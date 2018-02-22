---
layout: post
toc: true
title: iOS 为 UIKit 属性增加钩子方法
date: 2015-04-15 13:34:03.000000000 +08:00
permalink: /:title
tags: iOS
---

最近在做一个用于实现夜间模式的开源框架, 需监听 UIKit 中的属性, 而这个监听的通知者就是 UIKit **实例**本身, 当我最开始想要做的时候, 我感觉这个东西实在太简单了, 不过之后...

##KVO

我想到的第一个解决方案是使用 `KVO` 来解决. `KVO` 是一个很好的方式来为已有的属性添加观察者.

###继承 or 分类?

但是因为要实现的夜间模式要在工程中引入, 而不是使一个已经完成大半的项目重新继承所有的 `UIKit` 类, 所以使用分类的方式而不是继承的方式引入夜间模式, 而且大部分开源的框架都是以分类的形式来引入以减少使用者的工作量.

由于在分类中无法调用 `init` 系列方法来为**实例**增加观察者, 而且让用户自己在 `viewContrller` 中**手动添加观察者**对于一个轻量级的框架是难以忍受的, 所以我放弃了 `KVO` 这个解决方案(因为使用 `KVO` 就要使用继承).

##Runtime

而第二个解决方案就是使用 `objc/runtime` 中**方法调剂**来实现的, 我们在运行时**动态**替换原有的属性的 setter 的实现, 换成我们自己实现的添加钩子的 setter 方法.

为什么要这么做呢, 因为我们并不清楚系统底层是怎么实现 setter 方法的, 所以重写一个 setter 方法可能会有意想不到的事情发生.

在最开始直接覆写 setter 方法的时候, 因为在**分类中无法访问属性**例如:

~~~objectivec
self.backgroundColor
~~~

而使用别的办法没有达到想要的效果(动态为分类添加属性覆写 setter 和 getter), 每次为属性`backgroundColor` 都不会使颜色正确的渲染, 所以我就放弃了, 最终选择 runtime 中的方法调剂实现这一功能.

我直接展示一下方法调剂的代码:

~~~objectivec
static dispatch_once_t onceToken;              
dispatch_once(&onceToken, ^{                                               
    Class class = [self class];                                           
    SEL originalSelector = @selector(#origin#);
    SEL swizzledSelector = @selector(#swizzle#);

    Method originalMethod = class_getInstanceMethod(class, originalSelector);  
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);  
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));                   
    if (didAddMethod){
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));           
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
});
~~~

这段代码来自于 [NSHipster](http://nshipster.com/method-swizzling/), 实现还是很清楚的, 我们只需要在 `#origin#` 和 `#swizzle#` 处填上需要交换的**选择子**就可以了.

找对了方法, 接下来的工作就很简单了, 我们需要在哪里加入方法调剂的代码呢, 我的建议是在 `load` 方法中, 因为这个方法只会在程序的运行中执行一次, 不会导致线程之类的问题.

~~~objectivec
+ (void)load {
	// Here is your method swizzling code.
}

- (void)hook_setTextColor:(UIColor *)textColor {
	NSLog(@"Before");
	[self hook_setTextColor:textColor];
    NSLog(@"After");
}
~~~

有人看到这里可能会有疑问: **方法调用自己是否会导致无限递归?**. 其实并不会, 因为我们在运行时交换了方法的实现.

在方法的实现交换之后:

> `hook_` 方法的实现是原方法, 而原方法的实现会被替换为 `hook_`, 所以当再次访问 `setTextColor:` 方法时, 会先 `NSLog(@"Before")` 然后运行原方法的实现(未被替换前的实现), 最后 `NSLog(@"After")`.

这里可能有点难以理解, 建议各位写一个 Demo 试一下就知道调用的时序了.

##总结

这次的 post 主要是在**分类**中为已有的**属性或者方法**添加钩子, 关键问题还是方法调剂的时间, 难度其实并不是很高. 不过实现感觉还是很有意思的啊 :)
