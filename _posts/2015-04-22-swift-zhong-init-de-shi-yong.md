---
layout: post
toc: true
title: Swift 类构造器的使用
date: 2015-04-22 20:21:15.000000000 +08:00
permalink: /:title
tags: iOS
---


这几天在使用 Swift 重写原来的一个运动社交应用 SportJoin.

为什么要重写呢? 首先因为实在找不到设计师给我作图; 其次, ~~原来写的代码太烂了~~我也闲不下来, 想找一些项目做, 所以只好将原来的代码重写了.

原来的代码大约是一年半以前写的, 我现在真的不想吐槽当时写的代码有多烂, 有一句话怎么说来着:

> ~~程序员连自己写的源代码都不想读, 怎么可能看别人写的源代码!~~ 每半年获得的知识相当于之前获得的全部知识的总和.

个人觉得这句话还是蛮有道理的. 反正对于我来说, 每过一段的时间回过头来看自己写的代码都感觉有很大的重构空间, 很多地方写的不够 **PERFECT**, 虽然我不是一个**处女座**, 但是对于代码的健壮和整洁还是很注意的.

接下来, 我来~~扯一扯~~谈一谈最近写 Swift 遇到的那些~~坑~~问题吧.

## 感受

首先说下 Swift 给我带来的感受吧, Swift 的刚开始使用的时候感觉还是~~太特么难用了~~可以的.

不过 Xcode 在 Swift 上的**补全极其慢**, 因为 Swift 所有的属性方法都是**默认公开**的, 所以可能是因为每次都要搜索全局的符号导致自动补全非常缓慢, 严重影响了工作效率, 有同样的问题的请戳[这里](http://stackoverflow.com/questions/25948024/xcode-6-with-swift-super-slow-typing-and-autocompletion). 当然也不排除我电脑配置的影响, 不过重写的过程还是蛮顺利的, 没有遇到太多的问题, 而且使用了很多 Swift 的高级特性来缩减原来冗长的 ObjC 代码.

## 构造器 init

~~好了~~然后, 谈一下我在这两天中写 Swift 时遇到的最大问题 ---- 构造器 `init` 的使用.

注: 我们在这篇博客中提到的构造器都为**类构造器**, 在这里不提及值构造器的使用，详见文档.

刚刚使用这个构造器的时候我感觉到很困惑啊, 不就是个 `init`, 你给我搞这么多事情干什么? ~~我只想安安静静地初始化~~

### 开始使用 init

当我遵从以前写 ObjC 的习惯, 在 Swift 中键入 `init` 之后, 编译器提醒我:

![](/content/images/2015/04/6D760453-E328-4CA6-BAD8-04DA1831E3E5.png)

~~~
'required' initialize 'init(coder:)' must be provided by subclass of 'UITableViewCell'
~~~

这是什么意思(,,#ﾟДﾟ), 好吧, 这个错误竟然可以点. 于是开心地双击, 然后呢, Xcode 在我们的屏幕中自动生成了这些东西:


~~~swift
required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
}
~~~

随后, 我就如在 ObjC 中一样在 `init` 方法中调用了 `super.init()`, (/= _ =)/~┴┴  怎么还有错误?

![](/content/images/2015/04/D441FBD5-CB3C-4034-AD7E-2B32A9753ADF.png)

这是啥意思?

~~~
Must call a designated initializer of the superclass 'UITableViewCell'
~~~

必须调用一个 `UITableViewCell` 的指定构造器. 算了先不管了, 继续写好了. 于是又出现呢了下面的提示:

![](/content/images/2015/04/8381E08C-BA7B-4E4B-8363-6358EEAE8C5F.png)

~~~
Convenience initializer for 'TableViewCell' must delegate (with 'self.init') rather than chaining to a superclass initializer (with 'super.init')
~~~

既然说 convenience 构造器不能调用 `super.init`, 那么按照错误提示改成 `self.init` 应该就好了.

![](/content/images/2015/04/650D9072-EF4A-49BB-BB4E-018759813171.png)

~~~
Could not find member 'Default'
~~~

既然报了这个错误, 那么如果加上 `UITableViewCellStyle` 呢

![](/content/images/2015/04/F48408EA-ABC6-4F67-A2BC-E593EFB728FE.png)

~~~
Could not fond an overload for 'init' that accepts the supplied arguments
~~~

找不到 init 方法接收所提供参数的重载.

最后一个常见的错误大概是这样的

![](/content/images/2015/04/4D7B47B7-D87E-4F7B-BDE2-125EF89B90CE.png)

~~~
Property 'self.label' not initialized at super.init call
~~~

Orz, 到这里我已经放弃了自己通过尝试来解决这些问题了. 于是我求助于 Google, 最后怒看苹果的官网文档并找到了以上错误的全部答案.

### 使用 init 方法的正确姿势

苹果的官方文档关于构造器的部分请戳[这里](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Initialization.html)

在 Swift 中, 类的初始化有两种方式, 分别是

1. Designated Initializer
2. Convenience Initializer

Designated Initializer 在本篇博客中译为指定构造器, 而 Convenience Initializer 译为便利构造器.

**指定构造器在一个类中必须至少有一个**, 而便利构造器的数量没有限制.

#### 指定构造器(Designated Initializer)

> Designated initializers are the primary initializers for a class. A designated initializer fully initializes all properties introduced by that class and calls an appropriate superclass initializer to continue the initialization process up the superclass chain.

**指定构造器是类的主要构造器, 要在指定构造器中初始化所有的属性, 并且要在调用父类合适的指定构造器.**

每个类应该只有少量的指定构造器, 大多数类只有**一个**指定构造器, 我们使用 Swift 做 iOS 开发时就会用到很多 UIKit 框架类的指定构造器, 比如说:

~~~swift
init()
init(frame: CGRect)
init(style: UITableViewCellStyle, reuseIdentifier: String?)
~~~

这些都是类指定构造器, 并且这些方法的前面是没有任何的关键字的(包括 `override`).

当定义一个指定构造器的时候, 必须调用父类的某一个指定构造器:

~~~swift
init(imageName: String, prompt: String = "") {
	super.init(style: .Default, reuseIdentifier: nil)
	...
}
~~~

在这里我们的指定构造器调用了父类的指定构造器 `super.init(style: .Default, reuseIdentifier: nil)`.

#### 便利构造器(Convenience Initializer)

> Convenience initializers are secondary, supporting initializers for a class. You can define a convenience initializer to call a designated initializer from the same class as the convenience initializer with some of the designated initializer’s parameters set to default values. You can also define a convenience initializer to create an instance of that class for a specific use case or input value type.


**便利构造器是类的次要构造器, 你需要让便利构造器调用同一个类中的指定构造器, 并将这个指定构造器中的参数填上你想要的默认参数.**

如果你的类不需要便利构造器的话, 那么你就不必定义便利构造器, 便利构造器前面必须加上 `convenience` 关键字.

在这里我们就不举例了, 但是我们要提一下便利构造器的语法:

~~~swift
convenience init(parameters) {
    statements
}
~~~

### init 规则

定义 init 方法必须遵循三条规则

1. **指定构造器必须调用它直接父类的指定构造器方法.**
2. **便利构造器必须调用同一个类中定义的其它初始化方法.**
3. **便利构造器在最后必须调用一个指定构造器.**

如下图所示:

![](/content/images/2015/04/initializerDelegation02_2x.png)

在图中, 只有指定构造器才可以调用父类的指定构造器, 而便利构造器是不可以的, 这也遵循了我们之前所说的三条规则.

只要 init 方法遵循这三个规则就不会有任何问题.

* 不过为什么要遵循这三条规则呢?
* `init` 的方法的调用机制是什么呢?

### init 机制

在 Swift 中一个实例的初始化是分为两个阶段的

1. 第一阶段是实例的所有属性被初始化.
2. 第二阶段是实例的所有属性可以再次的调整以备之后的使用.

而这与 ObjC 的区别主要在于第一部分, 因为在 ObjC 中所有的属性如果不赋值都会默认被初始化为 `nil` 或者 `0`. 而在 Swift 中可以所有属性的值由开发者来指定.

Swift 的编译器会对初始化的方法进行安全地检查已保证实例的初始化可以被**安全正确**的执行:

1. **指定构造器必须要确保所有被类中提到的属性在代理向上调用父类的指定构造器前被初始化, 之后才能将其它构造任务代理给父类中的构造器.**
2. **指定构造器必须先向上代理调用父类中的构造器, 然后才能为任意属性赋值.**
3. **便利构造器必须先代理调用同一个类中的其他构造器, 然后再为属性赋值.**
4. **构造器在第一阶段构造完成之前, 不能调用任何实例方法, 不能读取任何实例属性的值，`self` 不能被引用.**

接下来我们来说明一下类构造的两个阶段:

#### 阶段 1

* 某个指定构造器或便利构造器被调用.
* 完成新的实例内存的分配, 但此时内存还没有被初始化.
* 指定构造器确保其所在类引入的**所有存储型属性**都已赋值. 存储型属性所属的内存完成初始化.
* 指定构造器将调用父类的构造器, 完成父类属性的初始化.
* 这个调用父类构造器的过程**沿着构造器链一直往上执行**, 直到到达构造器链的最顶部.
* 当到达了构造器链最顶部, 且已**确保所有实例包含的存储型属性都已经赋值**，这个实例的内存被认为已经完全初始化。此时 `阶段 1` 完成.

![](/content/images/2015/04/twoPhaseInitialization01_2x.png)

1. 子类的便利构造器首先会被调用, 这时便利构造器无法修改子类的任何属性.
2. 便利构造器会调用子类中的指定构造器, 指定构造器(子类)要确保所有的属性都已赋值, 完成所属内存的初始化,
3. 接着会指定构造器(子类)会调用父类中的指定构造器, 完成父类属性所属内存的初始化, 直到达到构造器链的最顶部. 所有的属性以及内存被完全初始化, 然后进入第 `阶段 2`.

#### 阶段 2

* 从顶部构造器链一直向下, 每个构造器链中类的指定构造器都有机会进一步定制实例. 构造器此时可以访问 `self`, 修改它的属性并调用实例方法等等。
* 最终, 任意构造器链中的便利构造器可以有机会定制实例和使用 `self`

![](/content/images/2015/04/twoPhaseInitialization02_2x.png)

1. 父类中的指定构造器定制实例的属性(可能).
2. 子类中的指定构造器定制实例的属性.
3. 子类中的便利构造器定制实例的属性.


### init 的继承和重载

> Unlike subclasses in Objective-C, Swift subclasses do not inherit their superclass initializers by default. Swift’s approach prevents a situation in which a simple initializer from a superclass is inherited by a more specialized subclass and is used to create a new instance of the subclass that is not fully or correctly initialized.

跟 ObjC 不同, Swift 中的**子类默认不会继承来自父类的所有构造器**. 这样可以**防止错误的继承并使用父类的构造器生成错误的实例**(可能导致子类中的属性没有被赋值而正确初始化). 与方法不同的一点是, 在重载构造器的时候, 你不需要添加 `override` 关键字.

虽然子类不会默认继承来自父类的构造器, 但是我们也可以通过别的方法来自动继承来自父类的构造器, 构造器的继承就遵循以下的规则:

1. **如果子类没有定义任何的指定构造器, 那么会默认继承所有来自父类的指定构造器.**
2. **如果子类提供了所有父类指定构造器的实现, 不管是通过 `规则 1` 继承过来的, 还是通过自定义实现的, 它将自动继承所有父类的便利构造器.**

## 错误分析

我们到目前为止已经基本介绍了所有的构造器使用的注意事项, 接下来我们分析一下最开始错误的原因.

### 错误 1

第一个错误是因为, 我们一开始虽然没有为指定构造器提供实现, 不过, 因为重载了指定构造器, 所以来自父类的指定构造器并不会被继承.

> 如果子类没有定义任何的指定构造器, 那么会默认继承所有来自父类的指定构造器.

而 `init(coder aDecoder: NSCoder)` 方法是来自父类的指定构造器, 因为这个构造器是 `required`, 必须要实现. 但是因为我们已经重载了 `init()`, 定义了一个指定构造器, 所以这个方法不会被继承, 要手动覆写, 这就是第一个错误的原因.

### 错误 2

~~~swift
class TableViewCell: UITableViewCell {

    init() {

    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
~~~

我们已经手动覆写了这个方法, 然后, 因为 `init()` 方法虽然被重载了, 但是并没有调用父类的指定构造器:

> 指定构造器必须调用它最近父类的指定构造器.

所以我们让这个指定构造器调用 `super.init(style: UITableViewCellStyle, reuseIdentifier: String?)`, 解决了这个问题.

~~~swift
class TableViewCell: UITableViewCell {

    init() {
        super.init(style: .Default, reuseIdentifier: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
~~~

### 错误 3

~~~swift
class TableViewCell: UITableViewCell {

    convenience init() {
        super.init(style: .Default, reuseIdentifier: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
~~~

`错误 3` 跟前面的两个错误没有直接的联系. 这里的构造器是一个便利构造器(注意前面的 `convenience` 关键字), 而这里的错误违反了这一条规则:

> 便利构造器必须调用同一个类中定义的其它构造器(指定或便利).

所以我们让这个便利构造器调用同一个类的 `self.init(style: UITableViewCellStyle, reuseIdentifier: String?)` 的指定构造器.

~~~swift
class TableViewCell: UITableViewCell {

    convenience init() {
        self.init(style: .Default, reuseIdentifier: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
~~~

而这段代码目前还是有问题的, 而这就是 `错误 4` 的代码.

### 错误 4

`错误 4` 的主要原因就是重载了父类的 `init(coder aDecoder: NSCoder)` 指定构造器, 导致父类的指定构造器 `init(style: .Default, reuseIdentifier: nil)` 并没有被当前类 `TableViewCell` 继承, 所以当前类中是没有 `init(style: .Default, reuseIdentifier: nil)` 指定构造器.

> 如果子类没有定义任何的指定构造器, 那么会默认继承所有来自父类的指定构造器.

~~~swift
class TableViewCell: UITableViewCell {

    convenience init() {
        self.init(style: .Default, reuseIdentifier: nil)
    }
}
~~~

只需要删掉这个 `init(coder aDecoder: NSCoder)` 方法就可以解决这个错误了.

### 错误 5

~~~swift
class TableViewCell: UITableViewCell {

    let label : UILabel

    init(imageName: String) {
        super.init(style: .Default, reuseIdentifier: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
~~~

`错误 5` 的主要原因是违反了这一条规则, 它在调用 `super.init(style: .Default, reuseIdentifier: nil)` 之前并没有初始化自己的所有属性.

> 指定构造器必须要确保所有被类中提到的属性在代理向上调用父类的指定构造器前被初始化, 之后才能将其它构造任务代理给父类中的构造器.

因为 `label` 属性不是 `optional` 的, 所以这个属性就必须初始化.

~~~swift
init(imageName: String) {
    self.label = UILabel()
    super.init(style: .Default, reuseIdentifier: nil)
}
~~~

这是第一个解决的办法, 不过我一般使用另一种, 在属性定义的时候就为他说初始化一个值.

~~~swift
class TableViewCell: UITableViewCell {

    let label = UILabel()

    init(imageName: String) {
        super.init(style: .Default, reuseIdentifier: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
~~~

这些就是我在使用 swift 的构造其中遇到的全部错误了.

## 总结

Swift 中构造器需要遵循的规则还是很多的, 总结一下, 有以下规则:

* 调用相关
    * 指定构造器必须调用它直接父类的指定构造器方法.
    * 便利构造器必须调用同一个类中定义的其它初始化方法.
    * 便利构造器在最后必须调用一个指定构造器.
* 属性相关
    * 指定构造器必须要确保所有被类中提到的属性在代理向上调用父类的指定构造器前被初始化, 之后才能将其它构造任务代理给父类中的构造器.
    * 指定构造器必须先向上代理调用父类中的构造器, 然后才能为任意属性赋值.
    * 便利构造器必须先代理调用同一个类中的其他构造器, 然后再为属性赋值.
    * 构造器在第一阶段构造完成之前, 不能调用任何实例方法, 不能读取任何实例属性的值，`self` 不能被引用.
* 继承相关
    * 如果子类没有定义任何的指定构造器, 那么会默认继承所有来自父类的指定构造器.
    * 如果子类提供了所有父类指定构造器的实现, 不管是通过上一条规则继承过来的, 还是通过自定义实现的, 它将自动继承所有父类的便利构造器.


Swift 中的构造器 `init` 中坑还是很多的, 而目前我也终于把这个构造器这个坑填上了, 最终决定还是要重新**详细**看一遍 Swift 的[官方文档](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/index.html#//apple_ref/doc/uid/TP40014097-CH3-ID0), 而整篇博客和问题的解决都是基于官方文档的. 使用下来 Swift 比 Objective-C 语言使用起来的注意事项和坑更多, 也有很多的黑魔法, 等待着我们去开发和探索.
