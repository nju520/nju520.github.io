---
layout: post
toc: true
title: StackOverflow 黑魔法系列 <2>
date: 2015-08-03 11:08:19.000000000 +08:00
permalink: /:title
tags: iOS
---

距离上一次的 StackOverflow 黑魔法系列的 post 已经很久了, 自己也很久没有写技术博客了, 虽然这次带来的又是一篇水文. 但是好久没有写了, 写写水文也好试试手.

## AutoReleasePool

iOS 中的 run loop 等待一些事件的发生并且响应这些实践. 这个事件可能包括用户触摸屏幕等等.

处理每一个 iOS 中的事件时, 一个新的 autorelease pool 都会在开始时被创建, 然后在事件响应结束后被 `drain`. 从理论上来说, 自动释放池的嵌套可以使无数的, 但是你需要知道的最主要的自动释放池是 **Event Loop**.

下面是应用程序生命周期的图:

![](/content/images/2015/08/nBjxr.jpg)

可以用下面的代码来表示

~~~objectivec
int UIApplicationMain(...) {
    while (!shouldQuitApplication) {
        Event *someEvent = // wait for next event;
        NSAutoreleasePool *myPool = [[NSAutoreleasePool alloc] init];
        // handle event
        [myPool release];
    }
}
~~~

在 iOS 中有三种事件的类型.

~~~objectivec
UIEventTypeTouches,
UIEventTypeMotion,
UIEventTypeRemoteControl,
~~~

所以在每一次触摸, 运动和远程控制的事件结束之后, 自动释放池都会被排干.

链接: [End of run loop — autorelease pool recovery](http://stackoverflow.com/questions/5766839/end-of-run-loop-autorelease-pool-recovery
)

## GCD, NSThread 和 NSOperationQueue 之间有什么区别?

1. 当你需要**直接控制你所创建的线程**时, 使用 `NSThread`. e.g.
    * 当你需要对控制线程的优先级有细颗粒度的控制或者与其他直接消耗线程对象的子系统直接交互并且需要停留在同一页上时, 就需要使用 `NSThread` 但是这种情况是及其罕见的, 但是它们确实发生, 特别是在实时应用中.
2. 当你的任务是简单的并行时, 使用 `GCD`. e.g.
    * 你想要将一些工作简单的抛到后台去执行
    * 串行化的获取某些数据结构
    * 有一些可以使用 `dispatch_apply` 能够很好的串行化的 `for` 循环
    * 有一些数据源或者计时器, `GCD` 的 `API` 能够让你非常容易的使它们工作在后台
3. 当你在处理 Cocoa API 层级并且有一些更复杂的操作需要并行时, 使用 `NSOperation`. `NSOperation` 允许子类化, 复杂的依赖图, 撤销并且支持一些其他更高层级的语法糖. `NSOperation` 是对 `GCD` 的封装, 所以它有点类似有多核, 多线程的能力的 `GCD`. 如果你直接在 POSIX 层级进行工作时, 你应该更希望使用 `GCD`.

链接: [Which is the best of GCD, NSThread or NSOperationQueue?](http://stackoverflow.com/questions/12995344/which-is-the-best-of-gcd-nsthread-or-nsoperationqueue
)

## NSOperation 与 Grand Central Dispatch 对比

`GCD` 是一个底层级的以 C 语言为基础的 API, 可以用于以任务为基础的并行模型. `NSOperation` 和 `NSOperationQueue` 是 Objective-C 中用于完成相应工作的类. `NSOperation` 在 iOS 4 和 OS X 10.6 中被首次介绍, `NSOperationQueue` 和其它一些队列是使用 `GCD` 实现的.

从总体上来说, 你应该使用满足需要的最高层级的抽象. 这意味着你需要使用 `NSOperationQueue` 来代替 `GCD`, 除非你需要完成一些事情, 但是 `NSOperationQueue` 无法支持.

事实上, 有许多可以使用 `NSOperationQueue` 可以非常简单完成的工作, 但是使用 `GCD` 时需要很多的工作. 苹果公司借助 GCD 创建了拥有对象友好型的 API 的 `NSOperation`.

链接: [NSOperation vs Grand Central Dispatch](http://stackoverflow.com/questions/10373331/nsoperation-vs-grand-central-dispatch)

## UITableViewCell 子视图在被点击时消失

当 UITableViewCell 被点击时, 在 cell 的 `contentView` 上面的视图的颜色全部都会改变, 你可以通过子类化 `UIView` 来改变颜色或者使用 `UIImageView` 并使用 1x1 像素的拉伸图片来解决这个问题.

链接: [UITableViewCell subview disappears when cell is selected](http://stackoverflow.com/questions/6745919/uitableviewcell-subview-disappears-when-cell-is-selected)

## 判断 iPhone 上的晃动手势

判断 iPhone 上面晃动手势的最简单办法是, 你需要有一些 UIView 来作为第一响应者来接收晃动实践. 这里有一写使用 UIView 获取晃动事件的代码.

~~~objectivec
@implementation ShakingView

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if ( event.subtype == UIEventSubtypeMotionShake ){
        // Put in code here to handle shake
    }

    if ( [super respondsToSelector:@selector(motionEnded:withEvent:)] )
        [super motionEnded:motion withEvent:event];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

@end
~~~

你可以通过子类化任意一个 `UIView` 并覆写这些方法完成对晃动手势的监听.

在视图控制器中, 你需要设置这个视图变成第一响应者:


~~~objectivec
- (void) viewWillAppear:(BOOL)animated {
    [shakeView becomeFirstResponder];
    [super viewWillAppear:animated];
}
- (void) viewWillDisappear:(BOOL)animated {
    [shakeView resignFirstResponder];
    [super viewWillDisappear:animated];
}
~~~

如果有其他的视图变成了第一响应者, 那么在其他视图响应结束后, 恢复当前视图的第一响应者身份.

链接: [How do I detect when someone shakes an iPhone?](http://stackoverflow.com/questions/150446/how-do-i-detect-when-someone-shakes-an-iphone)
