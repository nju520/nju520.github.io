---
layout: post
toc: true
title: Prolog 递归 <3>
date: 2015-04-09 02:22:14.000000000 +08:00
permalink: /:title
---




在这一次的 post 中, 我们将要介绍 Prolog 中的递归定义, 也就是说, 一个 predicate 如果它定义了一个或多个引用自己的规则, 那么这个 predicate 就是递归的.

递归的定义非常地简单:

~~~
is_digesting(X,Y):-just_ate(X,Y).
is_digesting(X,Y):-
    just_ate(X,Z),
    is_digesting(Z,Y).
just_ate(mosquito,blood(john)).
just_ate(frog,mosquito).
just_ate(stork,frog).
~~~

`is_digesting` 就是一个递归地 predicate, 在这个 knowledge base 上, 我们就可以询问 Prolog.

~~~
?- just_ate(stork,blood(john)).
true
~~~

虽然我们并没有直接定义这个事实, 不过 Prolog 根绝递归定义地 `is_digesting` 推出了这个结果.

递归是一种非常强大的定义方式, 但是, 我们也能遇到一切错误, 如果, 你是用下面的这种定义方式, 就会出现无限递归.

~~~
is_digesting(X,Y):-is_digesting(X,Y).
~~~

这个无限递归是非常明显的.

~~~
is_digesting(X,Y):-
    is_digesting(Z,Y),
    just_ate(X,Z).
~~~

上面的定义初看是正确的, 不过 Prolog 会不断地调用 `is_digesting` 导致无限递归, 所以这也是错误的.

我们需要正确是使用递归, 使用递归定义式, 要在定义最后添加自己的引用而不是在定义的前面.
