---
layout: post
toc: true
title: Ouroboros 的实现 ---- 提供神奇的滚动效果
date: 2016-03-10 17:40:28.000000000 +08:00
permalink: /:title
tags: iOS
---


[Ouroboros](https://github.com/nju520/Ouroboros) 是一个根据 `scrollView` 滚动的距离完成动画的一个仓库. 灵感来源于 `javascript` 的第三方框架 [scrollMagic](https://github.com/janpaepke/ScrollMagic).

![](https://raw.githubusercontent.com/nju520/Ouroboros/master/demo.gif)

我在使用 `scrollMagic` 的过程中, 觉得这种根据当前滚动距离改变视图状态的方式非常的优雅, 而且这种动画是可以**回退**的, 在我看来, 这种动画的方式完全适合于在 iOS App 中完成引导界面的动画.

在以往的开发经验中, 经常需要根据 `scrollView` 的滚动距离完成一些相应的动画, 而 `Ouroboros` 就是 iOS 中用于解决这一类问题的框架.

## 动画?

`Ouroboros` 与其说是为视图添加动画, 不如说是改变视图当前的状态. 当动画根据 `scrollView` 的滚动距离而进行时, 所谓的 `duration` 就失去了意义. 我们不会知道动画**什么时候开始, 什么时候结束**, "动画" 的状态完全取决于位置. 而这也是这些动画可以**后退**的最重要原因.

> 为视图添加的其实并不是通常意义的动画, 而是根据当前的 `scrollView` 的滚动位置, 计算出当前视图的状态, 然后再更新视图的这样一组动作.


## 实现

`Ouroboros` 的组成还是非常的简单, 总共分为以下几部分

+ `UIScrollView` 的分类, 提供当前位置
+ `Ouroboros`, 聚合一组动画属性相同的 `Scale`
+ `Scale`, 用于计算当前状态
+ `UIView` 的分类, 为添加动画提供便利的方法, 并负责更新视图的状态

### UIScrollView+Ouroboros

`UIScrollView+Ouroboros` 这个分类的主要作用就是为整个 `Ouroboros` 提供数据支持, 也就是导致视图状态改变的原数据, `contentOffset`.

根据 `UIScrollView` 的滚动方向不同, 而 `UIScrollView` 的属性 `ou_scrollDirection` 决定了是根据 `contentOffset.x` 还是 `contentOffset.y` 来改变视图的状态.

我在 `UIScrollView` 中通过 method swizillzing 动态地改变了原有的 `-setContentOffset:` 方法的实现.

~~~objectivec
- (void)ou_setContentOffset:(CGPoint)contentOffset {
    [self ou_setContentOffset:contentOffset];
    [[NSNotificationCenter defaultCenter] postNotificationName:OURScrollViewUpdateContentOffset
                                                        object:nil
                                                      userInfo:@{@"contentOffset": [NSValue valueWithCGPoint:contentOffset],
                                                                 @"direction":@(self.ou_scrollDirection)}];
}
~~~

当 `UIScrollView` 滚动时, 它的 `contentOffset` 会不断发生改变, 而我们就可以通过方法调剂改变原有方法的实现, 在 `contentOffset` 改变时发出通知, 来通知 `Ouroboros` 中的其他模块根据 `contentOffset` 和  `ou_scrollDirection` 来对视图的状态进行更新.

### UIView+Ouroboros

`UIView+Ouroboros` 这个分类与大多数框架中的分类的作用一样, 为 `UIView` 提供"开箱即用"的方法, 其核心方法为 `-our_animateWithProperty:configureBlock:`, :

~~~objectivec
- (void)our_animateWithProperty:(OURAnimationProperty)property
                 configureBlock:(ScaleAnimationBlock)configureBlock {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateState:) name:OURScrollViewUpdateContentOffset object:nil];
    Ouroboros *ouroboros = [self ouroborosWithProperty:property];
    Scale *scale = [[Scale alloc] init];
    configureBlock(scale);
    NSMutableArray<Scale *> *scales = [ouroboros mutableArrayValueForKey:@"scales"];
    [scales addObject:scale];
}
~~~

当这个方法被调用时:

1. 首先会注册 `OURScrollViewUpdateContentOffset` 通知, 当 `contentOffset` 改变时调用 `-updateState:` 方法.
2. 然后会根据方法传入的 `property`, 获取一个对应的 `Ouroboros` 的对象, 这个对象的作用就是为了管理一组 `Scale`.
3. 而在获取 `ouroboros` 之后, 会实例化一个 `scale`
4. 使用传入的 `block` 配置这个 `scale`
5. 存入 `ouroboros` 持有的 `scales` 数组中

在这里有这样几个问题, **每一个视图对应的一组 `property` 相同的动画, 都由相同的 `ouroboros` 对象来处理**, 这样做的主要原因是防止在同一区间中改变视图的同一属性多次的问题.

~~~objectivec
[yellowView our_animateWithProperty:OURAnimationPropertyViewHeight configureBlock:^(Scale * _Nonnull scale) {
    scale.toValue = @(200);
    scale.trigger = 0;
    scale.offset = 320 * 2;
}];
[yellowView our_animateWithProperty:OURAnimationPropertyViewHeight configureBlock:^(Scale * _Nonnull scale) {
    scale.toValue = @(400);
    scale.trigger = 320;
    scale.offset = 320 * 0.5;
}];
~~~

在这里当我们第一次调用 `-our_animateWithProperty:configureBlock:` 方法时, 在 `[0, 640]` 之间改变了视图的高度, 而在我们第二次为视图高度添加动画时, 在 `[320, 480]` 之间改变了视图的高度, 而这时就造成了冲突. 而这就是 `ouroboros` 要解决的一个问题.

当 `UIScrollView` 滚动并且发出通知告知视图需要更新状态时, 就会调用在该分类中另一个比较重要的方法 `-updateState:`

1. 这个方法首先会从 `notification` 对象中取出 `contentOffset` 和 `ou_scrollDirection` 的值
2. 然后遍历视图自己持有的 `ouroboroses` 数组
3. 通过其中的每一个 `ouroboros` 获取当前位置下的值, 根据 `ouroboros.property` 更新视图的状态.

~~~objectivec
- (void)updateState:(NSNotification *)notification {
    CGPoint contentOffset = [[notification userInfo][@"contentOffset"] CGPointValue];
    OURScrollDirection direction = [[notification userInfo][@"direction"] integerValue];
    for (Ouroboros *ouroboros in self.ouroboroses) {
        CGFloat currentPosition = 0;
        if (direction == OURScrollDirectionHorizontal) {
            currentPosition = contentOffset.x;
        } else {
            currentPosition = contentOffset.y;
        }

        id value = [ouroboros getCurrentValueWithPosition:currentPosition];
        OURAnimationProperty property = ouroboros.property;

        switch (property) {
            case OURAnimationPropertyViewBackgroundColor: {
                self.backgroundColor = value;
            }
                break;
            ...
        }
    }
}
~~~

其中的 `-getCurrentValueWithPosition:` 方法会在下面介绍.

### Ouroboros

`Ouroboros` 作为这个框架的核心类, 它为视图的更新提供数据支持, 并且负责管理器持有的 `Scale` 对象, 发现其中的可能的动画冲突,
在这个类中也提供了几个创建 `CGRect` `CGSize` 和 `CGPoint` 的方法.

~~~objectivec
NSValue *NSValueFromCGRectParameters(CGFloat x, CGFloat y, CGFloat width, CGFloat height);
NSValue *NSValueFromCGPointParameters(CGFloat x, CGFloat y);
NSValue *NSValueFromCGSizeParameters(CGFloat width, CGFloat height);
~~~

当 `UIView` 调用 `-updateState:` 方法更新视图时, 调用了 `-getCurrentValueWithPosition:` 方法, 该方法根据当前的状态获取了视图该 `property` 对应的值.

~~~objectivec
- (id)getCurrentValueWithPosition:(CGFloat)position {
    Scale *previousScale = nil;
    Scale *afterScale = nil;
    for (Scale *scale in self.scales) {
        if ([scale isCurrentPositionOnScale:position]) {
            CGFloat percent = (position - scale.trigger) / scale.offset;
            return [scale calculateInternalValueWithPercent:percent];
        } else if (scale.trigger > position && (!afterScale || afterScale.trigger > scale.trigger)) {
            afterScale = scale;
        } else if (scale.stop < position && (!previousScale || previousScale.stop < scale.stop)) {
            previousScale = scale;
        }
    }
    if (previousScale) {
        return previousScale.toValue;
    } else if (afterScale) {
        return afterScale.fromValue;
    }
    NSAssert(NO, @"FATAL ERROR, Unknown current value for property %@", @(self.property));
    return [[NSObject alloc] init];
}
~~~

`Ouroboros` 对象会遍历持有的 `scales` 数组, 这时可能会发生三种情况:

1. 如果当前位置, 在某一个 `scale` 的区间中, 就会直接通过 `-calculateInternalValueWithPercent:` 方法, 返回当前位置的数值.
2. 否则, 当前位置不在某一个 `scale` 上, 但是存在 `previousScale` 就会返回 `previousScale.toValue`, 也就是 `previousScale` 结束时的值.
3. 如果不存在 `previousScale`, 但是存在 `afterScale` 那么就会返回 `afterScale.fromValue`, 也就是 `afterScale` 的初始值.

> 而当该方法调用时, 一定会存在至少一个 `scale`, 所以 `- getCurrentValueWithPosition:` 方法总会返回正确的值.

比如说, 存在以下两个 `scales`

~~~
[100, 200] [400, 500]
~~~

1. 如果当前位置在 `[100, 200]` 或者 `[400, 500]` 之间, 那么直接通过这两个 `scale` 计算就能获得当前位置的值.
2. 如果在 `[-Inf, 100]` 之间, 就会返回 `100` 处的值.
3. 如果在 `[200, 400]` 之间, 就会返回 `200` 处的值
4. 如果在 `[500, +Inf]` 之间, 就会返回 `500` 处的值

`Ouroboros` 这个类的另一个作用就是发现 `scale` 之间的覆盖, 而这个是通过 `Objective-C` 语言中的 `KVO` 完成的, 实现这个功能主要调用了三个方法:

+ `-mutableArrayValueForKey:`
+ `-insertObject:in<Key>AtIndex:`
+ `-removeObjectFrom<Key>AtIndex:`

`Objective-C` 中对数组的 `KVO` 主要由这三个方法实现, 首先需要通过 `-mutableArrayValueForKey:` 方法获取需要 observe 的可变数组

~~~objectivec
NSMutableArray<Scale *> *scales = [ouroboros mutableArrayValueForKey:@"scales"];
~~~

然后在操作这个数组, 例如 `-addObject:` 等方法时, 就会调用 `-insertObject:in<Key>AtIndex:`, `-removeObjectFrom<Key>AtIndex:` 方法, 而我们在只要在 `ouroboros` 覆写这两个方法就可以了.

~~~objectivec
- (void)insertObject:(Scale *)currentScale inScalesAtIndex:(NSUInteger)index {
    Scale *previousScale = nil;
    Scale *afterScale = nil;
    for (Scale *scale in self.scales) {
        if ([scale isSeparateWithScale:currentScale]) {
            if (scale.trigger >= currentScale.stop && (!afterScale || afterScale.trigger >= scale.stop)) {
                afterScale = scale;
            } else if (scale.stop <= currentScale.trigger && (!previousScale || previousScale.stop <= scale.trigger)) {
                previousScale = scale;
            }
        } else {
            NSAssert(NO, @"Can not added an overlapping scales to the same ouroboros.");
        }
    }

    if (previousScale) {
        currentScale.fromValue = previousScale.toValue;
    } else {
        currentScale.fromValue = self.startValue;
    }
    if (afterScale) {
        afterScale.fromValue = currentScale.toValue;
    }
    [self.scales insertObject:currentScale atIndex:index];
}

- (void)removeObjectFromScalesAtIndex:(NSUInteger)index {
    [self.scales removeObjectAtIndex:index];
}
~~~

在这里 `-removeObjectFromScalesAtIndex:` 方法的实现并不重要, 我们需要关注的是 `-insertObject:inScalesAtIndex:` 方法. 这个方法在最开始会先将即将插入的 `scale` 与其它所有的 `scale` 进行比较, 查看是否有 overlapping, 并找出最近的 `previousScale` 和 `afterScale`. 重新设置 `currentScale` 和 `afterScale` 的初始值. 我相信由于上面也有类似的代码, 这里的逻辑也很好解释.

### Scale

`Scale` 作为 `Ouroboros` 的一部分, 它的核心作用就是保存一个 `Ouroboros` 动画的状态

+ toValue
+ trigger
+ offset
+ function

然后根据这些状态和 `percent` 计算视图的状态, 也就是 `-calculateInternalValueWithPercent:` 方法.

这个方法的实现非常长, 我们在这里只截取其中的一部分

~~~objectivec
- (id)calculateInternalValueWithPercent:(CGFloat)percent {
    percent = [self justifyPercent:percent];

    CGFloat value = self.functionBlock(self.offset * percent * 1000, 0, 1, self.offset * 1000);

    id result = [[NSValue alloc] init];
    if ([self.fromValue isKindOfClass:[NSNumber class]]) {
        CGFloat fromValue = [self.fromValue floatValue];
        CGFloat toValue = [self.toValue floatValue];

        CGFloat resultValue = fromValue + (toValue - fromValue) * value;
        result = @(resultValue);
    }
    ...

    return result;
}
~~~

当 `percent` 传进来之后, 要调用 `-justifyPercent:` 方法保证当前 `percent` 值的范围在 `[0, 1]` 之间, 然后通过 `functionBlock` 根据不同的函数曲线偏移当前的 `offset` 值, 默认的函数曲线为线性的, 也就是不会改变 `percent` 值. 在这之后, 由于 `fromValue` 和 `toValue` 的值有不同的类型, 要根据值类型的不同, 计算出不同的 `resultValue`. 公式差不多都是这样的:

> fromValue + (toValue - fromValue) * value

如果是 `UIColor` 就会分别计算 `red` `green` `blue` `alpha` 四部分, 然后重新组成 `UIColor`, 如果是 `CGRect` 等其他值也会分别计算各个组成部分, 最后再重新组合成对应的值的类型.


## 总结

到这里, 整个 `Ouroboros` 框架的实现就已经基本介绍完了, 整个框架的实现还是比较简单的. 如果你有更好的想法或者有新的建议, 可以在 github 上开一个 issue 或者 PR.

<iframe src="https://ghbtns.com/github-btn.html?user=nju520&repo=Ouroboros&type=star&size=large" frameborder="0" scrolling="0" width="160px" height="30px"></iframe>

<iframe src="http://ghbtns.com/github-btn.html?user=nju520&type=follow&size=large" height="30" width="240" frameborder="0" scrolling="0" style="width:240px; height: 30px;" allowTransparency="true"></iframe>

Blog: [nju520.me](http://nju520.me)
