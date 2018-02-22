---
layout: post
title: 线性时间排序
date: 2015-03-26 00:20:40.000000000 +08:00
permalink: /:title
---


我们把在排序的最终结果中, 各元素的次序依赖于它们的比较的排序算法称为**比较排序**. 而我们在这里介绍的排序将不依赖于元素之间的比较.

第一次听到这种说法感觉非常的神奇和震惊, 而在以前的认识中, 排序都是基于比较的. 不经过比较怎么排序, 而这一章线性时间排序就改变了我过去对排序的浅显的认识.

#比较排序算法的下届

我们如何才能使排序的时间复杂度达到线性呢, 能否通过元素之间的比较产生一种排序时间复杂度为线性的算法呢.

结论是: 不可能, 比较排序算法最坏情况下的时间复杂度的下届为 $\Theta\left(n\lg n\right)$. 这是为什么呢, 我们可以用[决策树](http://zh.wikipedia.org/wiki/%E5%86%B3%E7%AD%96%E6%A0%91)模型来证明下届的正确性.

考虑一棵高度为 $h$, 具有 $l$ 个可达的叶结点的决策树, 它对应一个对 $n$ 个元素所做的比较排序, 因为输入数据的 $n!$ 种可能的排列都是叶结点, 并且叶的数目不多于 ${2}^{n}$, 所以, 我们得到:

$$n! \leq l \leq {2}^{n}$$

对该式两边取对数:


$$\begin{align}
	h \geq \lg(n!) = \Omega(n\lg n)
   \end{align}$$
   
所以我们可以观察到堆排序和快速排序都是渐近最优的排序算法, 上届为 $O(n \lg n)$.

#计数排序(Counting-Sort)

**计数排序**假设 $n$ 个输入元素中的每一个都是在 $0$ 到 $k$ 区间的一个整数. 当 $k=O(n)$ 时, 排序的运行时间为 $\Theta(n)$.

计数排序的基本思想是, 对于每一个输入元素 $x$, 确定小于 $x$ 的元素个数 $n$, 然后把元素 $x$ 直接放到第 $n+1$ 的位置.

我们使用如下代码实现计数排序.

~~~
void counting_sort(int A[], int B[], int k) {
    int C[k+1];
    
    for (int i = 0; i <= k; i++) {
        C[i] = 0;
    }

    for (int j = 0; j < length(A); j++) { C[A[j]]++; }
    for (int i = 1; i <= k; i++) { C[i] += C[i-1]; }
    
    for (int j = length(A) - 1; j >= 0; j--) {
        B[C[A[j]]] = A[j];
        C[A[j]]--;
    }
}
~~~

在这段代码中, `A[]` 为输入数组, `B[]` 为输出数组, `C[]`提供临时存储空间, 下面我们来分析这段代码.

~~~
for (int i = 0; i <= k; i++) {
    C[i] = 0;
}
~~~

这段代码运行过后, 数组 `C[]` 中的所有元素都被初始化为 `0`, $T(n)=\Theta(k)$

~~~
for (int j = 0; j < length(A); j++) { C[A[j]]++; }
~~~

循环的过程中, `A[]` 数组中的每一个元素都会使 `C[]` 数组中的对应元素 `+1`. 循环结束后, `C[]` 数组中的元素为, 对应索引出现在 `A[]` 数组中的次数, $T(n)=\Theta(n)$

~~~
for (int i = 1; i <= k; i++) { C[i] += C[i-1]; }
~~~

通过累加, 计算确定对每一个 $i=0, 1, ..., k$, 有多少元素是小于或等于 $i$ 的, $T(n)=\Theta(k)$

~~~
for (int j = length(A) - 1; j >= 0; j--) {
    B[C[A[j]]] = A[j];
    C[A[j]]--;
}
~~~

最后这段代码把 `A[]` 中的元素, 通过 `C[]` 中的索引放到恰当的位置,, $T(n)=\Theta(n)$

所以总的时间代价就是 $T(n)=\Theta(n+k)$, 当 $k=O(n)$ 时, 我们一般会使用计数排序, 这样的运行时间为 $\Theta(n)$.

计数排序的另一个重要性质就是它是稳定的, 具有相同值的元素在输出数组中的相对顺序不变, 而这点的主要原因就是

~~~
for (int j = length(A) - 1; j >= 0; j--)
~~~

如果把这段代码换成

~~~
for (int j = 0; j < length(A); j++)
~~~

那么计数排序就是不稳定的.

#基数排序(Radix-Sort)

我们了解了计数排序之后, 接下来介绍另一种排序方法, **基数排序**.

基数排序是将整数按位数切割成不同的数字, 然后按照每个位数进行比较.

<img src="http://deltax.qiniudn.com/radix-sort.png?attname=&e=1427369778&token=YJb_IPQrTSw1ox9LenQDH1HRcgHii9w_bp9ddmcz:d-0v6wSh1j09MH_agrIH_Q0DrN0" style="display:block;margin:auto"/>

为了保证基数排序的准确性, **一位数排序算法必须是稳定的**.

基数排序的实现如下

~~~
void radix_sort(int A[], int d) {
	for (int i = 0; i < d; i++) {
		Use a stable sort to sort array A on digit i
	}
}
~~~

如果使用计数排序与基数排序结合, 那么就可以在 $\Theta(d(n+k))$ 时间内排好序.


#桶排序(Bucket-Sort)

**桶排序**假设输入数据服从均匀分布, 平均情况下它的时间代价为 $O(n)$.


<img src="http://deltax.qiniudn.com/bucket-sort.png?attname=&e=1427371034&token=YJb_IPQrTSw1ox9LenQDH1HRcgHii9w_bp9ddmcz:D0HE4QlDxJZ455IPQX7uhNNJ_aA" style="display:block;margin:auto"/>

假设输入数据分布在 $[0..1)$ 区间中, 我们需要一个临时数组 `B[0..n-1]` 来存放链表. 我们接下来将实现桶排序.

~~~
void bucket_sort(int A[]) {
    int n = length(A);
    int B[n];

    
    for (int i = 0; i < n; i++) {
        B[i] = 0;
    }

    
    for (int i = 0; i < n; i++) {
        append(B[int(n * A[i])], A[i]);
    }

    for (int i = 0; i < n; i++) {
        insertion_sort(B[i]);
    } 

    int j = 0;
    for (int i = 0; i < n; i++) {
        while (B[i].head) {
            A[j] = B[i].head;
            delete(B[i]);
            j++;
        }
    }
}
~~~

因为插入排序的时间代价是 $\Theta(n^2)$, 所以桶排序的时间代价为:


$$T(n) = \Theta(n) + \sum\_{i=0}^{n-1}{O({n}\_{i}^2)}$$


其中 ${n}_{i}$ 表示桶 `B[i]` 中元素个数的随机变量.

桶排序可以在线性时间内完成, 只要所有桶的大小平方和与总元素数呈线性关系.

