---
layout: post
title: iOS Combine View and TableView <Bug01>
date: 2014-11-24 07:26:11.000000000 +08:00
permalink: /:title
---
我在开发我的第一个项目`SportJoin`的过程中遇到过这样一个问题, 需要写出一个同时有`UIView`和`UITablView`的界面, 这个为什么很困难呢. 

1. 需要写出易于维护的结构.
2. 需要在`tableView`滚动的时候滚动.
3. 需要在`headerView`到达顶部的时候`segmentControl`停在视图的顶部.

我在第一次遇到这种问题的时候, 想到的第一种解决办法就是在第一个`UITableViewCell`里面加入`headerView`, 但是这样却导致了另一个问题, 所有在`dataSource`方法和一些`delegate`方法中的一些`count`都需要`+1`, 我认为这一点相当的不优雅, 而随着需求的更改, 这种结构也被抛弃了, 所以我开始选择另一种方式解决这个问题. 经过了无数的实验与摸索, 选择了下图的这种方式达到我想要的效果.

![](/content/images/2015/04/iOSIMG_0297.PNG)


但是...经过我们团队成员多次测试, 竟然发现了这样的`bug`... `tableView`和`headerView`之间有`20 offset`. 而且当下拉刷新动画被打断的时候, 比如点击其他的`tabBarItem`. `offset`会越来越大.

![](/content/images/2015/04/iOSIMG_0296.PNG)

设计师第一次发现这个`bug`告诉我之后, 我立刻感觉到这个高度`20`应该跟`status bar`有关, 找了所有与`status bar`以及这个视图有关的代码, 并且上`google`搜索了无数次, 都没有发现这是因为什么. 

后来由于团队缺少运营, 参加完比赛, 项目不了了之, 这个`bug`我也没有再去改了. 不过这个`bug`一直我都记得非常的清楚, 实在是让我头痛不已.

现在先解释一下这个界面是如何完成的, 简单说一下这个界面的根控制器是一个`UIViewController`, 它的`view`上面只有一个子视图`tableView`, 注意只有**一个**子视图, 而这个子视图包含了我们在这个界面中看到的`headerView`, 也就是顶部的个人信息.

界面的层级如下:
	
		-----------------
		|      view     |
		-----------------
		        ^
		        |
		        |
		-----------------
		|   tableView   |
		-----------------
		        ^
		        |
		        |
		-----------------
		|   headerView  |
		-----------------

`headerView` 是 `tableView`的子视图, 但是为什么会这么显示呢, 有这么几个原因.

1. 在视图加载时, 我通过调整`tableView`的`contentInset`使`tableView`在初始化时向下偏移`headerView`的高度, 目的呢, 就是将`cell`开始显示的位置设置到目标的区域.

	~~~
  	tableView.contentInset = UIEdgeInsetsMake(HEADER_HEIGHT, 0, 0, 0);
	~~~

2. 然后呢, 将`headerView`初始化, 并添加到`tableView`上面, 这里呢, 有一点需要注意的就是`headerView.frame.origin.y`是小于`0`的. 这是为什么呢, 是因为我们上一步将`tableView`内容开是显示的`height`设置为`295`, 那么我们需要将`headerView`初始化到`tableView`的"外面"

	~~~
	// 使用CGRect的情况下, 使用AutoLayout可以类比一下
	headerView.frame = CGRectMake (0, -HEADER_HEIGHT, WIDTH_SCREEN, HEADER_HEIGHT);
	~~~

3. 这样我们就完成了这个界面的显示, 但是, 当我们向这个`headerView`中添加按钮的时候, 却发现, 这个按钮的`action`没有触发, 因为`headerView`是`tableView`的`subview`并且在它的外部, 所以, 我们需要设置`clipsToBound`属性, 防止`tableView`拦截这个实践.

	~~~
	tableView.clipsToBound = NO;
	~~~
4. 接下来我们要实现让界面的一部分停在屏幕上, 只需要调用`UIScrollView`的`delegate`方法, 注意设置适当的条件就可以.

	~~~
	- (void)scrollViewDidScroll:(UIScrollView *)scrollView
	{
	    static CGFloat headerHeight = 60;
	    if (scrollView.contentOffset.y >= -60)
	        [self.headerView setFrame:CGRectMake(0, scrollView.contentOffset.y - (HEADER_HEIGHT - headerHeight), WIDTH_SCREEN, HEADER_HEIGHT)];
	    if (scrollView.contentOffset.y <= -HEADER_HEIGHT)
	        [self.headerView setFrame:CGRectMake(0, scrollView.contentOffset.y, WIDTH_SCREEN, HEADER_HEIGHT)];
	}
	~~~

	
	
卧槽, 终于搞定了, 我特么太爽了, 然而.........就是上面的`bug`让我头疼了好久...

直到今天, 我在新项目中又遇到了这个问题, 无论我怎么更改布局, 使用`CGRect`, `AutoLayout`都没能解决, 因为代码量较小, 经过多次调试, 认为这次绝对另有原因, 我机智的上`Google`搜索了如下关键字`contentInset` `20` `iOS`, 结果, 这回果然发现了问题所在, 在`stackoverflow`上面找到了这个问题的答案, 原来`automaticallyAdjustsScrollViewInsets`才是导致问题的罪魁祸首, 而之前我完全没有接触过这个属性. 在苹果官方文档中是这样描述的.

>  If you don’t want a scroll view’s content insets to be automatically adjusted, set automaticallyAdjustsScrollViewInsets to NO. (The default value of automaticallyAdjustsScrollViewInsets is YES.)

在设置了`tableViewController`之后, 仍然没有起到任何作用.

~~~
self.automaticallyAdjustsScrollViewInsets = NO;
~~~

经过仔细寻找其他答案后, 找到了这样一条答案

> Your view controller must be directly on a `UINavigaitonController`'s stack for `automaticallyAdjustsScrollViewInsets` to work (i.e. not a child view controller)

> If it is a child view controller of another view controller which is on the navigation stack, you can instead set `automaticallyAdjustsScrollViewInsets = NO` on the parent. Alternatively you can do this:

>		self.parentViewController.automaticallyAdjustsScrollViewInsets = NO;

意思就是, 如果你的`viewController`直接在`UINavigationController`那么, 直接设置这个`viewController`的`automaticallyAdjustsScrollViewInsets`属性, 如果`viewController`是另一个`viewController`比如说`tabBarViewController`, 那么需要设置这个`viewController`的`parentViewController`的属性.

最后, 我在3个月后的今天, `fix`了这个`bug`, 实在是太难忘了.

5 . self.parentViewController.automaticallyAdjustsScrollViewInsets = NO;


----

最后总结一下:

1. `tableView.contentInset = UIEdgeInsetsMake(HEADER_HEIGHT, 0, 0, 0);`

2. `headerView.frame = CGRectMake (0, -HEADER_HEIGHT, WIDTH_SCREEN, HEADER_HEIGHT);`
		
3. `tableView.clipsToBound = NO;`

4. `scrollViewDidScroll`

5. `self.parentViewController.automaticallyAdjustsScrollViewInsets = NO;`

----

后来的后来...我发现了`tableView`的的另一个属性`tableHeaderView`, 只需要设置这个属性, 就可以把视图放在`tableView`的前面...真是蛋都碎了...

~~~
self.tableView.tableHeaderView = headerView;
~~~
	
......
