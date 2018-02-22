---
layout: post
title: 红黑树
date: 2015-04-07 18:02:48.000000000 +08:00
permalink: /:title
---


红黑树是一棵二叉搜索树, 它在每个结点上增加了一个存储位来表示结点的颜色, 可以使 `RED` 或 `BLACK`. 红黑树中没有一条路径会比其他路径长出 2 倍, 所以是近似平衡的.

树中的每个结点包含 5 个属性: `color, key, left, right 和 parent`. 下面是一个红黑树需要满足的性质:

1. 每个结点是红色的或者是黑色的.
2. 根节点是黑色的.
3. 每个叶结点是黑色的.
4. 如果一个结点是红色的, 则它的两个子节点都是黑色的.
5. 对每个结点, 从该结点到其所有后代子结点的简单路径上, 均包含相同数目的黑色结点.

##旋转

搜索树的操作 `tree_insert` 和 `tree_delete` 在含 $n$ 个关键字的红黑树上, 运行时间都为 $O(\lg n)$. 但是这两个操作可能会违反红黑树的性质, 所以我们需要在适当的时间改变树中每个结点的颜色以及指针结构.

指针结构的修改是通过**旋转**来完成的, 这是一种能保持二叉搜索树性质的局部操作.

![](/content/images/2015/04/rotate.png)

~~~
struct tree_t {
    struct node_t *root;
};

struct node_t {
    struct node_t *left;
    struct node_t *right;
    struct node_t *parent;
    color_t color;
    int key;
}

void left_rotate(tree_t *tree, node_t *x) {
    node_t *y = x->right;
    x->right = y->left;

    if (y->left != NULL) {
        y->left->parent = x;
    }
    y->parent = x->parent;

    if (x->parent == NULL) {
        tree->root = y;
    } else if (x == x->parent->left) {
        x->parent->left = y;
    } else {
        x->parent->right = y;
    }
    y->left = x;
    x->parent = y;
}

void right_rotate(tree_t *tree, node_t *x) {
    node_t *y = x->left;
    x->left = y->right;

    if (y->right != NULL) {
        y->left->parent = x;
    }
    y->parent = x->parent;

    if (x->parent == NULL) {
        tree->root = y;
    } else if (x == x->parent->right) {
        x->parent->right = y;
    } else {
        x->parent->left = y;
    }

    y->right = x;
    x->parent = y;
}
~~~

`left_rotate` 和 `right_rotate` 的都能在时间复杂度 $O(1)$ 内完成, 在这个操作中只有指针改变, 其他所有属性都保持不变.

##插入

我们可以在 $O(\lg n)$ 时间内完成向一棵含有 $n$ 个结点的红黑树中插入一个新结点. 我们在 `tree-insert` 的基础上进行修改, 实现了 `red_black_insert`, 同时我们调用一个辅助函数 `red_black_insert_fixup` 来对结点进行着色和旋转.

~~~
void red_black_insert(tree_t *tree, node_t *z) {
	node_t *t = NULL;
	node_t *x = tree.root;

	while (x != NULL) {
		y = x;
		if (z->key < x->key) {
			x = x->left;
		} else {
			x = x->right;
		}
	}

	z->parent = y;

	if (y == NULL) {
		tree->root = z;
	} else if (z->key < y->key) {
		y->left = z;
	} else {
		y->right = z;
	}

	z->left = NULL;
	z->right = NULL;
	z->color = RED;

	red_black_insert_fixup(tree, z);
}
~~~

因为将 z 着色为红色可能违反红黑书的性质, 所以我们需要 `red_black_insert_fixup` 来保持红黑性质.

~~~
void red_black_insert_fixup(tree_t *tree, node_t *z) {
	while (z->parent->colot == RED) {
		if (z->parent == z->parent->parent->left) {
			y = z->parent->parent->right;
			if (y->color == RED) {
				z->parent->color = BLACK;
				y->color = BLACK;
				z->parent->parent->color = RED;
				z = z->parent->parent;
			} else if (z == z->parent->right) {
				z = z->parent;
				left_rotate(tree, z);
			} else if (z == z->parent->left) {
				z->parent->color = BLACK;
				z->parent->parent->color = RED;
				right_rotate(tree, z->parent->parent);
			}
		} else {
			y = z->parent->parent->left;
			if (y->color == RED) {
				z->parent->color = BLACK;
				y->color = BLACK;
				z->parent->parent->color = RED;
				z = z->parent->parent;
			} else if (z == z->parent->left) {
				z = z->parent;
				right_rotate(tree, z);
			} else if (z == z->parent->right) {
				z->parent->color = BLACK;
				z->parent->parent->color = RED;
				left_rotate(tree, z->parent->parent);
			}
		}
	}
	tree->root->color = BLACK;
}
~~~

该过程总共有三种情况:


![](/content/images/2015/04/rb_fixup.png)


###情况1

`z` 的 uncle 结点是红色的, `y` 为 `z` 的 uncle 结点.

~~~
z->parent->color = BLACK;
y->color = BLACK;
z->parent->parent->color = RED;
z = z->parent->parent;
~~~

然后, 再次进入循环, `z` 变成了 `z->parent->parent`.

###情况2

`z` 的 uncle 结点是黑色的, 并且 `z` 是一个 right child.

~~~
z = z->parent;
left_rotate(tree, z);
~~~

向左旋转 `z` 的父结点.

###情况3

`z` 的 uncle 结点是黑色的, 并且 `z` 是一个 left child.

~~~
z->parent->color = BLACK;
z->parent->parent->color = RED;
right_rotate(tree, z->parent->parent);
~~~

##删除

删除一个结点需要话费 $O(\lg n)$ 时间. 与插入操作相比, 删除操作要稍微复杂一点.

从一棵红黑树中删除结点的过程是基于 `tree_delete` 过程, 我们需要设计一个 `transplant` 过程, 并将它应用到红黑树上.

~~~
void red_black_transplant(tree_t *tree, node_t *u, node_t *v) {
	if (u->parent == NULL) {
		tree->root = v;
	} else if (u == u->parent->left) {
		u->parent->left = v;
	} else {
		u->parent->right = v;
	}
	v->parent = u->parent;
}
~~~

这个过程非常的简单, 我们接下来实现 `red_black_delete` 函数.

~~~
void red_black_delete(tree_t *tree, node_t *z) {
	node_t *x;
	node_t *y = z;
	color_t y_original_color = y->color;

	if (z->left == NULL) {
		x = z->right;
		red_black_transplant(tree, z, z->right);
	} else if (z->right == NULL) {
		x = z->left;
		red_black_transplant(tree, z, z->left);
	} else {
		y = tree_minimum(z->right);
		x = y->right;
		if (y->parent == z) {
			x->parent = z;
		} else {
			red_black_transplant(tree, y, y->right);
			y->right = z->left;
			y->right->parent = y;
		}
		red_black_transplant(tree, z, y);
		y->left = z->left;
		y->left->parent = y;
		y->color = z->color;
	}

	if (y_original_color == BLACK) {
		red_black_delete_fixup(tree, x);
	}
}
~~~

`red_black_delete` 函数与 `tree_delete` 拥有相同的结构. 如果结点 y 是黑色的, 就会产生三个问题.

1. 如果 `y` 是原来的根节点, 而 `y` 的一个红色的 child 成为新的根节点
2. `x` 和 `x->parent` 是红色的.
3. 在树中移动 `y` 会导致先前包含结点 `y` 的任何简单路径上的黑色结点个数减少 `1`.

现在我们来看一下过程 `red_black_delete_fixup` 过程是如何修复这些问题的.

~~~
void red_black_delete_fixup(tree_t *t, node_t *x) {
	node_t *w;
	while (x != tree->root && x->color == BLACK) {
		if (x == x->parent->left) {
			w = x->parent->right;
			if (w->color == RED) {
				w->color = BLACK;
				x->parent->color = RED;
				left_rotate(tree, x->parent);
				w = x->parent->right;
			}
			if (w->left->color == BLACK && w->right->color == BLACK) {
				w->color = RED;
				x = x->parent;
			} else if (w->right->color == BLACK) {
				w->left->color = BLACK;
				w->color = RED;
				right_rotate(tree, w);
				w = x->parent->right;
			} else {
				w->color = x->parent->color;
				x->parent->color = BLACK;
				w->right->color = BLACK;
				left_rotate(tree, x->parent);
				x = tree->root;
			}
		} else {
			w = x->parent->left;
			if (w->color = RED) {
				w->color = BLACK;
				x->parent->color = RED;
				right_rotate(tree, x->parent);
				w = x->parent->left;
			}
			if (w->right->color == BLACK && w->left->color == BLACK) {
				w->color = RED;
				x = x->parent;
			} else if (w->left->color == BLACK) {
				w->left->color = BLACK;
				w->color = RED;
				left_rotate(tree, w);
				w = x->parent->left;
			} else {
				w->color = x->parent->color;
				x->parent->color = BLACK;
				right_rotate(tree, x->parent);
				x = tree->root;
			}
		}
	}
	x->color = BLACK;
}
~~~

下图中给出了代码中的 4 种情况.

![](/content/images/2015/04/delete-fixup.png)

###情况1

`x` 的兄弟结点 `w` 是红色的.

~~~
w->color = BLACK;
x->parent->color = RED;
left_rotate(tree, x->parent);
w = x->parent->right;
~~~

###情况2

`x` 的兄弟结点 `w` 是黑色的, 而且 `w` 的两个子节点都是黑色的.

~~~
w->color = RED;
x = x->parent;
~~~

###情况3

`x` 的兄弟结点 `w` 是黑色的, `w` 的左子结点是红色的, 右子结点是黑色的.

~~~
w->left->color = BLACK;
w->color = RED;
right_rotate(tree, w);
w = x->parent->right;
~~~

###情况4

`x` 的兄弟结点 `w` 是黑色的, `w` 右子结点是红色的.

~~~
w->color = x->parent->color;
x->parent->color = BLACK;
w->right->color = BLACK;
left_rotate(tree, x->parent);
x = tree->root;
~~~

###分析

`red_black_delete` 的运行时间如何呢, 因为含有 $n$ 的结点的红黑树的高度为 $O(\lg n)$, 不调用 `red_black_delete_fixup` 的总时间代价为 $O(\lg n)$, 在 `red_black_delete_fixup` 中, 情况 1 3 4 中, 最多执行常熟次数的颜色改变, 并且最多 3 次旋转之后便停止, 情况 2 中是可以多次执行的, 但是指针沿树最多上升 $O(\lg n)$ 次, 且不执行任何旋转. 所以 `red_black_delete` 的运行时间最多为 $O(\lg n)$.
