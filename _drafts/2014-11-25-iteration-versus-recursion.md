---
layout: post
title: Iteration versus Recursion
date: 2014-11-25 05:25:57.000000000 +08:00
permalink: /:title
---


`Iteration` 和 `Recursion` 在我们所有的编程语言中都是非常重要的概念, 尤其是在声明式的编程模型中.

##Iteraive computation

迭代的计算模型是一个`stack`大小为`constant`并且大小保持不变的循环.

非常重要的地方就是, 迭代的计算模型拥有一个初始的状态`S 0`, 在经过多次的转换最后会得到`S final`:

	S0 -> S1 -> ... -> Sfinal

这种思想的通用的表示可以被总结为如下的形式:

~~~
(define (iter state)
	(if (good-enough? state)
		state
		(iter (next state))))
~~~

在这个模式中, 函数`good-enough?`和`next`依赖于相应的问题. 我们使用`Newton's method`求平方根来验证这个迭代的计算模型.

~~~
(define (sqrt x)
	(define (iter guess x)
		(if (good-enough? guess x)
			guess
			(iter (improve guess x) x)))
	(define (improve guess x)
		(/ (+ guess (/ x guess)) 2))
	(define (good-enough? guess x)
		(< (abs (- x (* guess guess))) 0.00001))
	(define (abs x) (if (< x 0) (-x) x))
	(iter 1.0 x))
~~~
		
这就是我们使用迭代式的计算模型使用`Newton's method`求平方根的方法.

###Control abstraction

上面所提到的帮助我们设计高效的程序, 但是它并不是一种计算模型, 我们接下来提供一种通用的表示作为其他程序组成的一部分, 通过将其中的两部分提取出来, 然后作为函数的参数, 把这种通用的模式转化成一种控制的抽象.

~~~
(define (iter state good-enough? next)
	(if (good-enough? state)
		state
		(iter (next state))))
~~~
			
当我们使用这种控制抽象的时候, 需要为他提供`good-enough?`和`next`这两个函数, 每个函数带有一个参数. 将函数像参数一样传递给其他函数的技术叫做`higher-order programming`.

~~~
(define (sqrt x)
	(iter 1.0 
		  (lambda (guess) (< (/ (abs (- x (* guess guess))) x) 0.00001))
		  (lambda (guess) (/ (+ guess (/ x guess)) 2))))
~~~

使用两个匿名函数作为参数传给`iter`. 这是一种非常强大的组织程序的方式, 因为它把通用的控制流和特殊用法分离. 如果一种抽象经常使用, 我们可以将它更近一步, 将它转化为语言抽象.

