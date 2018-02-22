---
layout: post
title: 基本数据结构
date: 2015-04-03 23:20:07.000000000 +08:00
permalink: /:title
---


在这一次的 post 中, 我们将要介绍一些简单的数据结构: 栈, 队列, 链表和树.
#栈和队列

栈和队列都是动态集合, 在这两种数据结构上进行 `DELETE` 操作所移除的元素都是预先设定的. 它们是两种最常用的数据结构.

##栈

在栈中, 被删除的元素是**最近插入**的元素. 它实现的是一种**后进先出**(last-in, first-out, LIFO)的策略. 

栈上的 `INSERT` 操作叫做 `PUSH`, 而无参数的 `DELETE` 操作叫做 `POP`. 我们可以使用 Ruby 中的数组来实现一个栈不需要考虑栈中所容纳的最多元素.

当栈中不包含任何元素时, 即栈是**空**的. 如果对一个空栈执行 `POP` 操作, 那么称为 `underflow`. 如果栈中的元素数量超出了所容纳的上限, 那么成为 `overflow`. 在这里我们不考虑栈的 `overflow` 问题.

~~~
class Stack
	def initialize
		@elements = []
	end
	
	def empty
		@elements.size == 0
	end

	def push(x)
		@elements[@elements.size] = x
	end

	def pop
		raise "Cannot pop empty stack!" if @elements.size < 0
		result = @elements[@elements.size - 1]
		@elements[@elements.size - 1] = nil
		result
	end

end
~~~

这三种操作的执行时间都为 $O(1)$.

##队列

在队列中, 被删去的元素都是在集合中存在时间最长, 最先加入队列的元素. 队列实现的是一种**先进先出**(first-in, first-out, FIFO)策略.

队列中的 `INSERT` 操作成为 `ENQUEUE`, 无参数的 `DELETE` 操作被称为 `DEQUEUE`. 队列有 `head` 和 `tail`. 当一个元素入队时会放到队尾的位置, 就像排在队伍末尾买票的人, 而出队的元素总是队伍最前面等待最久的人.

~~~
class Queue

	def initialize
		@elements = []
	end

	def enqueue(x)
		@elements[@elements.size] = x
	end

	def dequeue
		raise "Queue is empty!" if @elements.size == 0
		result = @elements.shift
		result
	end

end
~~~

在这段实现代码中, 我们并没有使用 `@head` 和 `@tail` 来保存队列的头部和尾部属性. 而是使用其他的操作来代替.

#链表

链表是一种这样的数据结构, 其中的各对象按线性顺序排序. 数组的线性顺序是由数组下标决定的, 然而与数组不同的是, 链表的顺序是由各个对象里的指针决定的. 链表为动态集合提供了一种简单而灵活的表示方法.

**双向链表**中的每一个元素都是一个对象, 每一个对象都有一个关键字 `key` 和两个指针: `next` 和 `prev`.

链表可以有多种形式. 它可以是单链接的或双链接的, 可以使已排序的或未排序的, 可以是排序的或未排序的. 

* 如果一个链表是**单链接的**, 则省略每个元素中的 `prev` 指针. 
* 如果链表是**已排序**的, 则链表的线性顺序与链表元素中关键字的线性顺序一直. 
* 如果链表是**未排序**的, 则表中的元素可以以任何顺序出现.
* 如果链表是**循环链表**, 表头元素的 `prev` 指针指向表尾元素, 而表尾元素的 `next` 指针指向表头元素.

~~~
class LinkList
	attr_accessor :head
	
	def initialize
		@head = nil
	end

	def search(key)
		x = @head
		while x != nil && x.value != key
			x = x.next
		end
		x
	end

	def insert(node)
		node.next = @head
		@head.prev = node if @head != nil
		@head = node
		node.prev = nil
	end

	def delete(node)
		if node.prev != nil
			node.prev.next = node.next
		else
			@head = node.next
		end
		node.next.prev = node.prev if node.next != nil
	end

end

class Node
	attr_accessor :prev, :value, :next

	def initialize(value)
		@prev = nil
		@value = value
		@next = nil
	end

end
~~~

要搜索一个有 `n` 个对象的链表, 过程 `search` 的最坏情况下的运行时间为 $\Theta(n)$, 因为可能搜索整个链表.

~~~
def search(key)
	x = @head
	while x != nil && x.value != key
		x = x.next
	end
	x
end
~~~

链表的插入的执行时间为 $O(1)$.

~~~
def insert(node)
	node.next = @head
	@head.prev = node if @head != nil
	@head = node
	node.prev = nil
end
~~~

我们先使用 `search` 寻找到目标之后, 再将目标元素 `delete`. 它的运行时间为 $O(1)$. 但是要先寻找到指定元素时, 因为要调用 `search` 所以运行时间为 $\Theta(n)$.

~~~
def delete(node)
	if node.prev != nil
		node.prev.next = node.next
	else
		@head = node.next
	end
	node.next.prev = node.prev if node.next != nil
end
~~~

#树

树的结点用对象表示, 我们首先将讨论二叉树.

##二叉树

首先我们来介绍一下二叉树的表示.

<img src="http://deltax.qiniudn.com/bonary-tree.png?attname=&e=1428144652&token=YJb_IPQrTSw1ox9LenQDH1HRcgHii9w_bp9ddmcz:ijsBu-QD13JsmP3BXx1jRAU2t5U" style="display:block;margin:auto"/> 

上图中表示了在二叉树中, 数据是如何存储和表示的.
