---
layout: post
toc: true
title: DKNightVersion 的实现 --- 如何为 iOS 应用添加夜间模式
date: 2015-05-09 15:13:35.000000000 +08:00
permalink: /:title
tags: iOS
---


**最新: [成熟的夜间模式解决方案](http://nju520.me/night)**

**注意: 这篇文章已经过时了, 最新版本的 2.3.0 实现已经更改了.**


在很多重阅读或者需要在夜间观看的软件其实都会把夜间模式当做一个 App 所需要具备的特性. 而如何在不改变原有的架构, 甚至不改变原有的代码的基础上, 就能为应用优雅地添加夜间模式就成为一个在很多应用开发的过程中不得不面对的一个问题.

就是以上事情的驱动, 使我思考如何才能使用一种优雅并且简洁的方法解决这一问题.

而 [DKNightVersion](https://github.com/nju520/DKNightVersion) 就是我带来的解决方案.

到目前为止, 这个框架的大部分的工作都已经完成了, 或许它现在不够完善, 不过我会持续地维护这个框架, 帮助饱受实现夜间模式之苦的工程师们解决这个~~坑的一逼的~~需求.

## 实现

现在我也终于有时间来~~水一水~~写一篇博客来说一下这个框架是如何实现夜间模式的, 它都有哪些特性.

在很长的一段时间我都在想如何才能在不覆写 `UIKit` 控件的基础上, 为 iOS App 添加夜间模式. 而 `objc/runtime` 为我带来了不覆写 `UIKit` 就能实现这一目的的希望.

### 为 UIKit 控件添加 `nightColor` 属性

因为我们并不会子类化 UIKit 控件, 然后使用 `@property` 为它的子类添加属性. 而是使用 Objective-C 中神奇的分类(Category) 和 `objc/runtime`, 为 UI 系列的控件添加属性.

使用 `objc/runtime` 为分类添加属性相信很多人都知道而且经常在开发中使用了. 如果不了解的话, 可以看[这里](http://nshipster.com/associated-objects/).

DKNightVersion 为大多数常用的 `color` 比如说: `backgroundColor` `tintColor` 都添加了以 `night` 开头的夜间模式下的颜色, `nightBackgroundColor` `nightTintColor`.

~~~objectivec
- (UIColor *)nightBackgroundColor {
    return objc_getAssociatedObject(self, &nightBackgroundColorKey) ? :self.backgroundColor);
}

- (void)setNightBackgroundColor:(UIColor *)nightBackgroundColor {
    objc_setAssociatedObject(self, &nightBackgroundColorKey, nightBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
~~~

我们创建这个属性以保存夜间模式下的颜色, 这样当应用的主题切换到夜间模式时, 将 `nightColor` 属性存储的颜色赋值给对应的 `color`, 但是这会有一个问题. 当应用重新切换回正常模式时, 我们失去了原有正常模式的 `color`.

### 添加 `normalColor` 存储颜色

为了解决这一问题, 我们为 UIKit 控件添加了另一个属性 `normalColor` 来保存正常模式下的颜色.

~~~objectivec
- (UIColor *)normalBackgroundColor {
    return objc_getAssociatedObject(self, &normalBackgroundColorKey);
}

- (void)setNormalBackgroundColor:(UIColor *)normalBackgroundColor {
    objc_setAssociatedObject(self, &normalBackgroundColorKey, normalBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
~~~

但是保存这个颜色的时机是非常重要的, 在最开始的时候, 我的选择是直接覆写 `setter` 方法, 在保存颜色之前存储 `normalColor`.

~~~objectivec
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    self.normalBackgroundColor = backgroundColor;
    _backgroundColor = backgroundColor;
}
~~~

然而这种看似可以运行的 `setter` 其实会导致视图不会被着色, 设置 `color` 包括正常的颜色都不会有任何的反应, 反而视图的背景颜色一片漆黑.

由于上面这种方法行不通, 我想换一种方法使用观察者模式来存储 `normalColor`, 将实例自己注册为 `color` 属性的观察者, 当 `color` 属性变化时, 通知 UIKit 控件本身, 然后, 把属性存到 `normalColor` 属性中.

然而在什么时候将自己注册为观察者这一问题, 又使我放弃了这一解决方案. 最终选择[方法调剂](http://nshipster.com/method-swizzling/)来解决原有 `color` 的存储问题.

使用方法调剂为原有属性的 `setter` 方法添加钩子, 在方法调用之前, 将属性存储起来, 用于切换回 `normal` 模式时, 为属性赋值.

这是要与 `setter` 调剂的钩子方法:

~~~objectivec
- (void)hook_setBackgroundColor:(UIColor*)backgroundColor {
    if ([DKNightVersionManager currentThemeVersion] == DKThemeVersionNormal) {
        [self setNormalBackgroundColor:backgroundColor];
    }
    [self hook_setBackgroundColor:backgroundColor];
}
~~~

如果当前是 `normal` 模式, 就会存储 `color`, 如果不是就会直接赋值, 如果你看不懂为什么这里好像会造成无限递归, 请看[这里](http://nshipster.com/method-swizzling/), 详细的解释了方法调剂是如何使用的.

### DKNightVersionManager 实现 `color` 切换

我们已经为 UIKit 控件添加了 `normalColor` 和 `nightColor`, 接下来我们需要实现 `color` 在这两者之间的切换, 而这 `DKNightVersionManager` 就是为了处理模式切换的类.

通过为 `DKNightVersionManager` 创建一个单例来处理 `模式转换`, `使用默认颜色`, `动画时间` 等操作.

当调用 `DKNightVersionManager` 的类方法 `nightFalling` 或者 `dawnComing` 时, 我们首先会获取全局的 `UIWindow`, 然后通过递归调用 `changeColor` 方法, 使能够响应 `changeColor` 方法的视图改变颜色.

~~~objectivec
- (void)changeColor:(id <DKNightVersionChangeColorProtocol>)object {
    if ([object respondsToSelector:@selector(changeColor)]) {
        [object changeColor];
    }
    if ([object respondsToSelector:@selector(subviews)]) {
        if (![object subviews]) {
            // Basic case, do nothing.
            return;
        } else {
            for (id subview in [object subviews]) {
                // recursice darken all the subviews of current view.
                [self changeColor:subview];
                if ([subview respondsToSelector:@selector(changeColor)]) {
                    [subview changeColor];
                }
            }
        }
    }
}
~~~

因为我在这个类中并没有引入 `category`, 编译器不知道 `id` 类型具有这两个方法. 所以我声明了一个协议, 使 `changeColor` 中的方法来满足两个方法 `changeColor` 和 `subViews`. 不让编译器提示错误.

~~~objectivec
@protocol DKNightVersionChangeColorProtocol <NSObject>

- (void)changeColor;
- (NSArray *)subviews;

@end
~~~

然后让所有的 UIKit 控件遵循这个协议就可以了, 当然我们也可以不显式的遵循这个协议, 只要它能够响应这两个方法也是可以的.

### 实现默认颜色

我们要在 DKNightVersion 实现默认的夜间模式配色, 以便减少开发者的工作量.

但是因为我们对每种 `color` 只在父类中实现一次, 这样使得子类能够继承父类的实现, 但是同样**不想让 UIKit 系子类继承父类的默认颜色**.

~~~objectivec
- (UIColor *)defaultNightBackgroundColor {
    BOOL notUIKitSubclass = [self isKindOfClass:[UIView class]] && ![NSStringFromClass(self.class) hasPrefix:@"UI"];
    if ([self isMemberOfClass:[UIView class]] || notUIKitSubclass) {
        return UIColorFromRGB(0x343434);
    } else {
        UIColor *resultColor = self.normalBackgroundColor ?: [UIColor clearColor];
        return resultColor;
    }
}
~~~

通过使用 `isMemberOfClass:` 方法来判断**实例是不是当前类的实例, 而不是该类子类的实例.** 然后才会返回默认的颜色. 但是非 UIKit 中的子类是可以继承这个特性的, 所以使用这段代码来判断该实例是否是非 UIKit 的子类:

~~~objectivec
[self isKindOfClass:[UIView class]] && ![NSStringFromClass(self.class) hasPrefix:@"UI"]
~~~

我们通过 `NSStringFromClass(self.class) hasPrefix:@"UI"` 巧妙地达到这一目的.

#### 使用 `erb` 生成 Objective-C 代码

这个框架大多数的工作都是重复的, 但是我并不想为每一个类重复编写近乎相同的代码, 这样的代码十分不易阅读和维护, 所以使用了 `erb` 文件, 来为生成的 Objective-C 代码提供模板, 只将元数据进行解析然后传入每一个模板, 动态生成所有的代码, 再通过另一个脚本将所有的文件加入目录中.

----

[DKNightVersion](https://github.com/nju520/DKNightVersion) 的实现并不复杂. 它不仅使用了 `erb` 和 Ruby 脚本来减少了大量的工作量, 而且使用了 `objc/runtime` 的特性来魔改 UIKit 组件, 达到为 iOS 应用添加夜间模式的效果.

<iframe src="https://ghbtns.com/github-btn.html?user=nju520&repo=DKNightVersion&type=star&count=true&size=large" frameborder="0" scrolling="0" width="160px" height="30px"></iframe>
