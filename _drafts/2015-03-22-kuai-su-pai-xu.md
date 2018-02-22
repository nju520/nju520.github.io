---
layout: post
title: 快速排序
date: 2015-03-22 21:06:38.000000000 +08:00
permalink: /:title
---


[快速排序](http://zh.wikipedia.org/wiki/%E5%BF%AB%E9%80%9F%E6%8E%92%E5%BA%8F)使用分治法策略把一个数组分成两个子数组, 并对两个子数组递归排序.

快速排序的分治过程有三步:

* 分解
	* 数组 `A[p..r]` 被分解为两个可能为空的子数组 `A[p..q-1]` 和 `A[q+1..r]`, 使 `A[p..q-1]` 中的所有元素都小于或等于 `A[q]`, `A[q+1..r]` 中的所有元素都大于或等于 `A[q]`.
* 解决
	* 地柜地调用快速排序, 对子数组 `A[p..q-1]` 和 `A[q+1..r]` 进行排序.
* 合并
	* 不需要合并操作, 数组 `A[p..r]` 已经有序.
	
##快速排序的实现

~~~
void quicksort(int A[], int p, int r) {
	if (p < r - 1) {
		int q = partition(A, p, r);
		quicksort(A, p, q - 1);
		quicksort(A, q + 1, r);
	}
}
~~~

为了排序一个数组, 我们需要调用 `quicksort(A, 0, A.length - 1)

##数组的划分(partition)

快速排序最关键的部分就是数组的划分, 也就是过程 `partition`, 它实现了对数组的重新排序.

~~~
#define EXCHANGE(a, b) tmp = a; a = b; b = tmp;

int partition(int A[], int p, int r) {
	int x = A[r],
		 i = p - 1;
		
	for (int j = p; j < r; j++) {
		if (A[j] <= x) {
			i++;
			EXCHANGE(A[i], A[j]);
		}
	}
	EXCHANGE(A[r], A[i + 1]);
	return i + 1;
}
~~~
	
每一轮迭代开始时, 对于任意数组下标 `k`, 有:

1. `p <= k <= i, A[k] <= x`
2. `i + 1 <= k <= j - 1, A[k] > x`
3. `k = r, A[k] = x`

##性能

快速排序的性能依赖于数组是否被平衡的划分, 如果平衡, 那么快速排序的划分是**平衡**的. 那么快速排序的性能与归并排序相同, 否则, 划分是**不平衡**的, 快速排序的性能就接近于插入排序.

###最坏情况下的性能

当快速排序在最坏情况下时, 我们获得一个递归式:

> T(n) = T(n-1) + Θ(n)

得到最坏情况下的时间复杂度仍然为 `Θ(n^2)`, 而插入排序在最坏情况下时间复杂度也为 `Θ(n^2)`, 而在几乎有序的情况下快速排序的时间复杂度也为 `Θ(n^2)`, 插入排序则为 `Θ(n)`.

###最好情况下性能

在最好的情况下, 每次划分都是平均的, 递归式为:

> T(n) = 2T(n/2) + Θ(n)

最好的情况下的时间复杂度为 `Θ(nlgn)`, 我们得到了一个渐进时间最快的算法.

###平衡的划分

假设划分算法总是产生 9:1 的划分, 那么递归式为:

>  T(n) = T(n/10) + T(9n/10) + cn

我们在这里求得快速排序的总时间代价依然为 `Ο(nlgn)`, 由此可以发现, 任何一种**常数**比例的划分都会产生时间复杂度为 `Ο(nlgn)` 的算法.

###随机版本的快速排序

因为快速排序的时间复杂度取决于数组的划分, 有时, 我们希望引入随机性来改善算法的性能. 在这里我们可以采用一种随机抽样的方式选择数组的主元, 达到随机的目的.

~~~
int randomized_partition(int A[], int p, int r) {
	int i = i = rand() % (r - p) + p;
	EXCHANGE(A[r], A[i])	;
	return partition(A, p, r);
}

int randomized_quicksort(int A[], int p, int r) {
	if (p < r - 1) {
		int q = randomized_partition(A, p, r);
		randomized_quicksort(A, p, q - 1);
		randomized_quicksort(A, q + 1, r);
	}
}
~~~
	
我们只需要在调用 `partition` 之前随机选择一个 pivot 然后与 `A[r]` 交换即可.

###Hoare版本的快速排序

我们在之前使用的 `partition` 并不是快速排序算法最初的版本, 下面给出的是快速排序最初的版本.

~~~
int hoare_partition(int A[], int p, int r) {
	int x = A[p],
		 i = p - 1,
		 j = r + 1;
	while (true) {
		do { j--; } while (!(A[i] <= x));
		do { i++; } while (!(A[j] >= x));
		if (i < j) {
			EXCHANGE(A[i], A[j]);
		} else {
			return k;
		}
	}
}

int hoare_quicksort(int A[], int p, int r) {
	if (p < r - 1) {
		int q = hoare_partition(A, p, r);
		hoare_quicksort(A, p, q - 1);
		hoare_quicksort(A, q + 1, r);
	}
}
~~~
	
###针对相同元素的快速排序

~~~
typedef struct {
    int q;
    int t;
} pivot_t;

pivot_t partition(int A[], int p, int r) {
    int x = A[r - 1],
        q = p,
        t,
        tmp;

    for (int i = p; i < r - 1; i++) {
        if (A[i] < x) {
            EXCHANGE(A[q], A[i]);
            q++;
        }
    }

    for (t = q; t < r && A[t] == x; t++);

    for (int i = r - 1; i >= t; i--) {
        if (A[i] == x) {
            EXCHANGE(A[t], A[i]);
            t++;
        }
    }

    pivot_t result = {q, t};
    return result;
}
~~~

`partition` 过程在这一版本中, 返回 `q` 和 `t`, 使得 

* `A[p..q-1]` 中的每个元素都小于 `A[q]`.
* `A[q..t]` 中的每个元素都等于 `A[q]`.
* `A[t+1..r]` 中的每个元素都大于 `A[q]`.
