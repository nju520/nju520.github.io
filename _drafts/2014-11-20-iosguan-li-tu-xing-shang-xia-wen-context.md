---
layout: post
title: iOS 管理图形上下文 context
date: 2014-11-20 01:01:57.000000000 +08:00
permalink: /:title
---
在 `iOS` 的视图中, 有三个非常相似的属性, `alpha`, `opaque` `hidden`. 这三个属性实际上没有什么太多的关系.

----
##hidden 属性
我们首先来解释一下 `hidden 属性, 如果将一个控件设置的 `view` 属性设置为 `YES` , 那么这个 `view` 根本不会被绘制, 它通常等于 `alpha` 值被设置为 `0`, 但是设置 `hidden` 属性并不会产生动画, 如果你需要动画完成过渡就需要修改 `alpha` 的值.

~~~
//without animation
(view.alpha = 0) == (view.hidden = YES)
//with animation
(view.alpha = 0) != (view.hideen = YES)
~~~
	
---
##alpha 属性

`alpha` 属性决定了视图会通过像素显示多少信息. `alpha` 值设为 `1` 意味着所有的视图信息都在像素上表现出来. 而 `alpha` 值设为 `0` 意味着没有视图信息能在像素上显示出来. 在iOS中, 屏幕上的任何真正透明的东西, 改变 `alpha` 值其实就是改变视图以及子视图的显示程度.

当 `alpha` 值被设置为 `0` 之后, 当前 `UIView` 和 `subviews` 会被隐藏, 而且当前 `UIView` 会从响应链删除.

---
##opaque 属性
是否将视图标记为 `opaque` 并不会升高或降低一个 `UIView` 的透明度. 它实际的坐拥实际上是为 `GPU` 节省工作量, 设置它的值并不影响视图是否绘制的最终结果.

---
我们可以通过设置以下的属性, 创建一个透明的视图接收事件.

~~~
view.alpha = 1;
view.opaque = NO;
view.backgroundColor = [UIColor clearColor];
~~~
