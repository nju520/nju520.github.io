---
layout: post
toc: true
title: 链式语法与 Objective-C
date: 2015-05-27 15:44:22.000000000 +08:00
permalink: /:title
tags: iOS
---


作为一个 Objective-C 语言的使用者已经有近两年的时间了. 在逐渐熟悉手中的工具, Objective-C 语言的同时, 我也开始从更高的角度来观察这一门语言.

虽然至今我也不敢说我精通 Objective-C 和 Cocoa Touch, 但是我对它们也有了一些自己的见解.

## Objective-C

Objective-C 语言的语法使得我感觉到这门语言是如此的**优雅**. 在别人看来啰嗦的 label, 其实更是为了增加语言的可读性, 使 Objective-C 更像一门自然语言而做出的努力.

大多数的方法都不需要去查看文档, 只凭借方法的签名就能获得这个方法的作用, 这点使我们 iOS 开发者在编码的过程中更容易的达到**代码即注释**.

~~~objectivec
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
~~~

然而凡事都是有双面性, Objective-C 中一些重要框架的使用, 往往让人诟病.

## Core Data

作为一名 iOS 开发者就会不可避免的接触到 Core Data 这个框架, 但是它的使用却一直被开发者吐槽, 主要是它的使用实在太过于复杂, 麻烦.

但是你有时却不得不使用它.

当然, 我在我所开发的应用中并没有过多的使用 Core Data, 而是使用了 levelDB 来代替, 这种 Key-Value 存储的数据库更适合于大部分的应用.

## AutoLayout

在 AutoLayout 刚刚出现的时候, 许多的开发者都觉得 AutoLayout 必将快速将原来 iOS 开发中使用 frame 布局转变到使用 constraint 布局.

但是知道真正使用的时候才发现原来 AutoLayout 的使用方法是如此的繁琐.

~~~objectivec
[superview addConstraints:@[

    //view1 constraints
    [NSLayoutConstraint constraintWithItem:view1
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:superview
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:padding.top],

    [NSLayoutConstraint constraintWithItem:view1
                                 attribute:NSLayoutAttributeLeft
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:superview
                                 attribute:NSLayoutAttributeLeft
                                multiplier:1.0
                                  constant:padding.left],

    [NSLayoutConstraint constraintWithItem:view1
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:superview
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                  constant:-padding.bottom],

    [NSLayoutConstraint constraintWithItem:view1
                                 attribute:NSLayoutAttributeRight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:superview
                                 attribute:NSLayoutAttributeRight
                                multiplier:1
                                  constant:-padding.right],

 ]];
~~~

使用这种方式来构建布局简直就是一种折磨, 这也是为什么在 AutoLayout 刚刚出现的时候, 并没有什么人去使用它. 反而, 真正使 AutoLayout 被开发者广泛使用的是另一个 DSL, 也就是大名鼎鼎的 [Masonry](https://github.com/SnapKit/Masonry).

它使用一种非常非常简洁的方式来实现自动布局.

~~~objectivec
[view1 mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(superview.mas_top).with.offset(padding.top); //with is an optional semantic filler
    make.left.equalTo(superview.mas_left).with.offset(padding.left);
    make.bottom.equalTo(superview.mas_bottom).with.offset(-padding.bottom);
    make.right.equalTo(superview.mas_right).with.offset(-padding.right);
}];
~~~

其中最关键的一点就是使用了**链式语法**.

~~~objectivec
make.top.equalTo(superview.mas_top).with.offset(padding.top);
~~~

## Animation

在 Masonry 之后, 也就是前一段时间, 又有开发者为动画实现了同样简洁优雅的链式语法, 也就是 [JHChainableAnimations](https://github.com/jhurray/JHChainableAnimations).

在 JHChainableAnimations 作者的同意下, 我也同样将它移植到了 Swift 上 [DKChainableAnimationKit](https://github.com/nju520/DKChainableAnimationKit).

这是使用 Objective-C 原有的方法实现的动画, 虽然它非常的易读, 并且符合 Objective-C 一贯的风格.

~~~objectivec
[UIView animateWithDuration:1.0
                      delay:0.0
     usingSpringWithDamping:0.8
      initialSpringVelocity:1.0
                    options:0 animations:^{
                       CGPoint newPosition = self.myView.frame.origin;
                       newPosition.x += 50;
                       self.myView.frame.origin = newPosition;
} completion:^(BOOL finished) {
   [UIView animateWithDuration:0.5
                         delay:0.0
                       options:UIViewAnimationOptionCurveEaseIn
                    animations:^{
       self.myView.backgroundColor = [UIColor purpleColor];
   } completion:nil];
}];
~~~

但是这段代码与下面的**链式语法**比起来就显得冗长与罗嗦了.

~~~objectivec
self.myView.moveX(50).spring.thenAfter(1.0).makeBackground([UIColor purpleColor]).easeIn.animate(0.5);
~~~

虽然有人说, 这是**对属性的误用**, 不过在我看来**与它带来的便捷, 优雅与易读相比, 属性的误用又算什么呢**?

链式的语法能够极大的改变原有 Objective-C Swift 的使用, 而在这两者的启发下, 我也开始了各种各样的尝试.

## UIKit

首先, 我在 UIKit 中进行了尝试, 希望能对原有的语法进行改造. 使用链式语法取代原有的语法. 这也就有了 [ChainableKit](https://github.com/nju520/ChainableKit) 使用链式语法配置 UIKit 组件的第三方库.

~~~objectivec
UIColor *red = [UIColor redColor];
UILabel.make
    .backgroundColor(red)
    .textAlignment(NSTextAlignmentCenter)
~~~

但是, 当这一框架刚刚诞生并且我尝试写出之后, 我却感到有些怪异, 这好像并不符合我们的直觉, 因为这些属性并没有顺序上的关系. 但是却不失为一种尝试.

不过, 它也确实能够极大的减少代码的行数, **将配置 UILabel 的全部代码聚合在一起**.

## AttributedString

由于 [colorize](https://github.com/fazibear/colorize) 的启发, 我又在 AttributedString 中尝试使用链式语法来解决创建配置**属性字符串**的问题. [Typeset](https://github.com/nju520/Typeset)

~~~objectivec
@"Hello".typeset.match(@"He").red.string;
~~~

## 总结

这就是我对链式语法在 Objective-C 中使用的总结和体会. 虽然并没有得出什么重要的结论, 不过我还是相信**简洁与优雅的方法最终总会被开发者采纳**.
