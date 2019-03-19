---
layout: post
toc: true
permalink: /rails-database-best-prectice-part-1
title: Rails 数据库最佳实践
tags: rails database best prectice
desc: 在维护一些老旧的Rails项目的时候，我偶尔会碰到一些不好的ActiveRecord代码。我也花费过一些时间来加速一些相对较慢的、或者多次调用数据库的数据库操作。有了这些经历，启发了我写一些“回归到基础”的Rails数据库最佳实践。

---



## 规则1： 让数据库完成它应该完成的工作

当我们正确使用数据库的时候，数据库会表现出非常丰富的特性以及令人难以置信的速度。他们在数据过滤和排序方面是非常厉害的，当然其他方面也不错。假如数据库可以做的，我们就让数据库来完成，这方面肯定速度会比Ruby，或其他语言快。

你可能必须学习一点关于数据库方面的知识，但是老实说，为了发挥数据库的最佳好处你不必深入学习太多相关知识。

通常我们用的都是Postgres。选择哪种数据库和认识它、使用它，让它发挥它的长处相比来说，后者更重要。假如你对Postgres好奇，在这篇博客后面有挺多相关资源的链接。我们喜爱他们。

我们的首要原则就是：让数据库来做它擅长的事情，而不是Ruby。

## 规则2： 编写高效的和可以级联调用的Scope

Scope很好用。它们允许你根据具体的要求创建直观的helper来获取数据的子集，但是反模式的scope反而会显著的扼杀它带给我们的优势。我们先看看`.active` scope：

```
class Client < ActiveRecord::Base
  has_many :projects
end

class Project < ActiveRecord::Base
  belongs_to :client

  # Please don't do this...
  scope :active, -> {
    includes(:client)
      .where(active: true)
      .select { |project| project.client.active? }
      .sort_by { |project| project.name.downcase }
  }
end
```

有几点需要我们注意的是：

1. 这个scope返回的不是ActiveRecord Relation，所以它不可以链式调用，也不能用`.merge`方法。
2. 这个scope用Ruby来实现数据选择（过滤）
3. 用Ruby实现排序
4. 周期性的用Ruby实现排序

#### #1 返回ActiveRecord::Relation （例如不触发查询）

为什么返回Relation更好？ 因为Relation可以链式调用。可链式调用的scope更容易被复用。当scope返回的是Relation时，你可以把多个scope组合进一条查询语句，例如`Athlete.active.men.older_than(40)`。Relation也可以和`.merge()`一起使用，安利一下`.merge()`非常好用。

#### #2 用DB选择数据（而不是Ruby）

为什么用Ruby过滤数据是个坏主意？因为和DB相比，Ruby这方面确实很慢。对于小的数据集来说关系大，但是对大量数据集来说，差别就太大了。

## 首要原则： Ruby做的越少越好

为什么Ruby在这方面很慢，有三方面原因：

- 花费在把数据从数据库里传到应用服务器上的时间
- ActiveRecord必须解析查询结果，然后为每条记录创建AR模型对象
- 你的数据库有索引（对吧？！），它会让数据过滤非常快，Ruby不会。

#### #3 让数据库排序（而不是Ruby）

那么排序呢？在数据库里排序会更快，除非你处理很大的数据集，否则很难注意到这点。最大的问题是`.sort_by`会触发执行查询，而且我们丢失了Relation数据结构。光这个原因就足够说服我们了。

#### #4 不要把排序放进scope里面（或放到一个专用的scope里）

因为我们尽量创建一个可复用的scope，不可能每个scope的调用都有相同的排序要求。因此，我推荐把微不足道的排序一起单独拿出来。或者，把混合的或比较重要的排序移到它自己的scope，如下：

```
scope :ordered, => { order(:status).order('LOWER(name) DESC') }
```

更好的scope看起来如下：

```
class Client < ActiveRecord::Base
  has_many :projects

  scope :active, -> { where(active: true) }
end

class Project < ActiveRecord::Model
  belongs_to :client

  scope :active, -> {
    where(active: true)
      .joins(:client)
      .merge(Client.active)
  }

  scope :ordered, -> {
    order('LOWER(name)')
  }
end
```

在重构过的scope版本里看看`.merge()` [api](http://api.rubyonrails.org/classes/ActiveRecord/SpawnMethods.html#method-i-merge)的用法。`.merge()`让从别的已经join进查询的model中使用scope变得更加容易，减少了潜在的可能存在的重复。

这个版本在效率上等价，但是消除了原来的scope的一些缺点。我觉得也更容易阅读。

### 规则3： 减少数据库调用

ActiveRecord为操作数据库提供了容易使用的API。问题主要是在开发期间我们的通常使用本地数据库，数据也很少。一旦你把代码push到生产环境，等待时间瞬间增加了10+倍。数据量显著上升。请求变得非常非常慢。

## 最佳实践：假如经常被访问的页面需要多次访问DB，那么就需要多花点时间来减少查询数据库的次数。

在很多情况下，区别就在于用`.includes()` 还是`.joins()`。有时你还必须使用`.group()`, `.having()`和一些其他函数。在很稀少的情况下，你可能需要直接写SQL语言。

对于非不重要的查询, 一旦你实现了SQL，然后在弄清楚怎么把它转化为ActiveRecord。这样的话，你每次只需弄明白一件事，先是纯SQL，然后是ActiveRecord。DB是Postgres？使用[pgcli](http://pgcli.com/)而不是psql。

这方面有很多详细的介绍。下面是一些链接：

- [Includes vs Joins in Rails](http://tomdallimore.com/blog/includes-vs-joins-in-rails-when-and-where)
- [Preload vs Eager Load vs Joins vs Includes](http://blog.bigbinary.com/2013/07/01/preload-vs-eager-load-vs-joins-vs-includes.html)
- [Bullet – A gem that warns of N+1 select (and other) issues](https://github.com/flyerhzm/bullet)

那么用缓存会怎么样呢？当然，缓存是另外一个加速这些加载速度慢的页面，但是最好先消除低效的查询。当没有缓存时可以提高表现，通常也会减少DB的压力，这对scale会很有帮助。

### #4：使用索引

DB仅在查询有索引的列的时候会很快，否则就会做全表查询（坏消息）。

## 首要原则：在每个id列和其他在where语句里出现的列上都添加索引。

为表添加索引很容易。在Rails的迁移里：

```ruby
class SomeMigration < ActiveRecord::Migration
  def change
    # Specify that an index is desired when initially defining the table.
    create_table :memberships do |t|
      t.timestamps             null: false
      t.string :status,        null: false, default: 'active', index: true
      t.references :account,   null: false, index: true, foreign_key: true
      t.references :club,      null: false, index: true, foreign_key: true
      # ...
    end

    # Add an index to an existing table.
    add_index :payments, :billing_period

    # An index on multiple columns.
    # This is useful when we always use multiple items in the where clause.
    add_index :accounts, [:provider, :uid]
  end
end
```

现实略微有点差别，而且总是。过度索引和在insert/update时会增加一些开销是可能的，但是作为首要原则，有胜于无。

想要理解当你触发查询或更新时DB正做什么吗？你可以在ActiveRecord Relation末尾添加`.explain`，它会返回DB的查询计划。见[running explain](http://guides.rubyonrails.org/active_record_querying.html#running-explain)

### #规则5：对复杂的查询使用Query对象

我发现scope当他们很简单而且做的不多的时候最好用。我把它们当中可复用的构建块。假如我需要做一些复杂的事情，我会使用Query类来包装复杂的查询。示例如下：

```ruby
# A query that returns all of the adults who have signed up as volunteers this year,
# but have not yet become a pta member.
class VolunteersNotMembersQuery
  def initialize(year:)
    @year = year
  end

  def relation
    volunteer_ids  = GroupMembership.select(:person_id).school_year(@year)
    pta_member_ids = PtaMembership.select(:person_id).school_year(@year)

    Person
      .active
      .adults
      .where(id: volunteer_ids)
      .where.not(id: pta_member_ids)
      .order(:last_name)
  end
end
```

粗看起来好像查询了多次数据库，然而并没有。
9-10行只是定义Relation。在15-16行里的两个子查询用到它们。这是生成的SQL（一个单独的查询）：

```
SELECT people.*
FROM people
WHERE people.status = 0
  AND people.kind != "student"
  AND (people.id IN (SELECT group_memberships.person_id FROM group_memberships WHERE group_memberships.school_year_id = 1))
  AND (people.id NOT IN (SELECT pta_memberships.person_id FROM pta_memberships WHERE pta_memberships.school_year_id = 1))
ORDER BY people.last_name ASC
```

注意，这个查询返回的是一个ActiveRecord::Relation，它可以被复用。

不过有时候要返回一个Relation实在太难，或者因为我只是在做原型设计，不值得那么努力。在这些情况下，我会写一个返回数据的查询类（例如触发查询，然后以模型、hash、或者其他的形式返回数据）。我使用命名惯例：加入返回的是已经查询的数据，用`.data`，否则用`.relation`。如上。

查询模式的主要好处是代码组织；这个也是把一些潜在的复杂的代码从Model/Controller里提取到自己的文件的一个比较容易的方式。单独的查询也容易测试。它们也遵循单负责原则。

### #规则6： 避免Scope和查询对象外的ad-hoc查询（及时查询）

我不记得我第一次从哪里听到的，但是首要原则是和我站在一条线：

> 限制Scope和查询对象对ActiveRecord的构建查询方法（如`.where`, `.group`, `joins`, `.not`, 等）的访问。

即，把数据读写写进scope和查询对象，而不是在service、controller、task里构建ad-hoc查询。

为什么？嵌入控制器（或视图、任务、等）里的ad-hoc查询更难测试，不能复用。对于推理代码遵从什么原则更容易，让它更容易理解和维护。

### #规则7：使用正确的类型

每个数据库提供的数据类型都比你以为的要多。这些不常用的Postgres类型我认为适合绝大多数应用：

- 想要保留状态（preserve case），但是希望所有的比较都大小写不敏感吗？`citext`[doc](https://www.postgresql.org/docs/9.6/static/citext.html)正是你需要的。在migration里和String用法差不多。
- 想要保存一个集合（例如地址，标签，关键词）但是用一个独立的表觉得太重了？使用`array`类型。 [(PG docs)](https://www.postgresql.org/docs/9.6/static/arrays.html)/[(Rails doc)](http://guides.rubyonrails.org/active_record_postgresql.html#array)
- 模型化date, int, float Range？使用range类型[(PG doc)](https://www.postgresql.org/docs/9.6/static/rangetypes.html)/[(Rails doc)](http://guides.rubyonrails.org/active_record_postgresql.html#range-types)
- 需要全局独立的ID（主键或其他）使用`UUID`类型[(PG doc)](https://www.postgresql.org/docs/9.6/static/datatype-uuid.html)/[(Rails doc)](http://guides.rubyonrails.org/active_record_postgresql.html#uuid)
- 需要保存JSON数据，或者在考虑NoSQL DB？使用JSON类型之一[(PG doc)](https://www.postgresql.org/docs/9.6/static/datatype-json.html)/[(Rails doc)](http://guides.rubyonrails.org/active_record_postgresql.html#json)

这些只是特殊的数据类型中的一小部分。感兴趣可以看[理解数据类型的能量--PG的秘密武器](http://postgres-data-types.pvh.ca/)了解更多。

### #规则8：考虑你的数据库的全文检索

PG高级查询链接 [(1)](http://blog.carbonfive.com/2014/10/28/adventures-in-searching-with-postgres-part-1) [(2)](http://blog.carbonfive.com/2014/10/28/adventures-in-searching-with-postgres-part-2)

和[(PG文档)](https://www.postgresql.org/docs/9.6/static/textsearch.html)

### #规则9： 存储过程作为最后的选择（翻译略）

Wait what?! I’m saying use your database, but not to use stored procedures?!

Yup. There’s a time and place for them, but I think it’s better to avoid them while a product is rapidly evolving. They’re harder to work with and change, awkward to test, and almost definitely unnecessary early on. Keep it simple by leaving business logic out of your database, at least until something drives you to re-evaluate.

### 总结

我相信当使用数据库的潜力时产品会性能会表现更好，更容易。建议

减少查询的数量，使用索引，或任何别的建议都不是初级优化IMHO。 它是正确的使用你的数据库。当然，有一个收益递减的点： 例如写一个七七八八的原始SQL查询，从3个一般的查询减少到1个。利用你最好的判断力。
