---
layout: post
toc: true
title: MagicMove 在 iOS 中的实现
date: 2015-06-07 21:33:57.000000000 +08:00
permalink: /:title
tags: iOS
---


最近由于去武汉参加 hackday, 十多天没有更新博客了. 今天就来说一说, 我在 hackday 上使用 swift 开发 App 遇到的哪些问题吧.

## 神奇移动

我曾经在很多的 App 中都实现了类似 Keynote 中的神奇移动的效果, 也就是指定当前帧和下一帧中的视图, 当 Keynote 从当前帧切换到下一帧时, 就会根据当前的这两帧中视图的位置添加动画, 达到神奇的效果.

而我在 iOS 开发中的实现其实有以下几个步骤.

* 使下一帧的视图控制器获取视图的引用, 以及视图的位置以便返回时使视图归位.
* push 或者 present 时, 在下一帧的视图控制器中重新绘制视图.
* 将视图移动到目标位置.
* 将视图移回原位置之后 pop 或者 dismiss

当我在 Swift 中实现的时候却遇到了几个问题.

## 值类型

在 Swift 中类型分为值类型和引用类型两种, 值类型在传递和赋值时将进行复制, 引用类型就只会保留一个指向对象的引用, 就像 C 语言中的指针.

因为在这一次动画的实现中, 我需要实现多个视图的神奇移动效果, 所以我把 `[UIView]` 数组传到下一个视图中, 而在 Swift 中, 数组是值类型的, 在传递的过程中会自动 copy. 也就是说, 下一个视图中的 `[UIView]` 和当前视图中的 `[UIView]` 并没有什么太多的关系.

但是在 Swift 中传递单独的 `UIView` 的时候, 由于 UIView 等 Objective-C 对象都是**引用类型**的, 所以在传递的过程中都是传递的引用, 也就是指针. 所以在下一个视图改变 UIView 之后, 原视图也会发生对应的变化. 但是由于, 我不想改变原有的视图, 所以需要对视图进行深拷贝, 就是是调用 `copy()` 方法

~~~swift
let copy = view.copy()
~~~

在调用 `copy()` 方法时需要实现 `copyWithZone` 方法以及 `NSCopying` 协议. 但是所有的 Objective-C 对象都是默认没有实现这个方法, 所以需要我们手动实现.

~~~swift
func copyWithZone(zone: NSZone) -> AnyObject {
    let copy = CRMainCollectionViewCell(frame: self.frame)
    copy.index = self.index
    copy.avatarImageView.image = avatarImageView.image
    copy.customizeImageView.image = customizeImageView.image
    copy.nameLabel.text = nameLabel.text
    copy.data = data
    return copy
}
~~~

这就是我所实现的 `copyWithZone` 方法, 你可以视情况实现你的 `copyWithZone` 方法.
