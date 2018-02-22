---
layout: post
title: 二叉搜索树
date: 2015-04-06 23:46:57.000000000 +08:00
permalink: /:title
---



二叉搜索树是以一棵二叉树来组织的, 其中每一个结点都是一个对象, 每个结点都包含属性 `left` `right` 和 `p`, 它们分别指向结点的 left child, right child 和 parent. 如果某个 child 结点不存在, 那么相应的属性就为 `nil`.

二叉搜索树中的关键字的总是以满足二叉树性质的方式来存储:

> 其中对于任何一个结点, left child 中存储的数据都不会大于 parent, right child 中存储的数据都不会小于 parent.


![](/content/images/2015/04/bonary-tree.png)

我们先来实现一下树的数据结构:

~~~
class Tree
	attr_accessor :root, :left, :right, :parent, :key
	def initialize
		@left = nil
		@right = nil
		@parent = nil
		@key = nil
	end
end
~~~

##Traverse

二叉搜索树性质允许我们通过一个简单的递归算法来按序输出二叉搜索树中的所有关键字, 这种算法称为**中序遍历**, 这样的命名是因为输出的 root 的关键字位于其 left child 和 right child 之间. 类似地, 我们有**先序遍历**和**后序遍历**.

~~~
def inorder_tree_walk(tree)
	if tree != nil
		inorder_tree_walk(tree.left)
		puts tree.key
		inorder_tree_walk(tree.right)
end

def preorder_tree_walk(tree)
	if tree != nil
		puts tree.key
		preorder_tree_walk(tree.left)
		preorder_tree_walk(tree.right)
end

def postorder_tree_walk(tree)
	if tree != nil
		postorder_tree_walk(tree.left)
		postorder_tree_walk(tree.right)
		puts tree.key
end
~~~

遍历一棵 $n$ 个结点的二叉搜索树, 需要耗费 $\Theta(n)$ 的时间, 因为在第一次调用之后, 每个结点还要调用自己两次, 分别是 left 和 right child.

##Query

我们经常需要查找存在二叉搜索树中的关键字. 我们不仅需要支持 `SEARCH` 操作之外, 二叉搜索树还能支持还能支持诸如 `MINIMUM` `MAXIMUM` `SUCCESSOR` `PREDECESSOR` 的查询操作. 并且这些操作都能在 $O(h)$ 时间内完成.

###Search

查找操作非常的简单, 我们接下来用 Ruby 实现查找操作.

~~~
def tree_search(tree, key)
	if tree == nil or key == tree.key
		return tree
	end
	if key < tree.key
		return tree_search(tree.left, key)
	else
		return tree_search(tree.right, key)
	end
end
~~~

这个过程从 root 开始查找, 并沿着树中的一条简单的路径向下进行. 不断与 tree.key 比较, 选择最合适的路径.

我们也可以使用循环来解决我们的问题, 不过在这里我们不在演示了.

###Minimum Maximum

二叉搜索树的最大关键字和最小关键字的查找十分的简单, 我们这里直接给出 Ruby 的实现代码.

~~~
def tree_minimum(tree)
	if tree.left != nil
		tree_minimum(tree.left)
	else
		tree
	end
end

def tree_maximum(tree)
	if tree.left != nil
		tree_maximum(tree.left)
	else
		tree
	end
end
~~~

这两个过程在一棵高度为 $h$ 的树上均能在 $O(h)$ 时间内执行玩, 所遇到的结点均形成了一条从 root 向下的简单路径.

###Successor Predecessor

给定一棵二叉搜索树中的一个结点, 有时候需要按照中序遍历的次序查找它的后继:

~~~
def tree_successor(tree)
	return tree_successor if tree.right != nil
	parent = tree.parent
	whlie parent != nil and tree == parent.right
		tree = parent
		parent = parent.parent
	end
	parent
end
~~~

我们把 `tree_successor` 的伪代码分成两个部分

* 如果结点的 right child 非空, 那么结点的 successor 就是结点 right child 中的最左结点.
* 如果结点的 right child 为空, 那么它的后继就是该结点最底层的 parent.

同理, 查找树的 predecessor 的代码如下:

~~~
def tree_predecessor(tree)
	return tree_predecessor if tree.left != nil
	parent = tree.parent
	whlie parent != nil and tree == parent.left
		tree = parent
		parent = parent.parent
	end
	parent
end
~~~

##Insert and Delete

插入和删除的操作会导致二叉搜索树表示的动态集合的变化, 一定要修改数据结构来反映这个变化, 但修改要保持二叉搜索树性质的成立.

###Insert

要将一个新的值 $v$ 插入到一棵二叉搜索树 $T$ 中, 需要调用一下过程 `tree-insert`. 

~~~
def tree_insert(tree,z)
	y = nil
	x = tree
	while tree != nil
		y = tree
		if tree.key < x.key
			tree = tree.left
		else
			tree = tree.right
		end
	end
	z.parent = y
	if y == nil
		tree = z
	elsif z.key < y.key
		y.left = z
	else
		y.right = z
	end
end
~~~

该过程在高度为 $h$ 的二叉搜索树上的运行时间为 $O(h)$.

###Delete

从一个二叉搜索树 $T$ 中删除一个结点 $z$ 的整个策略分为三中基本情况

* 如果 $z$ 没有子节点, 那么只是简单地将它删除, 并将它的父结点置为 `nil`.
* 如果 $z$ 只有一个子节点, 那么直接将子节点提升到 $z$ 的位置, 并修改 $z$ 的父结点, 用子节点来代替.
* 如果 $z$ 有两个子节点, 那么找 $z$ 的后继 $y$, 并让 $y$ 占据树中 $z$ 的位置. $z$. $z$ 的原右子树部分成为 $y$ 的新的右子树, $z$ 的原左子树部分成为 $y$ 的新的左子树.
	* 如果 $y$ 是 $z$ 的 right child, 那么直接用 $y$ 替换 $z$, 并留下 $y$ 的 right child.
	* 否则, $y$ 位于右子树中, 但并不是 $z$ 的 right child, 先用 $y$ 的 right child 替换 $y$, 然后再用 $y$ 替换 $z$.
	
<img src="http://deltax.qiniudn.com/delete-binary-tree.png?attname=&e=1428419679&token=YJb_IPQrTSw1ox9LenQDH1HRcgHii9w_bp9ddmcz:uJFRzAVs3zXywADKNRUrZmfItl4" style="display:block;margin:auto"/>

为了在二叉搜索树内移动子树, 定义了一个子过程 `tranplant`, 它用另一棵子树替换一棵子树并成为其双亲的子节点.


~~~
def transplant(tree, u, v)
	if u.parent == nil
		tree.root = v
	elsif u == u.parent.left
		u.parent.left = v
	else
		u.parent.right = v
	end
	if v != nil
		v.parent = u.parent
	end
end
~~~

利用线程的 `transplant` 过程, 下面是从二叉树中删除结点 $z$ 的删除过程.

~~~
def tree_delete(tree,z)
	if z.left = nil
		transplant(tree, z, z.right)
	elsif z.right = nil
		transplant(tree, z, z.left)
	else
		y = tree_minimum(z.right)
		if y.parent != z
			transplant(tree, y, y.right)
			y.right = z.right
			y.right.parent = y
		end
		transplant(tree, z, y)
		y.left = z.left
		y.left.parent = y
	end
end
~~~

在一棵高度为 $h$ 的树上, 事项动态集合操作 `INSERT` 和 `DELETE` 的运行时间均为 $O(h)$.
