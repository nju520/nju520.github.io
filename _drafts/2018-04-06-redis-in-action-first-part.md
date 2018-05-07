---
layout: post
toc: true
permalink: /redis-in-action
title: Redis 实战 (一)
tags: redis database
desc: Redis 是一个远程内存数据库, 它可以提供五种不同类型的数据结构, 很多问题都可以很自然地映射到这些数据结构上. 用户还可以通过复制、持久化(persistance)和客户端分片(clien-side sharding)等特性, 方便地将 Redis 扩展成一个能够包含数百G数据, 每秒处理上百万次请求的系统.本章主要熟悉 Redis 的基本实用, 并通过一个虚拟的 Web 应用来使用 Redis 解决实际问题.
---



> 1. 本系列文章参考 《Redis 入门指南》  《Redis IN ACTION》
> 2. 本系列文章的代码采用 Ruby实现.


## 初识 Redis

`Redis`是一个速度非常快的非关系型数据库(no-relational database), 它可以存储键(key)与5种不同类型的值(value)之间的映射(map). 它可以将存储在内存的键值对数据持久化到硬盘, 也可以使用复制特性来扩展读功能, 还可以使用客户端分片来扩展写性能.


### Redis 附加特性

在使用类似 Redis 这样的内存数据库时, 我们首先想到的一个问题就是: “当服务器被关闭时, 服务器被存储的数据将何去何从?”

Redis 拥有两种不同形式的持久化方法, 它们都可以使用小而紧凑的格式将存储在内存中的数据存储到硬盘中.

1. 时间点转储(point-in-time dump),转储操作既可以在“指定时间段内有指定数量的写操作执行”被满足时执行, 还可以通过调用两条转储到硬盘(dump-to-disk)命令中的一条来执行.
2. 将所有修改了数据库的命令都写入一个只追加(append-only)文件里面, 用户可以根据数据的重要程度, 将只追加写入设置为不同形式:
  * 不同步(sync)
  * 每秒同步一次
  * 每写入一个命令就同步一次

还有一点值得考虑的就是有时候只使用一台 Redis 服务器可能无法处理所有请求. 为了扩展Redis 的读性能, 并为Redis提供故障转移(failure)支持, Redis 实现了主从复制特性: 执行复制的从服务器会连接上主服务器, 接收主服务器发送的整个数据库的初始副本(copy); 之后主服务器执行的写命令, 都会发送到从服务器去执行, 从而实时地更新服务器的数据集.

因为从服务器包含的数据会不断地进行更新, 因此客户端可以向任意一个从服务器发送读请求, 以此来避免对主服务器进行的集中式访问.



### Redis 数据结构

Redis 可以存储键(key)五种不同数据结构类型之间的映射:

* String

* List

* Set

* Hash

* Zset

  ​

#### String

Redis 的字符串和其他编程语言或者键值存储提供的字符串非常相似.

字符串拥有一些和其他键值存储相似的命令, 比如 GET、 SET、 DEL.

在下一个章节我们着重熟悉 Redis 的常用指令.



#### List

Redis 对链表(linked-list)结构的支持使得它在键值存储的世界中独树一帜. 一个列表结构可以有序地存储多个字符串.

Redis列表可执行的操作和很多编程语言中的列表操作非常相似:

* LPUSH: 将元素推入列表的左端(left end)
* RPUSH: 将元素推入列表的右端(right end)
* LPOP: 从列表左端弹出数据
* RPOP: 从列表右端弹出数据
* LINDEX: 获取列表中指定序号的元素
* LRANGE: 获取列表在给定范围上的所有元素

Redis 的列表并不仅仅支持一些通用的列表操作, 它还提供将元素插入列表中间的命令、将列表修剪至指定长度的命令.



#### Set

Redis的集合和列表都是可以存储多个字符串, 它们之间的区别就在于:

* 列表可以存储多个相同的字符串
* 集合通过散列表来保证自己存储的每个字符串都是各不相同(这些散列表只有键, 没有与键相关联的值)

因为Redis的集合使用无序(unordered)方式存储元素, 所以用户不能像使用列表那样, 将元素推入集合的一端 或者从集合的某一段弹出元素. 但是我们可以采用集合特有的命令来完成相应的操作:

*  `SADD`向集合中添加元素
* `SREM`命令从集合中移除元素
* `SISMEMBER`检查一个元素是否存在集合中
* `SMEMBERS`获取集合包含的所有数据

除了一些基本的操作之外, 集合还支持一些集合之间的操作:

* SINTER: 取两个集合的交集
* SUNION: 取两个集合并集
* SDIFF: 取两个集合差集 (SetA - SetB)

这些指定在特定的场景中非常实用.



#### Hash

Redis的散列是可以存储多个键值对之间的映射. 和字符串一样, 散列存储的值机可以是字符串又可以是数字值. 我们还可以对散列存储的数字执行自增和自减操作.

散列在很多方面就像是一个微缩版的Redis,不少字符串命令都有相应的散列版本.

* HSET: 添加一个键值对
* HGET: 获取一个键对应的值
* HGETALL: 获取所有的键值对
* HDEL: 删除一个键值对

熟悉文档数据库的同学来说 Redis 的散列可以看作文档数据库里面的文档;

熟悉关系数据库的同学可以将散列看作关系数据库里面的行.

因为散列、文档以及行都运行用户同时访问或者修改一个或多个域.



#### ZSET

有序集合是 Redis 最高级的一种数据结构.有序集合和散列一样, 都用于存储键值对:

* 有序集合的键: 被称为成员(member),每个成员是各不相同的
* 有序集合的值: 被称为分值(score),分值必须为浮点数.

有序集合是 Redis 中唯一一个既可以通过成员访问元素(这和散列类型), 又可以根据分值以及分值的排序顺序来访问元素的结构.

* ZADD: 向一个有序集合同添加元素

* ZRANGE: 获取有序集合中指定范围的元素, 多个元素会按照分值大小进行排序

* ZRANGEBYSCORE: 根据分值来获取指定范围的元素

* ZREM: 删除一个有序元素

  ​



### 文章投票

现在是时候来学习一下怎么使用这些结构来解决实际问题了.

最近几年, 越来越多的网站开始提供对网页链接、文章或者问题进行投票的功能.

![stackoverflow](点赞/踩)



这些网站会根据文章的发布时间和文章获得的投票数计算出一个评分, 按照这个评分来决定如何排序和展示文章.

这一小节就会实现一个简单的文章投票网站的后端.



#### 对文章进行投票

要构建一个文章投票网站,我们首先要做的就是为这个网站设置一些数值和限制条件.

> 如果一篇文章获得了至少200张投票(up vote),那么网站就认为这篇文章是一篇大家都感兴趣的文章.
>
> 假设这个网站每天发布1000篇文章, 而其中的50篇符合上述要求, 那么我们就将这50篇文章放到文章列表前100位至少一天.
>
> 另外, 我们的网站暂时不支持反对票(down vote)的功能

一般来说, 越晚发布的文章比越早发布的文章有更高的基础分数. 换言之, 我们需要一种策略来实现随着时间流逝基础分数越来越大, 程序需要根据文章的发布时间和当前时间来计算文章的评分.

具体策略如下:

> 将文章得到的支持票数 乘以一个常量, 然后加上文章的发布时间, 得出的结果就是文章的评分.
>
> 我们使用 UTC 时区 1970年1月1日 到现在为止经历过的秒数来计算文章的评分, 这个值通常被称为 Unix 时间.
>
> 另外, 我们的常量为432. 这个常量是通过将一天的秒数(86,400)除以文章展示一天所需的支持票数(200)得出的: 文章每获得一张支持票, 程序就将文章的得分增加 432 分.



构建文章投票网站除了需要计算文章评分之外, 还需要使用Redis散列来存储网站上的各种信息. 对于网站的每篇文章, 程序都使用一个散列值来存储文章的标题、指向文章的网站、发布文章的用户、文章的发布时间、文章得到的投票数量.

`article:202791` 详细信息:

~~~json
{
    "title": "Redis in action: first part",
    "link": "http://hwbnju.com/redis-in-action",
    "poster": "hwbnju",
    "time": "1523079350",
    "votes": "212"
}
~~~

> 使用冒号(:)作为分隔符: 上述散列的key 我们使用 `article:article_id` 的形式来构建命名空间.



我们的文章投票网站需要使用两个有序集合(zset)来有序地存储文章:

* publish_at: 成员为文章 ID , 分值为文章的发布时间. 记录根据发布时间排序的文章
* score: 成员为文章 ID, 分值为文章得到的评分. 记录根据评分排序的文章



为了防止用户对同一篇文章进行多次投票, 我们需要为每篇文章记录一个已投票用户名单.

为此, 程序将为每篇文章创建一个集合, 使用这个集合来存储所有已投票用户的ID:  voted:acrticle_id.

为了尽量节约内存, 我们规定当一篇文章发布期满一周之后, 用户将不能对其进行投票, 文章的评分也会固定下来, 而记录文章已投票用户名单的集合也会被删除.

在实现文章投票功能之前, 我们来浏览一下使用的数据结构:

* article:article_id: 散列, 用来记录文章的具体信息
* publish_at: 有序集合, 用来记录根据发布时间排序的文章
* score: 有序集合, 用来记录根据文章评分排序的文章
* voted:article_id: 集合, 记录文章对应的投票用户



##### 投票吧

当用户尝试对一篇文章进行投票时, 程序需要使用`ZSCORE`命令检查记录文章发布时间的有序集合, 判断文章的发布时间是否超过一周.

如果文章还处在可以投票的时间范围内, 那么程序就使用SADD`命令, 尝试将用户添加到记录文章已投票用户名单的集合中.

如果添加操作执行成功的话, 说明用户是第一次对这篇文章进行投票, 程序将使用`ZINCRBY`命令为文章的评分增加`432`(ZINCRBY命令用于有序集合成员的分数执行自增操作), 并使用`HINCRBY`命令对散列记录文章的投票数进行更新(HINCRBY命令用于对散列存储的值执行自增操作).

让我们来实现上述逻辑:

~~~ruby
ONE_WEEK_IN_SECONDS = 7 * 86400
VOTE_SCORES = 432

# article => article:20198
# redis => 为 Redis客户端的一个实例
def article_votes(user, article)
  cut_off = Time.now.to_i - ONE_WEEK_IN_SECONDS
  return if redis.zscore('zset:publish_at', article) < cut_off
  article_id = article.split(':')[1]

  # 如果用户之前未对此文章投票, 就将其加入到投票用户名单中
  if redis.sadd('voted:' + article_id, user)
    redis.zincrby('score', article, VOTE_SCORES) # 文章的评分增加 432
    redis.hincrby(article, 'votes', 1) # 文章的投票数加 1
  end
end
~~~

> 从技术上讲, 要正确的实现投票功能, 需要将 SADD、 ZINCRBY、 HINCRBY这三个指令放到一个事务中执行, 我们暂且这样写, 后续再改进.



我们实现的投票功能, 但是如何发布一篇文章呢?



#### 发布并获取文章

发布一篇新文章首先需要创建一个新的文章ID, 这项工作可以通过对一个计数器(counter)执行INCR命令来实现.

接着程序使用`SADD` 将文章发布者的ID添加到记录已投票用户名单的集合中(我们默认文章赞同数为1), 并使用`EXPIRE`命令为这个集合设置一个过期时间, 让 Redis 再文章发布期满一周之后自动删除这个集合.

之后程序会使用`HMSET`来存储文章的详细信息, 并执行`ZADD`命令, 将文章的初始评分(initial score)和发布时间分别添加到两个相应的有序集合中.

~~~ruby
def publish_article(user, title, link)
  article_id = redis.incr('article:').to_s

  voted = 'voted:' + article_id  # 文章已投票用户名单集合
  redis.sadd(voted, user)
  redis.expire(voted, ONE_WEEK_IN_SECONDS)

  article = 'article:' + article_id
  now = Time.now
  redis.hmset(article, {
    title: title,
    link: link,
    publisher: user,
    time: now,
    votes: 1
  }) # 存储文章的详细信息

  redis.zadd('score', article, now + VOTE_SCORES) # 评分有序集合
  redis.zadd('publish_at', article, now)          # 发布时间有序集合

  article_id
end
~~~



#### 取出文章

我们已经实现了发布文章以及为文章投票的功能, 接下来就是如何取出评分最高的文章以及最新发布的文章了.

程序首先使用`ZREVRANEG`命令取出多个文章ID, 然后再对每个文章ID执行一次`HEGTALL`命令取出文章的详细信息, 这个方法既可以取出评分最高的文章, 又可以取出最新发布的文章.

>  因为有序集合会根据成员的分值从小到大排列元素, 因此我们采用`ZREVRANGE`指令

~~~ruby
ARTICLE_PER_PAGE = 10
def get_articles(page, order = 'score')
  first = (page - 1) * ARTICLE_PER_PAGE
  last = first + ARTICLE_PER_PAGE - 1

  redis.zrevrange(order, first, last).map do |article|
    article_data = hgetall(article)
    article_data['id'] = article
    return article_data
  end
end

~~~





#### 对文章进行分组

虽然我们构建的网站可以展示最新发布的文章和评分最高的文章了, 但是它还不具备目前很多投票网站都支持的群组(group)功能: 这个功能可以让用户只看到与特定话题相关的文章, 比如“redis 拾遗”,  "Web 开发"文章.

群组功能由两部分构成:

* 记录文章所属群组
* 取出群组中的文章

为了记录各个群组都保存了哪些文章, 网站需要为每个群组创建一个集合, 并将所有同属于一个群组的文章ID都记录在这个集合中.

~~~ruby
def add_remove_groups(article_id, to_add = [], to_remove = [])
  # 构建存储文章信息的键名
  article = 'article:' + article_id

  # 将文章添加到它所属的群组中
  to_add.each do |group|
    redis.sadd('group:' + group, article)
  end

  # 从群组中移除文章
  to_remove.each do |group|
    redis.srem('group:' + group, article)
  end
end
~~~

上面的代码实现了使用集合来记录群组文章的功能. 初看上去, 可能会觉得使用集合来记录群组文章并没多大用处, 但是要知道 Redis 不仅可以对多个集合执行操作, 还可以在集合与有序集合之间执行操作.

为了能够根据评分对群组文章进行排序和分页(paging), 网站需要将同一个群组里面的所有文章按照评分有序地存储到一个有序集合中. Redis中`ZINTERSTORE`命令可以结束多个集合与有序集合作为输入, 找出所有同时存在于集合与有序集合的成员, 并以几种不同的方式来合并(combine)这些成员的分值(所有的集合成员的分值会被默认视为1).

对于我们的投票网站来说, 程序需要使用`ZINTERSTORE`命令选出相同成员中最大的那个分值来作为交集成员的分值, 这就取决于所使用的排序选项, 这些分值既可以是文章的评分, 也可以是文章的发布时间.

* 存储群组文章的集合与存储文章评分的有序集合执行 `ZINTERSTORE`命令, 可以得到按照文章评分排序的群组文章
* 存储群组文章的集合与存储文章发布时间的有序集合执行`ZINTERSTORE`, 可以得到按照文章发布时间排序的群组文章



如果文章非常多, 执行`ZINTERSTORE`命令就会比较长, 为了尽量减少Redis的工作量, 程序会将这个命令的计算结果缓存60秒.

~~~ruby
# 获取根据某种形式排序的分组文章列表
def get_group_articles(group, page, order = 'score')
  # 为每个群组的每种排序顺序都创建一个键 eg: score:programming
  key = order + group

  unless redis.exist?(key)
    redis.zinterstore(key, ['group:' + group, order], :aggregate => 'max')
    redis.expire(key, 60)
  end

  # 根据页码获取对应的文章列表
  get_articles(page, key)
end
~~~

上述代码实现从群组中获取一整页文章.

我们的实现中允许一篇文章同时属于多个群组(比如一篇文章可以同时属于“编程”和“算法”两个群组) .

所以对于一篇同时属于多个群组的文章来说, 更新文章的评分意味着程序需要对文章所属的全部群组执行自增操作, 这一操作在一篇文章属于多个群组的情况下非常耗时. 因此我们在`get_group_articles()`方法中对`ZINTERSTORE`进行了60秒的缓存, 以此来减少`ZINTERSTORE`命令的执行次数, 这样就不需要在更新文章评分的时候重新获取根据评分(发布时间)排序的文章列表了. 如果缓存已失效, 我们就会重新获取最新评分(发布时间)排序的文章列表

开发者需要在灵活性或限制条件下取舍将改变程序存储和更新数据的方式, 这一点对于任何数据库都适用.



#### 给文章加上标签

标签其实也是另外一种形式的分组. 考虑到一个文章的所有标签都是互不相同, 而且展示时对这些标签的排列顺序也没有特殊要求, 我们可以使用集类型来存储文章的标签.

对每篇文章我们使用键名 `article:article_id:tags`的键来存储该篇文章的标签.

~~~ruby
def add_tags(article_id, tags)
  key = 'article:' + article_id + ':tags'
  redis.sadd(key, tags)
end

def remove_tags(article_id, tags)
  key = 'article:' + article_id + ':tags'
  redis.srem(key, tags)
end
~~~



##### 通过标签搜索文章

有时我们需要列出某个标签下的所有文章, 甚至需要获得同时属于某几个标签的文章列表.

我们可以为每个标签使用一个名为`tag:tag_name:articles`的集合类型键存储标有该标签的文章ID列表.

每当我们为一篇文章添加一个标签时, 就将这个文章ID加入到标签文章集合中去:

~~~ruby
def add_tags(article_id, tags)
  key = 'article:' + article_id + ':tags'
  tags.each do |tag|
    redis.sadd(key, tag)
    tag_key = 'tag:' + tag + 'articles'
    redis.sadd(tag_key, article_id)
  end

end

def remove_tags(article_id, tags)
  key = 'article:' + article_id + ':tags'
  tags.each do |tag|
    redis.srem(key, tag)
    tag_key = 'tag:' + tag + 'articles'
    redis.srem(tag_key, article_id)
  end
end
~~~

现在我们可以很方便地获取一篇文章的标签集合:

~~~ruby
def get_article_tags(article_id)
  key = 'article:' + article_id + 'tags'
  redis.smembers(key)
end
~~~

也可以很方便地获取属于一个标签的所有文章:

~~~ruby
def get_articles_by_tag(tag)
  key = 'tag:' + tag + 'articles'
  redis.smembers(key)
end

~~~

还可以方便地获取同时拥有多个标签的文章列表

~~~ruby
def get_articles_by_tags(tags)
  keys = tags.map { |tag| 'tag:' + tag + 'articles' }
  sinter(keys)
end

~~~



### 小结

本章对Redis进行了初步的认识,我们需要知道: Redis是一个可以用来解决问题的工具. 它既拥有其他数据库不具备的数据结构, 又拥有内存存储、远程、持久化、可扩展等多个特性, 这使得用户可以以熟悉的方式为各种不同的问题构建解决方案.

在阅读`Redis 实战`系列文章时, 你也许会惊讶地发现, 自己思考数据问题的方式从原来的“怎样将我的想法塞进数据库的表和行中”, 变成了”使用哪种Redis数据结构来解决这个问题比较好呢“.

下一章我们将使用 Redis 构建Web应用.





## 使用 Redis 构建 Web 应用



从高层次的角度来看, Web应用就是通过HTTP协议对网页浏览器发送的请求进行响应的服务器或者服务(service). 一个Web服务器对请求进行响应的典型步骤如下:

~~~
1. 服务器对客户端发来的请求(request)进行解析
2. 请求被转发给一个预定义的处理器(handler)
3. 处理器可能会从数据库中读取或写入数据
4. 处理器根据取出的数据对模板(templete)进行渲染(render)
5. 处理器向客户端返还渲染之后的内容作为对请求的响应(response)
~~~



这种情况下Web请求被认为是无状态的(stateless), 也就是说, 服务器本身不会记录过往请求有关的任何信息, 这使得失效的服务器可以很容易地被替换掉. 本章节讲解如何使用更快的Redis查询来代替传统的关系型数据库查询, 以及如何使用Redis来完成一些使用关系型数据库无法高效完成的任务.



### 登录和 cookie 缓存





### 购物车

### 网页缓存



### 数据记录缓存



### 网页分析

## Redis 常用指令

## 数据安全



## 性能保证
