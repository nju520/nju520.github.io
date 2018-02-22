---
layout: post
toc: true
title: NSUserDefaults 的默认值
date: 2016-03-10 17:39:45.000000000 +08:00
permalink: /:title
tags: iOS
---


`NSUserDefaults` 提供了一个与默认设置交互的接口. 这些默认设置允许一个 App 为每一个单独的用户的设置提供定制化的行为.

## 数据的同步

我们可以通过 `NSUserDefaults` 对象在运行时从数据库读取用户的数据, 并添加到缓存中. 在我们正常获取或者设置 `NSUserDefaults` 的值时, 数据库和缓存中的数据其实并没有同步更新, 因为这样会影响效率. `NSUserDefaults` 在需要同步时会**自动调用** `synchronize` 方法更新数据库数据.
我们也可以手动调用 `synchronize` 来同步数据.

## 不可变

从 `NSUserDefaults` 中返回的值都是不可变的, 也就是 `NSString` `NSArray` `NSDictionary`. 如果你想要改变这些值, 你需要调用 `mutableCopy`, 获取不可变的版本, 改变它的值之后再设置 `NSUserDefaults` 中对应的键.

## Bool

在 `NSUserDefaults` 中设置 `BOOL` 类型的值总会有一个非常麻烦的问题. 如果我们要在 `NSUserDefaults` 中存储一个 `BOOL` 类型的值, 当我们使用 `boolForKey:` 取出它的值时, 它的默认值总是 `NO`.

因为在你没有为一个 key 单独设置值时, 它的默认值总是 `nil`. 所以在我们使用 `NSUserDefaults` 设置一个 `BOOL` 值时, 总会把这个 `BOOL` 值的**语义设置为相反**的.

但是当我们需要把 `BOOL` 值的默认值设置为 `YES` 时, 其实也是有办法的.

### 设置 BOOL 值的默认值

假如我们要为我们的 App 添加一个 `isLatestVersion` 的 `BOOL` 值, 而它的默认值是 `YES`.

~~~objectivec
static NSString *isLatestVersion = @"isLatestVersion";
~~~

当我们使用 `boolForKey:` 获取 `isLatestVersion` 的值时:

~~~objectivec
[[NSUserDefaults standUserDefaults] boolForKey:isLatestVersion];
~~~

如果我们在之前没有设置它的值, 它的值总是 `NO`.

但是当我们用 `objectForKey:` 去获取它的值时:

~~~objectivec
[[NSUserDefaults standUserDefaults] objectForKey:isLatestVersion];
~~~

它返回的值是 `nil`. 哪怕在我们先通过 `boolForKey:` 获取 `isLatestVersion` 之后, 再调用  `objectForKey:` 返回的值依然是 `nil`. `boolForKey:` 也没有改变它的行为.

也就是说当我们没有设置一个 `BOOL` 类型的 `NSUserDefaults` 值时, 它的默认值都是 `nil`, 这样我们就可以通过下面的代码将一个 `BOOL` 类型的默认值设置为 `YES` 了.

~~~objectivec
if ([[NSUserDefaults standUserDefaults] objectForKey:isLatestVersion] == nil) {
    [[NSUserDefaults standUserDefaults] setBool:YES forKey:isLatestVersion];
}
~~~

<iframe src="http://ghbtns.com/github-btn.html?user=nju520&type=follow&size=large" height="30" width="240" frameborder="0" scrolling="0" style="width:240px; height: 30px;" allowTransparency="true"></iframe>

Blog: [nju520.me](http://nju520.me)
