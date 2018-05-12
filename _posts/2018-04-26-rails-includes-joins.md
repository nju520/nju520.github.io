---
layout: post
toc: true
permalink: /rails-includes-and-joins
title: Rails includes and joins
tags: rails mysql  includes preload eager_load joins left_outer_joins
desc: 在Rails中有三种方式可以预加载数据, 另外还有两种方式直接加载关联表数据.有时候我们会得到一个非常小而精悍的SQL, 有时候却是一个非常大的SQL. 本篇文章主要阐述一下 Rails中惰性加载数据以及加载关联表数据.
---

在使用 Rails ActiveRecord期间,我们经常使用 `includes`来预加载数据, 使用 `joins`来生成联接表. 但是有时候我们会生成一个小而精悍的SQL, 有时候却得到一个巨大的SQL. 与此同时, Rails中存在 `preload`、 `eager_load`、`includes`等三种形式来预加载数据,  存在 `joins`、`left_outer_joins`来生成联接表. 深入研究它们的使用场景和差异会让我们使用 ActiveRecord 处理数据时更加得心应手.



## 联结表

> 文章的很多内容参考 Rails Guide 以及 Rails API, 毕竟官方的文档是我们学习的最大源泉.



ActiveRecord提供了`joins`以及 `left_outer_joins`(`left_joins`)用来指明生成的SQL语句中的`JOIN`子句.

* `joins`: 用于生成`INNER JOIN`查询或者定制查询.
* `left_outer_joins`: 用于 `LEFT OUTER JOIN`查询.



我们有多种方式使用`joins`:



### JOINS 使用方式



#### 直接使用 `joins`

我们使用频率最高的莫过于直接使用`joins`来生成一个联结表.

~~~ruby
class User < ApplicationRecord
  has_many :orders
end

class Order < ApplicationRecord
  belongs_to :user
end

[2] pry(main)> User.joins(:orders)
  User Load (93.3ms)  SELECT `users`.* FROM `users` INNER JOIN `orders` ON `orders`.`user_id` = `users`.`id` WHERE `users`.`deleted_at` IS NULL
~~~

上述查询的意思就是把所有包含了订单的用户作为一个`User`对象返回.

Warning:  **如果多个订单属于同一个用户, 那么这个用户会在`User`对象中出现多次.要想让每个用户只出现一次, 可以使用**:

~~~ruby
User.joins(:orders).distinct

User.joins(:orders).count # => 14899
User.joins(:orders).distinct.count # => 389
~~~

上面的示例是关联对象和被关联对象的关系为`一对多`. 如果它们的关系为`多对一`、`一对一`, 那情况如何呢?



~~~ruby
Order.joins(:user).count == Order.joins(:user).distinct.count
~~~

如果关联对象和被关联对象的关系为 `多对一`, 生成的订单对象只会出现一次.



#### 多个关联的联结

如果关联的对象不止一个的话, 我们可以使用多个关联的联结.

> 示例对象来自 Rails Guide

~~~ruby
class Category < ApplicationRecord
  has_many :articles
end

class Article < ApplicationRecord
  belongs_to :category
  has_many :comments
  has_many :tags
end

class Comment < ApplicationRecord
  belongs_to :article
  has_one :guest
end

class Guest < ApplicationRecord
  belongs_to :comment
end

class Tag < ApplicationRecord
  belongs_to :article
end
~~~



~~~ruby
Article.joins(:category, :comments)

# => SELECT articles.* FROM articles
  INNER JOIN categories ON articles.category_id = categories.id
  INNER JOIN comments ON comments.article_id = articles.id
~~~

上述查询的意思就是把属于某个分类的并至少拥有一个评论的文章作为一个`Article`对象返回.

与之前一样, 拥有多个评论的文章会在`Article`对象中出现多次.



#### 单层嵌套关联的联结

~~~ruby
Article.joins(comments: :guest)
# => Article.joins({comments: :guest})

# => SELECT articles.* from articles
INNER JOIN comments ON comments.article_id = articles.id
INNER JOIN guest    ON guest.comment_id = comments.id
~~~

上述查询的意思是把所有拥有访客评论的文章作为一个`Article`对象返回.



#### 多层嵌套关联的联结

~~~ruby
Category.joins(articles: [{comments: :guest}, :tags])

# => SELECT categories.* from categories
INNER JOIN articles ON articles.category_id = categories.id
INNER JOIN comments ON comments.article_id  = articles.id
INNER JOIN guests   ON guests.comment_id    = comments.id
INNER JOIN tags     ON tags.article_id		= artciles.id
~~~

上述查询的意思是把所有包含文章的分类作为一个`Category`对象返回, 其中这些文章都拥有访客评论并且带有标签.

上述的联结查询中`comments`和`tags`与`articles`是直接关联的, 因为它们属于同一个数组的元素.

`tags`是通过`comments`与`articles`关联, 因此 `comments`与`tags`是在一个`Hash`中.



### 为联结表指明条件

我们使用联结表的主要目的就是过滤出我们需要的对象集合, 有时候仅仅依靠管理表来过滤出所需的对象集合还是远远不够的. 此时我们就需要为联结表指明条件. 有两种方式可以实现联结表指明条件:

* 普通的SQL语句
* 散列条件

~~~ruby
# 1.普通的SQL字符串
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Client.joins(:orders).where('orders.created_at' => time_range)

# => SELECT clients.* from clients
INNER JOIN orders ON orders.client_id = cliens.id
WHERE orders.created_at BETWEEN '2018-04-30 16:00:00' AND '2018-05-01 16:00:00'

# 2. 散列条件
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Client.joins(:orders).where(orders: { created_at: time_range })
~~~



### 使用 merge

> Merges in the conditions from `other`, if `other` is an [ActiveRecord::Relation](http://api.rubyonrails.org/classes/ActiveRecord/Relation.html). Returns an array representing the intersection of the resulting records with `other`, if `other` is an array.

通过官方的文档我们可以看出 `merge`是可以连接其他的`ActiveRecord::Relation`的,这样可以简化我们的查询方法.

~~~ruby
Post.where(published: true).joins(:comments).merge( Comment.where(spam: false) )
# Performs a single join query with both where conditions.

recent_posts = Post.order('created_at DESC').first(5)
Post.where(published: true).merge(recent_posts)
# Returns the intersection of all published posts with the 5 most recently created posts.
# (This is just an example. You'd probably want to do this with a single query!)
~~~



### LEFT_OUTER_JOINS

Rails 5提供了`left_outer_joins`来实现左外联结.

如果你觉得`left_outer_joins`方法太长, 没关系,你可以使用`left_joins`.

左外联结一般用来选择一组记录, 不管他们是否具有关联记录.

~~~ruby
User.left_outer_joins(:orders).distinct.select('users.name AS name, orders.number AS number')

# => SELECT DISTINCT users.name AS name, orders.number AS number
LEFT OUTER JOIN orders ON orders.user_id = users.id
~~~



PS: 不论是`joins`还是`left_joins`,如果在后面添加`where`条件过滤, 返回的结果都是经过过滤之后的数据集合.



### 联结表返回的对象

以上我们讲述了 Rails 中 `joins`以及`left_outer_joins`的使用.

一般来说, 联结表的意义是用来过滤集合, 并不会加载关联的对象. 另外, 如果在联结表中加入了查询条件, 将会根据添加的查询条件对联结表进行过滤.

PS: **如果只使用 `joins`或者`left_outer_joins`, 并不会生成一张大的联结表, 只有在使用了预加载时, 才有可能生成大的联结表.**



## 惰性加载(eager load)

Rails 中使用ORM常见的一种问题就是当我们查询对象以及关联对象时遇到的`N+1`.

解决的方案也很简单, 就是使用`includes`:

~~~ruby
users = User.includes(:orders).limit(10)

users.each do |user|
  puts user.order.number
end

# SELECT * FROM users LIMIT 10
# SELECT orders.* FROM orders WHERE (orders.user_id IN (1,2,3,4,5,6,7,8,9,10))
~~~

上述代码只会生成两条SQL语句, 也就是两条`SELECT`查询语句.



### 加载形式

#### 及早加载多个关联对象

与`joins`类似, 我们可以及早加载多个关联对象

~~~ruby
Article.includes(:cateogry, :comments)
~~~

上述代码会加载所有文章、所有文章关联的分析以及每篇文章的分类



#### 嵌套关联的散列

~~~ruby
Category.includes(articles: [{comments: :guest}, :tags]).find(1)
~~~

上述代码会查询 ID 为1的分类, 并及早加载所有关联的文章、这些文章的标签以及评论, 还有这些评论关联的访客.



#### 为关联的及早加载指明条件

我们可以像`joins`那样为及早加载指明条件.

**加上条件之后, 就会生成一张大的联结表(LEFT OUTER JOIN)**



~~~ruby
Article.includes(:comments).where(comments: {visible: true})

#
SELECT "articles"."id" AS t0_r0, ... "comments"."updated_at" AS t1_r5 FROM "articles" LEFT OUTER JOIN "comments" ON "comments"."article_id" = "articles"."id" WHERE (comments.visible = 1)
~~~

上述代码会生成使用`LEFT OUTER JOIN`子句的SQL语句. 我们之前讨论的`joins`则会生成`INNER JOIN`子句的SQL语句.

PS: 上述的`where`条件为散列值, 如果换成SQL字符串的话, 就必须在代码末端加上`references`.

~~~ruby
Article.includes(:comments).where('comments.visible = ?', true).references(:comments)
~~~

通过`references`我们显式指明了`where`查询语句中使用的关联对象.



### eager_load and preload is What?

很多文章在介绍 `includes` 及早加载关联对象时都会涉及到`eager_load`以及`preload`. 本节我们就来看一下这两种预加载关联对象的方式.



#### preload

我们直接看官方的文档说明:

> Preload: Allowing preloading of args, in the same way that includes does
>
> User.preload(:posts)
>
> SELECT users.* FROM users
>
> SELECT posts.* FROM posts WHERE posts.user_id IN (1,2,3)



也就是说, `preload`在不加其他条件的情况下就等于`includes`.

查询结果是生成两条独立的`SELECT`语句.

如果我们在`preload`后面指明关联对象的查询条件, 就会报错. 因为 `perload`只负责加载对象和关联对象, 并没有联结关联对象.



#### eager_load

> Forces eager loading by performing a LEFT OUTER JOIN on args:
>
> User.eager_load(:posts)
>
> SELECT users.id AS to_ro, users.name AS to_r1,...,posts.id AS t1_r0
>
> FROM users LEFT OUTER  JOIN posts ON posts.user_id = users.id



`eager_load`只会产生一个`LEFT OUTER JOIN`查询语句, 并且会将关联对象加载到内存中(虽然从生成的语句中只是一个大的联结表查询, 实际上关联的对象的确被加载到了内存中).

`eager_load`就相当于使用了`references`的`includes`. 也就是指明的条件是关联对象中的字段时, Rails会生成`LEFT OUTER JOIN`语句.



#### includes

Rails 很聪明地帮我们选择到底是使用`preload`还是 `eager_load`.

我们要做的就是加载关联对象的时候使用`includes`即可.



> Why not simply call `eager_load` instead of the whole `query.includes(:user).references(:user)` piece? Why not simply call `preload` instead of `includes` (without its personal stalker), which is much more intent revealing?



### 总结



* `preload`、 `eager_load`、`includes`都是用于惰性加载.
* `preload`: 总是采用两条独立的查询语句来加载对象和关联对象. 它的后面不能指明关联对象的查询条件.
* eager_load: 通过`LEFT OUTER JOIN`来加载关联. 它后面可以指明关联对象的查询条件
* includes: Rails 4 之前的版本, `includes`是可以很聪明地判断到底使用哪种策略: eager loading or preloading. 但是在Rails 4之后的版本, `includes`只会使用`preload`预加载关联对象, 除非使用了`references`显式指明要使用`LEFT OUTER JOIN`去加载关联对象.



* `joins`和三种惰性加载方法不同. 使用 `inner joins`只会过滤数据并不会加载关联. 它和`includes`有三点不同:
  * 联结方式不同: `joins`使用的的联结方式为`INNER JOIN`. 而 `eager_load`采用的是`LEFT OUTER JOIN`.
  * 目的不同:  `joins`目的就是通过联结来过滤需要的记录集合, 它不会主动地加载关联对象, 因此无法避免 N+1次查询问题.
  * 当我们使用`joins`用来过滤对象而并不需要关联对象的字段时, `joins`完全符合我们的要求.





参考文章:

https://goiabada.blog/to-join-or-not-to-join-an-act-of-includes-f6728fcefea3
