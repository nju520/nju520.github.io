---
layout: post
toc: true
permalink: /rails-concern
title: Rails Concern 的使用以及源码解读
tags: Ruby Rails Concern
desc: 熟悉Rails的同学肯定知道, Rails类使用include SomeConcern 包含模块后可以同时获得实例方法和类方法,这是如何实现的呢? 答案需要到Active Support 类库的 Concern 模块中寻找. ActiveSupport::Concern模块修改了Ruby的对象模型, 它封装了“在我的类中添加类方法”这个功能, 并且可以在类中引入其他模块而不造成链式包含的问题.
---


## 使用 ActiveSupport::Concern

熟悉 Ruby on Rails 的同学肯定使用过`Concern`来让Rails类包含模块的同时获得实例方法和类方法. 举个例子:

~~~ruby
require 'active_support'
module ConcernA
  extend ActiveSupport::Concern

  included do
    enum status: { unconnect: 0, connected: 1, success: 2, failed: 3 }
    scope :active, -> { where(active: true) }
    scope :with_name, -> (name) { where(name: name) }
  end

  def hello_world
    'hello world'
  end

  module ClassMethods
    def score_rules
      %w(red_rec red_combo nice_repay)
    end
  end

end

class User < ApplicationRecord
  include ConcernA
end

User.score_rules
#=>  ["red_rec", "red_combo", "nice_repay"]

User.new.hello_world
#=> "hello world "

~~~

在Rail2 时代, Active Model类库还未出现, 如果像现在引入一个模块时需要一点小技巧

## 古老的做法

~~~ruby
module ConcernA
  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      enum status: { unconnect: 0, connected: 1, success: 2, failed: 3 }
      scope :active, -> { where(active: true) }
      scope :with_name, -> (name) { where(name: name) }
    end

    include InstanceMethods
  end

  module InstanceMethods
    def hello_world
      'hello world'
    end
  end

  module ClassMethods
    def score_rules
      %w(red_rec red_combo nice_repay)
    end
  end
end

~~~
从代码可知, 通过 `extend`以及`class_eval`为`base`类定义了`ClassMethods`中的类方法, 通过`include`为`base`类定义了`InstanceMethods`中的实例方法.

但是这样实现会有一个比较严重的问题, 也就是`链式包含`.
考虑一下代码:

~~~ruby
module Foo
  def self.included(base)
    base.class_eval do
      def self.method_injected_by_foo
        ...
      end
    end
  end
end

module Bar
  include Foo
  def self.included(base)
    base.method_injected_by_foo
  end
end

class Host
  include Foo # We need to include this dependency for Bar
  include Bar # Bar is the module that Host really needs
end
~~~

上面例子中 `Host` 为了 `include Bar`，必须得先 `include Bar` 依赖的` Foo`，这是因为 Bar 在 `include Foo` 时，只是为 `Bar extend method_injected_by_foo` 方法，所以 Host 必须显式的 `include Foo`，才能够 `extend method_injected_by_foo` 方法。

如果使用`ActiveSupport::Concern`来完成, 代码就简洁很多:

~~~ruby
module Foo
  extend ActiveSupport::Concern
  included do
    class_eval do
      def self.method_injected_by_foo
        ...
      end
    end
  end
end

module Bar
  extend ActiveSupport::Concern
  include Foo

  included do
    self.method_injected_by_foo
  end
end

class Host
  include Bar # works, Bar takes care now of its dependencies
end
~~~

Bar 和 Foo 都 `extend ActiveSupport::Concern` 后，`Host include Bar `已经不需要事先 `mix Foo`.

## 深入 ActiveSupport::Concern 源码 解读

直接查看`ActiveSupport::Concern`的相关源码:
~~~ruby
# frozen_string_literal: true
module ActiveSupport
  module Concern
    class MultipleIncludedBlocks < StandardError #:nodoc:
      def initialize
        super "Cannot define multiple 'included' blocks for a Concern"
      end
    end

    def self.extended(base) #:nodoc:
      base.instance_variable_set(:@_dependencies, [])
    end

    def append_features(base)
      if base.instance_variable_defined?(:@_dependencies)
        base.instance_variable_get(:@_dependencies) << self
        false
      else
        return false if base < self
        @_dependencies.each { |dep| base.include(dep) }
        super
        base.extend const_get(:ClassMethods) if const_defined?(:ClassMethods)
        base.class_eval(&@_included_block) if instance_variable_defined?(:@_included_block)
      end
    end

    def included(base = nil, &block)
      if base.nil?
        raise MultipleIncludedBlocks if instance_variable_defined?(:@_included_block)

        @_included_block = block
      else
        super
      end
    end

    def class_methods(&class_methods_module_definition)
      mod = const_defined?(:ClassMethods, false) ?
        const_get(:ClassMethods) :
        const_set(:ClassMethods, Module.new)

      mod.module_eval(&class_methods_module_definition)
    end
  end
end

　
~~~
主要是两个方法extend和append_features
当模块扩展Concern时候，会调用钩子方法extended。在这个方法中为扩展它的类定义了一个`@_dependencies`.默认值是[].
方法append_features是一个内核方法。和module#included类似。
* 相同点：当包含一个模块的时候被调用。
* 不同点：included默认是空的，只有覆写之后才会有内容。而append_features则包含有实际的动作。用于检查被包含模块是否已经在包含类的祖先链上，如果不在则将该模块加入其祖先链。

当一个模块扩展ActiveSupport::Concern,我们称其为一个concern
接着我们来分析append_features的源码：
主要分为两种情况：
#### 第一种情况
~~~ruby
module MyConcernB
  extend ActiveSupport::Concern

  def an_instance_methodb
    "an_instance_method "
  end

  module ClassMethods
    def a_class_methodb
      "a_class_method"
    end
  end
  def self.instance_check
    instance_variable_get(:@_dependencies)
  end
  include MyConcernA
end
~~~

代码会先判断base是否是一个concern.
当前是一个concern(MyConcernB)在包含一个concern(MyConcernA).此时包含的时候并没有真正的执行包含的动作，只是把链接放到一个依赖图中。也就是将MyConcernA放入数组`@_dependencies`.

~~~ruby
MyConcernB.instance_check
 => [MyConcernA]
# MyConcernB.a_class_method
# NoMethodError: undefined method `a_class_method' for MyConcernB:Module
~~~

#### 第二种情况
~~~ruby
class MyClass
  include MyConcernB
end
~~~

此时就是else后边的情况了。
首先会判断MyClass 是否继承了MyConcernB,也就是看MyConcernB是否在MyClass的继承链中。
如果没有就进行最关键的步骤：concern(MyConcernB)中的依赖（也就是`@_dependencies`,上文已经打印出了值）会被递归包含到类Myclass中。这种最小化的依赖管理方式解决了之前链式包含的问题。
此处的 `@_dependencies.each { |dep| base.send(:include, dep) }`
就相当于在MyClass中.

~~~ruby
include MyConcernA
~~~

把所有的依赖的concern(也就是`@_dependencies`中的值)都加入类的祖先链之后，
需要把包含类自己（此处相当于MyConcernB）也加入类的继承链中。这个通过调用super来实现。
最后是要通过ClassMethods模块来扩展类，就像最初做的事情一样。

## 总结

在rails 中不仅提倡在model中使用concern，而且还提倡在controller里面也使用。最典型的一个gem 就是这个 inherited_resources. 当然这是一个gem，但是意思是差不多的，就是 DON'T Repeat Yourself -- 它将controller里面的最典型的7个aciton封装起来.极大的精简了controller里面的代码。
