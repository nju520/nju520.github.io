---
layout: post
title: 散列表
date: 2015-04-05 00:33:49.000000000 +08:00
permalink: /:title
---


散列表(hash table)是实现字典操作的一种有效的数据结构. 尽管在最坏情况下, 散列表中查找一个元素的时间与链表中查找的时间相同, 达到了 $\Theta(n)$. 然而在实际的应用中, 散列表的性能是极好的, 查找元素的平均时间是 $O(1)$.

##直接寻址表

当关键字的全域 $U$ 比较小的时候, 直接寻址是一种简单有效的技术. 为表示动态集合, 我们用一个数组, 或称为**直接寻址表**, 记为 $T[0..m-1]$ 其中每个位置称为**槽**(slot).

![](/content/images/2015/04/direct-address.png)


如果该集合中没有关键字为 $k$ 的元素, 那么 $T[k]=nil$.

我们使用 Ruby 来实现我们直接寻址表的操作.

~~~
class DirectAddressTable

	def initialize
		@table = []
	end

	def search(k)
		@table[k]
	end

	def insert(x)
		@table[x.key] = x
	end

	def delete(x)
		@table[x.key] = nil
	end

end
~~~

直接寻址表本身就存放动态集合中的元素. 我们直接把对象存放在表的槽中, 节省了空间. 使用对象内的一个特殊关键字 `nil` 来表明槽为空. 因此我们如果知道一个对象在表中的下标就可以得到它的关键字. 因此如果不使用关键字, 我们就需要有一种方法来确定某个槽是否为空.

##散列表

直接寻址技术的缺点是及其明显的, 如果全域 $U$ 很大, 那么存储大小为 $\left|U \right|$ 的一张表 $T$ 也许不太实际. 实际存储的关键字集合 $K$ 相对 $U$ 来说可能很小, 使得分配地空间会被浪费掉.

在直接寻址方式下, 具有关键字 $k$ 的元素被存放在槽 $k$ 中. 在散列方式下, 该元素存放在槽 $h(k)$ 中. 使用散列函数 $h$, 通过关键字 $k$ 计算出槽的位置. 

函数 $h$ 将关键字的全域 $U$ 映射到**散列表** $T[0..m-1]$ 中的槽上:

$$h:U\rightarrow \big\\{0,1,...,m-1 \big\\}$$

一个具有关键字 $k$ 的元素被散列到槽 $h(k)$ 上, 也可以说 $h(k)$ 是关键字 $k$ 的**散列值**.

![](/content/images/2015/04/hash.png)

这里可能存在一个问题: 两个关键字可能映射到同一个槽中, 我们称这种情形为**冲突**(collision). 我们接下来介绍两种方法解决这种冲突, 一种称为**链接法**, 一种称为**开放寻址法**.

###链接法

链接法非常地简单, 只需要把 hash 到同一槽中的元素放到同一个链表中, 槽中有一个指针会指向链表的开头, 如果不存在则为 `nil`.

![](/content/images/2015/04/chaining-hash.png)

<img src="http://deltax.qiniudn.com/chaining-hash.png?attname=&e=1428237885&token=YJb_IPQrTSw1ox9LenQDH1HRcgHii9w_bp9ddmcz:Mi4Zu4awW1VX2A2y7DIoNYLYPQo" style="display:block;margin:auto"/>

使用链接法后, 散列表中的操作就很容易实现了:

~~~
class ChainedHashTable
	
	def initialize
		@table = []
	end

	def insert(x)
		if @table[x.key.hash]
			@table[x.key.hash] << x
		else
			@table[x.key.hash] = [x]
		end	
	end

	def search(k)
		@table[k.hash].each do |key|
			if key == k
				return k
			end
		end
	end

	def delete(x)
		@table[x.key.hash].delete(x)
	end

end
~~~

插入操作的最坏情况的运行时间为 $O(1)$. 查找操作的最坏情况运行时间与表的长度成正比. 如果散列表中的链表是双向链接的, 则删除一个元素 $x$ 的操作可以在 $O(1)$ 时间内完成.

给定一个能存放 $n$ 个元素的, 具有 $m$ 个槽位的散列表 $T$, 定义 $T$ 的**装载因子** $\alpha$ 为 $n/m$, 即一个链的平均存储元素数, $\alpha$ 可以小于等于或大于 $1$. 散列方法的平均性能依赖于使用的散列函数 $h$, 将所有的关键字集合分不在 $m$ 个槽位上的均匀程度.

在简单均匀散列的假设下, 对于用链接法解决冲突的散列表, 一次不成功查找的平均时间为 $\Theta(1+\alpha)$.

###开放寻址法

在开放寻址法中, 所有的元素都存放在散列表里, 也就是说, 每一个表项或包含动态集合的宇哥元素, 或包含 `NIL`. 查找某个元素时, 要系统地检查所有的表项, 知道找到所需的元素, 或者最终查明该元素不在表中.

开放寻址法中的散列表可能会被填满, 以至于不能插入任何的新元素. 所以装在因子 $\alpha \leq 1$.

为了使用开发寻址法插入一个元素, 需要连续地检查散列表, 或称为**探查**(probe). 知道找到一个空的槽来插入关键字为止, 探查的顺序不一定是 $0,1,...,m-1$, 而是要依赖于待插入的关键字. 使之包含探查号作为第二个输入参数, 我们的散列函数就变为:

$$h: U \times \big\\{ 0,1,...,,-1 \big\\}  \rightarrow  \big\\{ 0,1,...,,-1 \big\\}$$

对没一个关键字 $k$, 使用开放寻址法的探查序列

$$ \big \langle h(k,0),h(k,1),...,h(k,m-1) \big \rangle$$

这样的散列序列的排列, 使得当散列表逐渐填满时, 每一个表位最终都可以被考虑为用来插入新关键字的槽.

当向散列表中插入数据时, 我们使用如下的过程:

~~~
class OpenAddressHashTable

	def initialize(max)
		@max = max
		@table = []
	end

	def insert(k)
		i = 0
		
		until i == m
			j = k.hash(i)
			if @table[j] == nil
				@table[j] = k
				return j
			else
				i = i + 1
			end
		end
		
		raise "Hash table overflow!"
	end

	def search(k)
		i = 0

		until @table[j] == nil || i == m
			j = k.hash(i)
			if @table[j] == nil
				return j
			end
			i = i + 1
		end

		nil
	end

end
~~~
查找关键字 $k$ 的算法探查序列与将 $k$ 插入时的算法相同.

从开放寻址法的散列表中删除操作元素比较困难, 因为不能直接将其设置为 `nil` 标识它为空. 如果这样做就会有问题, 就是在槽中置一个特定的值 `DELETED` 替代为 `NIL` 来标记该槽. 但是在必须删除关键字的应用中, 最常见的做法是使用链接法来解决冲突.

目前, 我们又三种技术来计算开放寻址法中的探查序列: 线性探查, 二次探查和双重探查. 在这里我们不会介绍.

##散列函数

在散列函数在使用中经常使用启发式方法来构造性能好的散列函数, 在这里我们只介绍两种启发式的方法, 除法散列表和乘法散列表.

###除法散列法

在用来设计散列函数的除法散列表中, 通过取 $k$ 除以 $m$ 的余数, 讲关键字 $k$ 映射到 $m$ 个槽中的某一个, 即散列函数为:

$$h(k)=k \mod m$$

当应用除法散列法时, 要避免选择 $m$ 的某些值, 不应为 $2$ 的幂, 或者 $10$ 的幂. 一个不太接近 $2$ 的整数幂的素数是一个比较好的选择.

###乘法散列法

构造散列函数的乘法的散列法包含两个步骤. 第一步, 用关键字 $k$ 乘上常熟 $A(0 \le A \le 1)$, 并提取 $kA$ 的小数部分. 第二步, 用 $m$ 乘以这个值, 再向下取整. 散列函数为:

$$h(k) = \left \lceil{m(kA \mod 1)}\right \rceil $$

乘法散列法的一个优点就是对 $m$ 的选择不是特别的关键, 一般选择它为 $2$ 的某个幂次.

Knuth 认为

$$A \approx (\sqrt{5}-1)/2 = 0.618 033 988 7...$$

是个比较理想的数值.
