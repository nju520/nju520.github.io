---
layout: post
toc: true
title: Ruby 中的一些重要的钩子方法
permalink: /ruby-callback
tags: ruby callback

desc: Ruby的元编程能力能够让程序员编写在运行时动态生成的代码。它的线程功能使得程序员有一种优雅的的方式编写多线程代码。它的钩子方法能让程序员在程序运行时扩展它的行为。本文将探讨Ruby中的一些重要的钩子方法。我们将从不同方面讨论钩子方法，如它们是什么，它们用于什么，以及我们如何使用它们来解决不同的问题。我们同时也了解一下一些流行的Ruby框架/Gem包/库是如何使用它们来提供非常酷的特性的。
---

它的元编程能力能够让程序员编写在运行时动态生成的代码。它的线程功能使得程序员有一种优雅的的方式编写多线程代码。
它的钩子方法能让程序员在程序运行时扩展它的行为。

上述的这些特性，以及一些其他很酷的语言方面，使得Ruby成为编写代码的优先选择之一。
本文将探讨Ruby中的一些重要的钩子方法。我们将从不同方面讨论钩子方法，如它们是什么，它们用于什么，以及我们如何使用它们来解决不同的问题。
我们同时也了解一下一些流行的Ruby框架/Gem包/库是如何使用它们来提供非常酷的特性的。

## Ruby 中一些重要的钩子方法

### Ruby的哲学理念是基于一个基本的要素，那就是让程序员快乐。Ruby非常注重程序员的快乐，并且也提供了许多不同的方法来实现它。

我们开始吧。

什么是钩子方法？

钩子方法提供了一种方式用于在程序运行时扩展程序的行为。
假设有这样的功能，可以在无论何时一个子类继承了一些特定的父类时收到通知，
或者是比较优雅地处理一个对象上的不可调用的方法而不是让编译器抛出异常。
这些情况就是使用钩子方法，但是它们的用法并不仅限于此。
不同的框架/库使用了不同的钩子方法来实现它们的功能。

在本文中我们将会讨论如下几个钩子方法：

- included
- extended
- prepended
- inherited

- method_missing

#### included

Ruby给我们提供了一种方式使用 模块(modules) （在其他语言中被称作 混入类(mixins)）来编写模块化的代码供其他的 模块/类 使用。
模块 的概念很简单，它就是一个可以在其他地方使用的独立代码块。

例如，如果我们想要编写一些代码在任何时候调用特定的方法都会返回一个静态字符串。
我们姑且将这个方法称作 name。你可能在其他地方也会想使用同一块代码。
这样最好是新建一个模块。让我们来创建一个：

~~~ruby
module Person
  def name
    puts "My name is Person"
  end
end
~~~

这是一个非常简单的模块，仅有一个 name 方法用于返回一个静态字符串。在我们的程序中使用这个模块：

~~~ruby
class User
  include Person
end
~~~

Ruby提供了一些不同的方法来使用模块。include 是其中之一。include 所做的就是将在 module 内定义的方法在一个 class 的实例变量上可用。
在我们的例子中，是将 Person 模块中定义的方法变为一个 User 类实例对象的方法。
这就相当于我们是将 name 方法写在 User 类里一样，但是定义在 module 里的好处是可复用。
要调用 name 方法我们需要创建一个 User 的实例对象，然后再在这个对象上调用 name 方法。例如：
~~~ruby
User.new.name=> My name is Person
~~~
让我们看看基于 include 的钩子方法。included 是Ruby提供的一个钩子方法，当你在一些 module 或者 class 中 include 了一个 module 时它会被调用。
更新 Person 模块：

~~~ruby
module Person
  def self.included(base)
    puts "#{base} included #{self}"
  end

  def name
    "My name is Person"
  end
end
~~~

你可以看到一个新的方法 included 被定义为 Person 模块的类方法。当你在其他的模块或者类中执行 include Person 时，这个 included 方法会被调用。
该方法接收的一个参数是对包含该模块的类的引用。试试运行 User.new.name，你会看到如下的输出：

User included PersonMy name is Person

正如你所见，base 返回的是包含该模块的类名。现在我们有了一个包含 Person 模块的类的引用，我们可以通过元编程来实现我们想要的功能。
让我们来看看 Devise是如何使用 included 钩子的。

#### Devise中的 included

Devise是Ruby中使用最广泛的身份验证gem包之一。它主要是由我喜欢的程序员 José Valim 开发的，现在是由一些了不起的贡献者在维护。
Devise为我们提供了从注册到登录，从忘记密码到找回密码等等完善的功能。它可以让我们在用户模型中使用简单的语法来配置各种模块：

devise :database_authenticatable, :registerable, :validatable

在我们模型中使用的 devise 方法在这里定义。
为了方便我将这段代码粘贴在下面：

~~~ruby
def devise(*modules)
  options = modules.extract_options!.dup

  selected_modules = modules.map(&:to_sym).uniq.sort_by do |s|
    Devise::ALL.index(s) || -1  # follow Devise::ALL order
  end

  devise_modules_hook! do
    include Devise::Models::Authenticatable

    selected_modules.each do |m|
      mod = Devise::Models.const_get(m.to_s.classify)

      if mod.const_defined?("ClassMethods")
        class_mod = mod.const_get("ClassMethods")
        extend class_mod

        if class_mod.respond_to?(:available_configs)
          available_configs = class_mod.available_configs
          available_configs.each do |config|
            next unless options.key?(config)
            send(:"#{config}=", options.delete(config))
          end
        end
      end

      include mod
    end

    self.devise_modules |= selected_modules
    options.each { |key, value| send(:"#{key}=", value) }
  end
end
~~~

在我们的模型中传给 devise 方法的模块名将会作为一个数组保存在modules 中。
对于传入的模块调用 extract_options! 方法提取可能传入的选项。
在11行中调用 each 方法，并且每个模块在代码块中用 m 表示。
在12行中 m 将会转化为一个常量（类名），因此使用 m.to.classify 一个例如 :validatable 这样的符号会变为 Validatable 。
随便说一下 classify 是ActiveSupport的方法。

Devise::Models.const_get(m.to_classify) 会获取该模块的引用，并赋值给 mod。
在27行使用 include mod 包含该模块。
例子中的 Validatable 模块是定义在这里。
Validatable 的 included 钩子方法定义如下：

~~~ruby
def self.included(base)
  base.extend ClassMethods
  assert_validations_api!(base)

  base.class_eval do
    validates_presence_of  :email, if: :email_required?
    validates_uniqueness_of :email, allow_blank: true, if: :email_changed?
    validates_format_of    :email, with: email_regexp, allow_blank: true, if: :email_changed?

    validates_presence_of    :password, if: :password_required?
    validates_confirmation_of :password, if: :password_required?
    validates_length_of      :password, within: password_length, allow_blank: true
  end
end
~~~


此时模型是 base。在第5行的 class_eval 代码块会以该类作为上下文进行求值运算。
通过 class_eval 编写的代码与直接打开该类的文件将代码粘贴进去效果是一样的。
Devise是通过 class_eval 将验证包含到我们的用户模型中的。

当我们试着使用Devise注册或者登录时，我们会看到这些验证，但是我们并没有编写这些验证代码。
Devise是利用了 included 钩子来实现这些的。非常的优雅吧。

#### extended

Ruby也允许开发者 扩展(extend) 一个模块，这与 包含(include) 有点不同。
extend 是将定义在 模块(module) 内的方法应用为类的方法，而不是实例的方法。
让我们来看一个简单的例子：

~~~ruby
module Person
  def name
    "My name is Person"
  endend

class User
  extend Person
end

puts User.name # => My name is Person
~~~

正如你所看到的，我们将 Person 模块内定义的 name 方法作为了 User 的类方法调用。
extend 将 Person 模块内的方法添加到了 User 类中。extend 同样也可以用于将模块内的方法作为单例方法(singleton methods)。
让我们再来看另外一个例子：

~~~ruby
# We are using same Person module and User class from previous example.   

u1 = User.newu2 = User.new

u1.extend Person

puts u1.name # => My name is Personputs u2.name # => undefined method `name' for #<User:0x007fb8aaa2ab38> (NoMethodError)
~~~

我们创建了两个 User 的实例对象，并将 Person 作为参数在 u1 上调用 extend 方法。
使用这种调用方式，Person 的 name 方法仅对 u1 有效，对于其他实例是无效的。

正如 included 一样，与 extend 相对应的钩子方法是 extended。
当一个模块被其他模块或者类执行了 extend 操作时，该方法将会被调用。
让我们来看一个例子：

~~~ruby
# Modified version of Person module

module Person
  def self.extended(base)
    puts "#{base} extended #{self}"
  end

  def name
    "My name is Person"
  endend

class User
  extend Person
end
~~~

该代码的运行结果是输出 User extended Person。

关于 extended 的介绍已经完了，让我们来看看 ActiveRecord 是如何使用它的。

#### ActiveRecord中的 extended

ActiveRecord 是在 Ruby 以及 Rails 中广泛使用的ORM框架。它具有许多酷的特性，
因此使用它在很多情况下成为了ORM的首选。让我们进入 ActiveRecord 内部看看 ActiveRecord 是如何使用回调的。
(我们使用的是 Rails v3.2.21)

ActiveRecord 在这里 extend 了 ActiveRecord::Models 模块。

extend ActiveModel::Callbacks

ActiveModel 提供了一套在模型类中使用的接口。它们允许 ActionPack 与不是 ActiveRecord 的模型进行交互。
在这里， ActiveModel::Callbacks 内部你将会看到如下代码：

~~~ruby
def self.extended(base)
  base.class_eval do
    include ActiveSupport::Callbacks
  end
end
~~~

ActiveModel::Callbacks 对 base 即就是 ActiveRecord::Callbacks 调用了 class_eval 方法，
并包含了 ActiveSupport::Callbacks 模块。我们前面已经提到过了，对一个类调用 class_eval 与手动地将代码写在这个类里是一样的。
ActiveSupport::Callbacks 为 ActiveRecord::Callbacks 提供了 Rails 中的回调方法。

这里我们讨论了 extend 方法，以及与之对应的钩子 extended。并且也了解了 ActiveRecord / ActiveModel
是如何使用上述方法为我们提供可用功能的。

#### prepended

另一个使用定义在模块内部方法的方式称为 prepend。prepend 是在Ruby 2.0中引入的，并且与 include 和 extend 很不一样。
使用 include 和 extend 引入的方法可以被目标模块/类重新定义覆盖。
例如，如果我们在某个模块中定义了一个名为 name 的方法，并且在目标模块/类中也定义同名的方法。
那么这个在我们类在定义的 name 方法将会覆盖模块中的。而 prepend 是不一样的，它会将 prepend 引入的模块
中的方法覆盖掉我们模块/类中定义的方法。让我们来看一个简单的例子：

~~~ruby
module Person
  def name
    "My name belongs to Person"
  endend

class User
  include Person
  def name
    "My name belongs to User"
  end
end

puts User.new.name
=> My name belongs to User
~~~

现在再来看看 prepend 的情况：

~~~ruby
module Person
  def name
    "My name belongs to Person"
  endend

class User
  prepend Person
  def name
    "My name belongs to User"
  end
end

puts User.new.name
=> My name belongs to Person

使用 prepend Person 会将 User 中的同名方法给覆盖掉，因此在终端输出的结果为 My name belongs to Person。
prepend 实际上是将方法添加到方法链的前端。在调用 User 类内定义的 name 方法时，会调用 super 从而调用 Person 模块的 name。

与 prepend 对应的回调名为（你应该猜到了） prepended。当一个模块被预置到另一个模块/类中时它会被调用。
我们来看下效果。更新 Person 模块的定义：

module Person
  def self.prepended(base)
    puts "#{self} prepended to #{base}"
  end

  def name
    "My name belongs to Person"
  end
end
~~~

你再运行这段代码应该会看到如下结果：

Person prepended to User
My name belongs to Person

prepend 的引入是为了去除 alias_method_chain hack的丑陋，它曾被Rails以及其他库广泛地使用以达到与 prepend 相同的功能。
因为 prepend 只有在 Ruby >= 2.0 的版本中才能使用，因此如果你打算使用 prepend 的话，那么你就应该升级你的Ruby版本。

#### inherited

继承是面向对象中一个最重要的概念。Ruby是一门面向对象的编程语言，并且提供了从基/父类继承一个子类的功能。
我们来看一个简单的例子：

~~~ruby
class Person
  def name
    "My name is Person"
  endend

class User < Person
end

puts User.new.name # => My name is Person
~~~

我们创建了一个 Person 类和一个子类 User。在 Person 中定义的方法也成为了 User 的一部分。
这是非常简单的继承。你可能会好奇，是否有什么方法可以在一个类被其他类继承时收到通知呢？
是的，Ruby有一个名为 inherited 的钩子可以实现。我们再看看这个例子：

~~~ruby
class Person
  def self.inherited(child_class)
    puts "#{child_class} inherits #{self}"
  end

  def name
    "My name is Person"
  endend

class User < Person
end

puts User.new.name
~~~

正如你所见，当 Person 类被其他子类继承时 inherited 类方法将会被调用。
运行以上代码结果如下：

User inherits Person
My name is Person

让我们看看 Rails 在它的代码中是如何使用 inherited 的。

#### Rails中的 inherited

Rails应用中有一个重要的类名为 Application ，定义中 config/application.rb 文件内。
这个类执行了许多不同的任务，如运行所有的Railties，引擎以及插件的初始化。
关于 Application 类的一个有趣的事件是，在同一个进程中不能运行两个实例。
如果我们尝试修改这个行为，Rails将会抛出一个异常。让我们来看看Rails是如何实现这个特性的。

Application 类继承自 Rails::Application，它是在这里定义的。
在62行定义了 inherited 钩子，它会在我们的Rails应用 Application 类继承 Rails::Application 时被调用。
inherited 钩子的代码如下：
~~~ruby
class << self
  def inherited(base)
    raise "You cannot have more than one Rails::Application" if Rails.application
    super
    Rails.application = base.instance
    Rails.application.add_lib_to_load_path!
    ActiveSupport.run_load_hooks(:before_configuration, base.instance)
  end
end
~~~

class << self 是Ruby中的另一个定义类方法的方式。在 inherited 中的第1行是检查 Rails.application 是否已存在。
如果存在则抛出异常。第一次运行这段代码时 Rails.application 会返回false然后调用 super。
在这里 super 即是 Rails::Engine 的 inherited 钩子，因为 Rails::Application 继承自 Rails::Engine。

在下一行，你会看到 Rails.application 被赋值为 base.instance 。其余就是设置Rails应用了。

这就是Rails如何巧妙地使用 inherited 钩子来实现我们的Rails Application 类的单实例。

#### method_missing

method_missing 可能是Ruby中使用最广的钩子。在许多流行的Ruby框架/gem包/库中都有使用它。
当我们试图访问一个对象上不存在的方法时则会调用这个钩子方法。
让我们来看一个简单的例子：

~~~ruby
class Person
  def name
    "My name is Person"
  end
end

p = Person.new

puts p.name    # => My name is Person puts p.address  # => undefined method `address' for #<Person:0x007fb730a2b450> (NoMethodError)
~~~

我们定义了一个简单的 Person 类， 它只有一个 name 方法。然后创建一个 Person 的实例对象，
并分别调用 name 和 address　两个方法。因为 Person 中定义了 name，因此这个运行没问题。
然而 Person 并没有定义 address，这将会抛出一个异常。
method_missing 钩子可以优雅地捕捉到这些未定义的方法，避免此类异常。
让我们修改一下 Person 类：

~~~ruby
class Person
  def method_missing(sym, *args)
    "#{sym} not defined on #{self}"
  end

  def name
    "My name is Person"
  end
end

p = Person.new

puts p.name    # => My name is Personputs p.address  # => address not defined on #<Person:0x007fb2bb022fe0>

method_missing 接收两个参数：被调用的方法名和传递给该方法的参数。
首先Ruby会寻找我们试图调用的方法，如果方法没找到则会寻找 method_missing 方法。
现在我们重载了 Person 中的 method_missing，因此Ruby将会调用它而不是抛出异常。

让我们来看看 Rake 是如何使用 method_missing 的。

Rake中的 method_missing

Rake 是Ruby中使用最广泛的gem包之一。Rake 使用 method_missing 来提供访问传递给Rake任务的参数。
首先创建一个简单的rake任务：

~~~ruby
task :hello do
  puts "Hello"
end
~~~

如果你通过调用 rake hello 来执行这个任务，你会看到输出 Hello。
让我们扩展这个rake任务，以便接收一个参数（一个人名）并向他打招呼：

~~~ruby
task :hello, :name do |t, args|
  puts "Hello #{args.name}"
end
~~~

t 是任务名，args 保存了传递过来的参数。正如你所见，我们调用 args.name 来获取传递给 hello 任务的 name 参数。
运行该任务，并传递一个参数：

~~~ruby
rake hello["Imran Latif"]=> Hello Imran Latif
~~~

让我们来看看 Rake 是如何使用 method_missing 为我们提供了传递给任务的参数的。

在上面任务中的 args 对象是一个 Rake::TaskArguments 实例，它是在这里所定义。
这个类负责管理传递给Rake任务的参数。查看 Rake::TaskArguments 的代码，你会发现并没有定义相关的方法将参数传给任务。
那么 Rake 是如何将参数提供给任务的呢？答案是 Rake 是使用了 method_missing 巧妙地实现了这个功能。
看看第64行 method_missing 的定义：

~~~ruby
def method_missing(sym, *args)
  lookup(sym.to_sym)
end
~~~
在这个类中定义 method_missing 是为了保证能够访问到那些未定义的方法，而不是由Ruby抛出异常。
在 method_missing 中它调用了 lookup 方法：

~~~ruby
def lookup(name)
  if @hash.has_key?(name)
  @hash[name]
  elsif @parent
    @parent.lookup(name)
  end
end
~~~

method_missing 调用 lookup，并将方法名以 Symbol(符号) 的形式传递给它。
lookup 方法将会在 @hash 中进行查找，它是在 Rake::TaskArguments 的构造函数中创建的。
如果 @hash 中包含该参数则返回，如果在 @hash 中没有则 Rake 会尝试调用 @parent 的 lookup。
如果该参数没有找到，则什么都不返回。

这就是 Rake 如何巧妙地使用 method_missing 提供了访问传递给Rake任务的参数的。
感谢Jim Weirich编写了Rake。

结束语

我们讨论了5个重要的Ruby钩子方法，探索了它们是如何工作的，以及一些流行的框架/gem包是如何使用它们来提供一些优雅的功能。
我希望你能喜欢这篇文章。请在评论中告诉我们你所喜欢的Ruby钩子，以及你使用它们所解决的问题。
