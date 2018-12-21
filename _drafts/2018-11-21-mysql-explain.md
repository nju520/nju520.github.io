---
Explain简称执行计划，可以模拟SQL语句，来分析查询语句或者表结构是否有性能瓶颈。

日常工作中，我们有时会通过日志记录下耗时较长的SQL语句，但是光找出这些SQL语句并不意味着完事了，常常需要借助EXPLAIN来查看SQL语句的执行计划，查看SQL语句是否用上了索引，是否进行了全表扫描，这都可以通过EXPLAIN命令得到。
---



## 数据表准备

### 数据库

```sql
> CREATE database explain_examples
```



### 数据表

```sql

```



```sql
/* 用户信息 */

DROP TABLE IF EXISTS `members`;

/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `members` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `no` VARCHAR(20) NOT NULL ,
  `name` VARCHAR(20) NOT NULL DEFAULT '',
  `age` INT(11) 		      DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_members_on_no` (`no`),
  KEY `index_members_on_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

TRUNCATE `members`;

INSERT INTO members
  (no, name, age)
VALUES
  ("NJU_EE_20140001", "aa", 20),
  ("NJU_EE_20140002", "bb", 22),
  ("NJU_EE_20140003", "cc", 21),
  ("NJU_EE_20140004", "dd", 25),
  ("NJU_EE_20140005", "ee", 21),
  ("NJU_EE_20140006", "ff", 22),
  ("NJU_EE_20140007", "gg", 20),
  ("NJU_EE_20140008", "hh", 23),
  ("NJU_EE_20140009", "ii", 23),
  ("NJU_EE_201400010", "jj", 20),
  ("NJU_EE_201400011", "kk", 22),
  ("NJU_EE_201400012", "ll", 22),
  ("NJU_EE_201400013", "mm", 25),
  ("NJU_CE_20140001", "aa", 20),
  ("NJU_CE_20140002", "bb", 22),
  ("NJU_CE_20140003", "cc", 21),
  ("NJU_CE_20140004", "dd", 25),
  ("NJU_CE_20140005", "ee", 21),
  ("NJU_CE_20140006", "ff", 22),
  ("NJU_CE_20140007", "gg", 20),
  ("NJU_CE_20140008", "hh", 23),
  ("NJU_CE_20140009", "ii", 23),
  ("NJU_CE_201400010", "jj", 20),
  ("NJU_CE_201400011", "kk", 22),
  ("NJU_CE_201400012", "ll", 22),
  ("NJU_CE_201400013", "mm", 25);


```



```sql
/* 订单信息 */


DROP TABLE IF EXISTS `order_infos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `order_infos` (
  `id`           BIGINT(20)  NOT NULL AUTO_INCREMENT,
  `member_id`      BIGINT(20)           DEFAULT NULL,
  `product_name` VARCHAR(50) NOT NULL DEFAULT '',
  `productor`    VARCHAR(30)          DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_user_product_detail` (`member_id`, `product_name`, `productor`)
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8

TRUNCATE `order_infos`;

INSERT INTO order_infos
  (member_id, product_name, productor)
VALUES
  (1, 'p1', 'WHH'),
  (1, 'p2', 'WL'),
  (1, 'p1', 'DX'),
  (2, 'p1', 'WHH'),
  (2, 'p5', 'WL'),
  (3, 'p3', 'MA'),
  (4, 'p1', 'WHH'),
  (6, 'p1', 'WHH'),
  (9, 'p8', 'TE'),
  (10, 'p1', 'WHH'),
  (13, 'p2', 'WL'),
  (11, 'p1', 'DX'),
  (20, 'p1', 'WHH'),
  (18, 'p5', 'WL'),
  (16, 'p3', 'MA'),
  (12, 'p1', 'WHH'),
  (12, 'p1', 'WHH'),
  (10, 'p8', 'TE');


```



## EXPLAIN 输出格式

`EXLPAIN`命令的输出内容大致如下:

```sql
> mysql root@127.0.0.1:explain_examples> EXPLAIN SELECT * FROM members WHERE id = 10\G

***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | members
partitions    | <null>
type          | const
possible_keys | PRIMARY
key           | PRIMARY
key_len       | 8
ref           | const
rows          | 1
filtered      | 100.0
Extra         | <null>
```

各列的含义如下:

- id: `SELECT` 查询的标识符. 每个 `SELECT` 都会自动分配一个唯一的标识符.
- select_type: `SELECT` 查询的类型.
- table: 查询的是哪个表
- partitions: 匹配的分区
- type:` join` 类型
- possible_keys: 此次查询中可能选用的索引
- key: 此次查询中确切使用到的索引.
- ref: 哪个字段或常数与` key` 一起被使用
- rows: 显示此查询一共扫描了多少行. 这个是一个估计值.
- filtered: 表示此查询条件所过滤的数据的百分比
- extra: 额外的信息





### select_type

`select_type`表示查询的类型,常见取值如下:

- SIMPLE, 表示此查询不包含 UNION 查询或子查询
- PRIMARY, 表示此查询是最外层的查询
- UNION, 表示此查询是 UNION 的第二或随后的查询
- DEPENDENT UNION, UNION 中的第二个或后面的查询语句, 取决于外面的查询
- UNION RESULT, UNION 的结果
- SUBQUERY, 子查询中的第一个 SELECT
- DEPENDENT SUBQUERY: 子查询中的第一个 SELECT, 取决于外面的查询. 即子查询依赖于外层查询的结果.



最常见的查询类别应该是 `SIMPLE` 了, 比如当我们的查询没有子查询, 也没有 UNION 查询时, 那么通常就是 `SIMPLE` 类型, 例如:

```sql
> EXPLAIN SELECT * FROM order_infos WHERE id = 10\G
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | order_infos
partitions    | <null>
type          | const
possible_keys | PRIMARY
key           | PRIMARY
key_len       | 8
ref           | const
rows          | 1
filtered      | 100.0
Extra         | <null>
```



如果我们使用了`UNION`查询，那么`EXPLAIN`输出的结果如下:

```sql
> EXPLAIN (SELECT * FROM members WHERE id IN(1,2,3)) 
> UNION
> (SELECT * from members WHERE id IN (3,4,5))\G;

***************************[ 1. row ]***************************
id            | 1
select_type   | PRIMARY
table         | members
partitions    | <null>
type          | range
possible_keys | PRIMARY
key           | PRIMARY
key_len       | 8
ref           | <null>
rows          | 3
filtered      | 100.0
Extra         | Using where
***************************[ 2. row ]***************************
id            | 2
select_type   | UNION
table         | members
partitions    | <null>
type          | range
possible_keys | PRIMARY
key           | PRIMARY
key_len       | 8
ref           | <null>
rows          | 3
filtered      | 100.0
Extra         | Using where
***************************[ 3. row ]***************************
id            | <null>
select_type   | UNION RESULT
table         | <union1,2>
partitions    | <null>
type          | ALL
possible_keys | <null>
key           | <null>
key_len       | <null>
ref           | <null>
rows          | <null>
filtered      | <null>
Extra         | Using temporary
```



### table

查询涉及的表或者衍生表



### type

`type`字段非常重要，它提供了判断查询是否高效的重要依据。

通过`type`字段，我们可以判断此次查询是`全表扫描`还是`索引扫描`等。



#### system

表中只有一条数据。这个类型是特殊的`const`类型.



#### const

针对主键或者唯一索引的等值查询扫描，最多只返回一条数据。

`const`数据非常快，因为它仅仅读取一次即可。

* 下面的查询使用了主键索引(id),因此`type`就是`const`类型.

```sql
EXPLAIN SELECT * FROM members WHERE id = 10\G

***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | members
partitions    | <null>
type          | const
possible_keys | PRIMARY
key           | PRIMARY
key_len       | 8
ref           | const
rows          | 1
filtered      | 100.0
Extra         | <null>
```



* 对于唯一索引来说，`type`也是`const`类型。因为等值查询的结果最多只有一条匹配记录。

```sql
> EXPLAIN SELECT * FROM members WHERE no = 'NJU_EE_20140009'\G;
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | members
partitions    | <null>
type          | const
possible_keys | index_members_on_no
key           | index_members_on_no
key_len       | 62
ref           | const
rows          | 1
filtered      | 100.0
Extra         | <null>
```



### eq_ref

唯一性索引扫描，对于每个索引键，表中只有一条记录与之匹配。常见于主键或者唯一索引扫描.

结果集一般不是一条记录，所有通常应用于`join`关联关系中.



对于前表的每一个结果，都只能匹配到后表的一行结果，并且查询的比较操作通常为`=`,查询效率比较高.

对于`Rails`关联关系中，通过对应于`has_one belongs_to`关系表

```sql
> EXPLAIN SELECT * FROM members, order_infos WHERE members.id = order_infos.member_id\G;
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | order_infos
partitions    | <null>
type          | index
possible_keys | index_user_product_detail
key           | index_user_product_detail
key_len       | 254
ref           | <null>
rows          | 18
filtered      | 100.0
Extra         | Using where; Using index
***************************[ 2. row ]***************************
id            | 1
select_type   | SIMPLE
table         | members
partitions    | <null>
type          | eq_ref(members表中`type`为 eq_ref)
possible_keys | PRIMARY
key           | PRIMARY
key_len       | 8
ref           | explain_examples.order_infos.member_id
rows          | 1
filtered      | 100.0
Extra         | <null>
```



上述查询中

*  `order_infos`表`type`: `index`.查询`order_infos`表时使用了联合索引的最左匹配,类型为`index`.

* `members`表`type`: `eq_ref`.查询`members`表时由于用到的是主键，所以这里的`type`为`eq_ref`.


### ref

* 非唯一索引
* 非主键索引
* 使用了`最左匹配`规则索引的查询

返回匹配某个单独值所有行.

本质上也是一种索引访问，它返回所有匹配某个单独值的所有行,可能会找到多个符合条件的行。

```sql
> EXPLAIN SELECT * FROM members, order_infos WHERE members.id = order_infos.member_id AND order_infos.member_id = 10  \G;
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | members
partitions    | <null>
type          | const
possible_keys | PRIMARY
key           | PRIMARY
key_len       | 8
ref           | const
rows          | 1
filtered      | 100.0
Extra         | <null>
***************************[ 2. row ]***************************
id            | 1
select_type   | SIMPLE
table         | order_infos
partitions    | <null>
type          | ref
possible_keys | index_user_product_detail
key           | index_user_product_detail
key_len       | 9
ref           | const
rows          | 2
filtered      | 100.0
Extra         | Using index
```



对于上述的查询:

* `members`: const
* `order_infos`: ref



```sql
> EXPLAIN SELECT * FROM members WHERE members.name = 'aa'\G;

***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | members
partitions    | <null>
type          | ref
possible_keys | index_members_on_name
key           | index_members_on_name
key_len       | 62
ref           | const
rows          | 1
filtered      | 100.0
Extra         | <null>
```



上述查询就是简单的使用非唯一索引`index_on_members_name`来查询,返回的结果集中不一定是一条记录。



#### range

使用索引范围查询，通过索引字段范围获取表中部分数据记录。

这种范围扫描索引比全表扫描更好，因为它值需要开始于索引的某个点，而结束于另一点不用扫描全部索引。



* `=`
* `<>`
* `>`
* `>=`
* `<`
* `<=`
* `<=>`
* IS NULL
* BETWEEN
* IN()

下面的例子就是一个范围查询:

```sql
> EXPLAIN SELECT * FROM members WHERE id BETWEEN 2 AND 8\G;
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | members
partitions    | <null>
type          | range
possible_keys | PRIMARY
key           | PRIMARY
key_len       | 8
ref           | <null>
rows          | 7
filtered      | 100.0
Extra         | Using where
```



当`type`为`range`时，`EXPLAIN`数据的 `ref`字段为`NULL`,并且`key_len`字段时此次查询中使用到的索引最长的那个。



#### index

表示全表扫描(full index scan),和`ALL`类似。

只不过`ALL`类似是全表扫描，而`index`类型则仅仅扫描所有的所有，而不扫描数据。

`index` 类型通常出现在`所要查询的数据直接在索引树`中获得，而不需要扫描数据。不过如果数据量大的话，还需要进一步优化。

这种情况下，`Extra`字段就会显示`index`.

```sql
EXPLAIN SELECT name FROM members\G;

***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | members
partitions    | <null>
type          | index
possible_keys | <null>
key           | index_members_on_name
key_len       | 62
ref           | <null>
rows          | 26
filtered      | 100.0
Extra         | Using index
```



上面的例子中，我们查询的`name`字段恰好是一个索引，因此我们直接从索引中获取数据就可以满足查询的需求,此时`Extra`的值是`Using Index`.



#### all

全表扫描，这个类型的查询是性能最差的查询之一。

通常来说，我们的查询是不应该出现`ALL`类型的查询，因为这样的查询在数据量大的情况下，对数据的性能是巨大的灾难。如果一个查询是`ALL`类型查询，我们可以对相应的字段添加索引来避免。

```sql
> EXPLAIN SELECT * FROM members WHERE age = 20\G;

***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | members
partitions    | <null>
type          | ALL
possible_keys | <null>
key           | <null>
key_len       | <null>
ref           | <null>
rows          | 26
filtered      | 10.0
Extra         | Using where
```

上面的查询我们可以看到，在全表扫描时，`possible_keys`和`key` 字段均为`NULL`,表示没有使用到索引，并且`row`十分巨大，整个查询效率十分低下.



### type类型的性能比较

#### type 类型的性能比较

通常来说, 不同的 type 类型的性能关系如下:



`ALL < index < range ~ index_merge < ref < eq_ref < const < system`



`ALL` 类型因为是全表扫描, 因此在相同的查询条件下, 它是速度最慢的.

 `index` 类型的查询虽然不是全表扫描, 但是它扫描了所有的索引, 因此比 ALL 类型的稍快.

后面的几种类型都是利用了索引来查询数据, 因此可以过滤部分或大部分数据, 因此查询效率就比较高了.



### possible_keys 

显示可能应用在这张表中的索引，一个或多个。

查询涉及到的字段若存在索引，则该索引将被列出，但是不一定查询实际用到。



### key

查询实际用到的`索引`



### key_len

表示索引中使用的字节数，可通过该列计算查询中使用的索引的长度。

在不损失精度的情况下，长度越短越好。

`key_len`显示的值为索引字段的最大可能长度，并非实际使用长度，即`key_len`根据表定义计算得出，不是通过表内检索出。



```sql

DROP TABLE IF EXISTS `users`;

CREATE TABLE users (
  id INT(10) NOT NULL,
  tel INT(10)    DEFAULT NULL,
  first_name varchar(10) NOT NULL,
  last_name  varchar(10) DEFAULT NULL,
  father     char(10) NOT NULL,
  mother     char(10) DEFAULT NULL,
  PRIMARY KEY(id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8;

/* 插入数据 */
INSERT INTO users
  (id, tel, first_name, last_name, father, mother)
VALUES
  (1, 212, 'A', 'Jack', 'F', 'M'),
  (2, 213, 'B', 'Jack', 'F', 'M'),
  (3, 214, 'C', 'Jack', 'F', 'M'),
  (4, 215, 'D', 'Jack', 'F', 'M'),
  (5, 216, 'E', 'Jack', 'F', 'M'),
  (6, 217, 'F', 'Jack', 'F', 'M'),
  (7, 218, 'G', 'Jack', 'F', 'M'),
  (8, 219, 'H', 'Jack', 'F', 'M'),
  (9, 220, 'I', 'Jack', 'F', 'M'),
  (10, 221, 'J', 'Jack', 'F', 'M'),
  (11, 222, 'K', 'Jack', 'F', 'M'),
  (13, 223, 'L', 'Jack', 'F', 'M');


/* 添加索引 */
ALTER TABLE users add index index_id(id);
ALTER TABLE users add index index_tel(tel);
ALTER TABLE users add index index_fn(first_name);
ALTER TABLE users add index index_ln(last_name);
ALTER TABLE users add index index_fa(father);
ALTER TABLE users add index index_ma(mother);


```

我们可以测试每个`key_len`的长度:

```sql
/* int NOT NULL */
> EXPLAIN SELECT * FROM users where id = 3\G
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | users
partitions    | <null>
type          | const
possible_keys | PRIMARY,index_id
key           | PRIMARY
key_len       | 4
ref           | const
rows          | 1
filtered      | 100.0
Extra         | <null>

key_len = len(int) -> 4
```



```sql
/* int DEFAULT NULL */
> EXPLAIN SELECT * FROM users where tel = 212\G
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | users
partitions    | <null>
type          | ref
possible_keys | index_tel
key           | index_tel
key_len       | 5
ref           | const
rows          | 1
filtered      | 100.0
Extra         | <null>

key_len = len(int) + len(NULL) -> 5
* NULL 占用一个字节
```



```sql
/* varchar NOT NULL  */
> EXPLAIN SELECT * FROM users where first_name = 'A'\G;

***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | users
partitions    | <null>
type          | ref
possible_keys | index_fn
key           | index_fn
key_len       | 32
ref           | const
rows          | 1
filtered      | 100.0
Extra         | <null>

key_len = 10 * 3 + 2 -> 32

* utf8占用三个字节
* varchar 需要额外占用两个字节
```



```sql
/* varchar DEFAULT NULL */
> EXPLAIN SELECT * FROM users where last_name = 'A'\G;
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | users
partitions    | <null>
type          | ref
possible_keys | index_ln
key           | index_ln
key_len       | 33
ref           | const
rows          | 1
filtered      | 100.0
Extra         | <null>

key_len = 10 * 3 + 2 + 1(NULL) -> 33
```



```sql
/* char NOT NULL */
> EXPLAIN SELECT * FROM users where father = 'A'\G

***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | users
partitions    | <null>
type          | ref
possible_keys | index_fa
key           | index_fa
key_len       | 30
ref           | const
rows          | 1
filtered      | 100.0
Extra         | <null>

key_len = 10 * 3 -> 30
```



```sql
/* char DEFAULT NULL */
> EXPLAIN SELECT * FROM users where mother = 'A'\G

***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | users
partitions    | <null>
type          | ref
possible_keys | index_ma
key           | index_ma
key_len       | 31
ref           | const
rows          | 1
filtered      | 100.0
Extra         | <null>

key_len = 10 * 3 + 1 -> 31
```



我们可以总结一下:

* 一般情况下，key_len = 字段字符数 * 字符集每个字符所占字节数
* DEFAULT NULL: key_len + 1
* VARCHAR: key_len + 2
* INT: key_len = 4
* BIGINT: key_len = 8



**索引字段最好不要为NULL，因为NULL让统计更加复杂，并且需要额外一个字节的存储空间**





### ref

显示索引的哪一个字段被使用。如果可能的话，是一个常数。



### rows

根据表统计信息及搜索选用情况，大致估算出找到所需记录读取的行数。



### extra(列返回的描述的意义)



* *Using filesort*：看到这个的时候，查询就需要优化了。说明Mysql会对数据使用一个外部的索引排序，而不是按照表内的索引顺序进行读取。Mysql中无法利用索引完成的排序操作称之为文件排序。Mysql需要进行额外的步骤来发现如何对返回的行排序。它根据连接类型以及存储排序键值和匹配条件的全部行的行指针来排序全部行。



* *Using index*: 列数据是从仅仅使用了索引中的信息而没有读取实际的行动的表返回的，这发生在对表的全部的请求列都是同一个索引的部分的时候。表示相应的select操作中使用了覆盖索引（Coverindex ing），避免访问了表的数据行，效果理想！如果同时出现using where，表示索引被用来执行索引键值的查找；如果没有同时出现using where，表示索引用来读取数据而非执行查找动作。



```sql
/* 只选择索引列 */
> EXPLAIN SELECT name FROM members\G;
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | members
partitions    | <null>
type          | index
possible_keys | <null>
key           | index_members_on_name
key_len       | 62
ref           | <null>
rows          | 26
filtered      | 100.0
Extra         | Using index

> EXPLAIN SELECT name FROM members where name = 'A'\G;
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | members
partitions    | <null>
type          | ref
possible_keys | index_members_on_name
key           | index_members_on_name
key_len       | 62
ref           | const
rows          | 1
filtered      | 100.0
Extra         | Using index

通过索引查询时我们只取索引对应的列，就可以保证使用`覆盖索引`
```

覆盖索引的含义： 就是select的数据列只用从索引中就能够取得，不必读取数据行，Mysql可以利用索引返回select列表中的字段，而不必根据索引再次读取数据文件，换句话说查询列要被所建的索引覆盖。注意的是，如果要使用覆盖索引，一定要注意select列表中只读取出需要的列，而不是select *，因为如果将所有字段一起做索引会导致索引文件过大，降低查询性能。



```sql
> EXPLAIN SELECT id FROM members where id IN(1,2,3)\G;

这里执行了搜索，同时使用索引读取数据

***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | members
partitions    | <null>
type          | range
possible_keys | PRIMARY
key           | PRIMARY
key_len       | 8
ref           | <null>
rows          | 3
filtered      | 100.0
Extra         | Using where; Using index
```



* *Using temporary*：看到这个的时候，查询需要优化了。这里，Mysql需要创建一个临时表来存储结果，这通常发生在对不同的列集进行ORDER BY上和GROUP BY上，拖慢与sql查询。



####  **覆盖索引(Covering Indexes)**

**mysql高效索引之覆盖索引**

　　覆盖索引是一种非常强大的工具，能大大提高查询性能。设计优秀的索引应该考虑到整个查询，而不单单的where条件部分。索引确实是一种查找数据的高效方式，但是MYSQL也可以使用索引来直接获取列的数据，这样就不再需要读取数据行。索引的叶子节点中已经包含要查询的数据，那么就没有必要再回表查询了，**如果索引包含满足查询的所有数据，就称为覆盖索引。**

　　解释一： 就是select的数据列只用从索引中就能够取得，不必从数据表中读取，换句话说查询列要被所使用的索引覆盖。
　　解释二： 索引是高效找到行的一个方法，当能通过检索索引就可以读取想要的数据，那就不需要再到数据表中读取行了。如果一个索引包含了（或覆盖了）满足查询语句中字段与条件的数据就叫做覆盖索引。
　　解释三： 是非聚集组合索引的一种形式，它包括在查询里的Select、Join和Where子句用到的所有列（即建立索引的字段正好是覆盖查询语句[select子句]与查询条件[Where子句]中所涉及的字段，也即，索引包含了查询正在查找的所有数据）。

只需要读取索引而不用读取数据有以下一些优点：
**(1)索引项通常比记录要小，所以MySQL访问更少的数据；(2)索引都按值的大小顺序存储，相对于随机访问记录，需要更少的I/O；(3)大多数据引擎能更好的缓存索引。比如MyISAM只缓存索引。(4)覆盖索引对于InnoDB表尤其有用，因为InnoDB使用聚集索引组织数据，如果二级索引中包含查询所需的数据，就不再需要在聚集索引中查找了。覆盖索引不能是任何索引，只有B-TREE索引存储相应的值。而且不同的存储引擎实现覆盖索引的方式都不同，并不是所有存储引擎都支持覆盖索引(Memory和Falcon就不支持)。**
对于索引覆盖查询(index-covered query)，使用EXPLAIN时，可以在Extra一列中看到“Using index”。例如，在sakila的inventory表中，有一个组合索引(store_id,film_id)，对于只需要访问这两列的查询，MySQL就可以使用索引.