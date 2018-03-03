---
layout: post
toc: true
title: Prolog 基础 <1>
date: 2015-04-05 19:45:30.000000000 +08:00
permalink: /:title
---




##为什么学习 Prolog?

[Prolog](http://zh.wikipedia.org/zh/Prolog) 是种逻辑式的编程语言. 我第一次见到这个名字的时候大约实在我学习 SICP 的过程中, 实现了一个简单的逻辑式语言的解释器. 之后我又在 CTMCP 一书中的 Relational Programming 和 Logical Programming 中多次见到 Prolog 的身影, 加上我本身对于各种编程语言非常地感兴趣, 所以我选择学习这门语言, 在这里记录一下我的学习的进度和经历, 也希望能为别人学习 Prolog 提供一下微不足道的帮助吧.

##书籍的选择

在选择学习一门新的编程语言之后, 第一件事情是上网查询一些资料因为 Prolog 的使用者极少, 所以资料也非常的难以查找, 我一开始想要使用的是 Prolog by Example, 但是因为很难找到所以就选择了 Learn Prolog Now.

##开发环境的搭建

怎样才能快速的搭建 Prolog 的开发环境呢, 如果你是用的 Mac. 在命令行中输入

~~~
brew cask install swi-prolog
~~~

如果没有装 brew 或者 cask, 可以在 google 上轻松找到这两个命令行工具的安装方法. 在这里我也就不在多说了.

我是用的编辑器是 Emacs, 使用的插件可以点[这里](http://bruda.ca/emacs/prolog_mode_for_emacs). 安装好之后, 我们就可以开始 Prolog 之旅了.

##Prolog 基础

Prolog 有三种非常基本结构:

* 事实(facts)
* 规则(rules)
* 查询(queries)

事实和规则被叫做 knowledge base 或者叫 database, Prolog 的编程其实就是写 knowledge base, 这些 knowledge base 就定义和保存了我们感兴趣的全部知识. 我们如何使用一个 Prolog 程序呢? 就是发起查询, 就是通过向 knowledge base 中存储的数据提出问题, 然后获取回答. 这与我们平时的使用 Objective-C Java 等命令式编程有着极大的不同.

###Facts

首先我们先写下几个 Prolog 中的 facts, 需要打开一个文件, 后缀是 `.pl`.

~~~
programmer(linux).
programmer(bill).
designer(jonathan).
~~~

这个文件 `facts.pl` 就是一些 facts 的集合, 注意, 在这里的每一个 fact 都是以 `.` 结尾的. 我们怎么使用呢, 在命令行中切换到 `facts.pl` 的目录下, 然后输入 `swipl`.

~~~
Welcome to SWI-Prolog (Multi-threaded, 64 bits, Version 6.6.6)
Copyright (c) 1990-2013 University of Amsterdam, VU Amsterdam
SWI-Prolog comes with ABSOLUTELY NO WARRANTY. This is free software,
and you are welcome to redistribute it under certain conditions.
Please visit http://www.swi-prolog.org for details.

For help, use ?- help(Topic). or ?- apropos(Word).

?-
~~~

然后会出现这些信息, 使用 `consult('fact.pl').` 加载你的 Prolog 代码. 输入: programmer(linux).

~~~
?- programmer(linux).
true
~~~

Prolog 会返回 `true`. 如果你输入: programmer(jonathan).

~~~
?- programmer(jonathan).
false
~~~

它就会返回 `false`. 很简单吧.

当然 facts 也可以是向下面这样有多个参数

~~~
loves(i,u).
loves(he,u).
~~~

如果你输入一个不存在过程, 它就会告诉你 `Undefined procedure`.

###Rules

接下来我们介绍一下什么是规则 rules, 规则我们理解起来非常的容易, 在 Prolog 中如何实现一些规则呢, 我们使用 `:-`.

~~~
sunny(today).
happy(tom).
football(tom) :- sunny(today),happy(tom).
~~~

接下来我们加载我们的代码, 询问 `football(tom)`. Prolog 会返回 `true`, 规则是什么呢, 规则的前半部分也就是 `football(tom)` 是规则的头部(head), 规则的后半部分 `sunny(today),happy(tom)` 是规则的目标(goals). 当规则的 goals 成立时, head 就会成立也就是:

**如果今天的天气很好, tom 也很开心, 那么他就会去踢足球.**

Prolog 使用 `,` 来表示 **和**, 使用 `;` 来表示 **或**. 所以在这里, 后面的两个条件都需要成立. 这样 Prolog 就能推出 `football(tom)`.

我们可以在 Rules 中添加变量增强我们的表达能力, 比如这样:

~~~
father(tom,john).
father(john,ive).
grandfather(X,Z):-father(X,Y),father(Y,Z).
~~~

我相信这对于我们是非常容易理解的, 在这里也不过多说明了.

###Queries

什么是 queries, 其实我们在上边输入的 `football(tom).`, `programmer(jonathan).` 都是一种查询. 只是查询是否成立, 接下来我们就需要在查询中引入变量(variable)了.

~~~
programmer(linux).
programmer(bill).
designer(jonathan).
~~~

还是这一段代码, 我们可以通过询问 Prolog:

~~~
?- programmer(X).
~~~

然后就会出现

~~~
X = linux
~~~

Prolog 每次只会出现最先符合条件的结果, 若果你想看其他的结果, 可以输入 `;` 也就是或, 来查看是否有其他的输入, 我们输入 `;` 之后, 会出现:


~~~
X = bill
~~~


再次输入之后, 就会返回 `false` 了, 因为没有符合条件的结果了.

##Prolog 语法

介绍了 Prolog 中的基本元素之后, 我们想要知道, Prolog 中的基本元素到底是由什么来构建的呢, 现在来看一下 Prolog 中的基本语法.

Prolog 中的基本元素都是 term(*不知道该怎么翻译*)构建而来的. 而在 Prolog 中有 4 种不同的 term

* atom
* number
* variable
* complex term

###Atom

符合下列条件之一的就是 Prolog 中的 atom:

1. 由大写字母, 小写字符, 数字和下划线组成的并且**以小写字母开头**的字符串, 例如: `john` `tom` `big_big` `a_bc`.
2. 任意的包装在单引号 `'` 中的字符床. 例如: `'dsada'` `*((&@!MBAS))` `Fjdh_da`.
3. 特殊的字符串, 比如 `:-` `;` `@=`.

###Numbers

数字在 Prolog 中并不是非常的重要, 不过 Prolog 支持大多数的数字的表示和特殊的值.

###Variables

变量是由由大写字母, 小写字符, 数字和下划线组成的并且**以大写字母或者下划线开头**的字符串, 比如 `X` `Variable` `_dsal`. 

变量 `_` 在 Prolog 中非常的特殊被称为匿名变量.

###Complex Terms

Complex terms 实际上就是一种结构, 而我们之前见到的

~~~
programmer(linux).
programmer(bill).
designer(jonathan).
~~~

这些都是 complex terms, 而且我们也可以定义出更加复杂的结构

~~~
father(father(fahter(john))).
~~~

complex term 拥有的参数的数量叫做 arity, arity 在 complex term 中及其的重要, `progammer(linux)` 中的 `arity = 1`, `love(i,u)` 中的 `arity = 2`.

在 Prolog 中可以定义两个名字相同, 而 arity 不同的 predicate.

当我们讨论到 predicate 时, 我们经常使用 `/` 后面跟着 `arity` 的数量来表示 predicate.

例如:

~~~
happy/1
love/2
~~~

##总结

到目前为止, 我们已经对 Prolog 有着一个大体的了解, 也能感觉到它与其他编程语言的与众不同, 而这种不同就是驱使我学习它的最大因素.
