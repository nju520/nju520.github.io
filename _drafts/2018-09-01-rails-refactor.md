---
layout: post
toc: true
permalink: /rails-refactor
title: rails重构
tags: rals refactor
desc: Pusher是一个基于 WebSocket的实时消息推送服务。

---

`Ruby on Rails`近几年在国内受到越来越多的开发者的青睐，`Rails`应用也从比较简单的内部系统深入到复杂的企业级应用。

`Rails`的`习惯大于配置`的思想以及`ActiveRecord`等众多优秀的技术极大地提高了开发效率，但是在业务复杂的大型系统中，`Rails`应用也会面临很多问题。

本篇文章围绕以下几种模式来详细地阐述如何更好的进行`Rails`代码重构:

* Services Objects
* Form Objects
* Query Objects
* View Objects(Serializer/Presenter)
* Policies Objects
* Value Objects
* Decorators Objects
* Observers Objects
* Delegate Objects
* Worker Objects



## Services Objects

当`Controller`中的`action`有以下症状时:

* 过于复杂(比如电商中的下单)
* 调用外部API
* 明显不属于某个`model`(比如删除过期数据)
* 涉及多个`model`

我们就可以使用`services object`来精简我们的`controller action`



### 示例

以下示例中，主要工作由外部Stripe服务完成。该服务基于邮件地址和来源创建Stripe客户，并将所有服务费用绑定到该客户的账号上。

### 问题分析

- Controller中包含调用外部服务的代码
- Controller负责构建调用外部服务所需的数据
- Controller难于维护和扩展

```ruby
class ChargesController < ApplicationController
   def create
     amount = params[:amount].to_i * 100
     customer = .create(
       email: params[:email],
       source: params[:source]
     )
     charge = Stripe::Charge.create(
       customer: customer.id,
       amount: amount,
       description: params[:description],
       currency: params[:currency] || 'USD'
     )
     redirect_to charges_path
   rescue Stripe::CardError => exception
     flash[:error] = exception.message
     redirect_to new_charge_path
   end
  end
```

为了解决这些问题，可以将其封装为一个外部服务。

```ruby
# controller
class ChargesController < ApplicationController
 def create
   CheckoutService.new(params).call
   redirect_to charges_path
 rescue Stripe::CardError => exception
   flash[:error] = exception.message
   redirect_to new_charge_path
 end
end

# service
class CheckoutService
 DEFAULT_CURRENCY = 'USD'.freeze

 # 可以使用 instance_variable_set来批量设置实例变量
 def initialize(options = {})
   options.each_pair do |key, value|
     instance_variable_set("@#{key}", value)
   end
 end

 def call
   Stripe::Charge.create(charge_attributes)
 end

 private

 attr_reader :email, :source, :amount, :description

 def currency
   @currency || DEFAULT_CURRENCY
 end

 def amount
   @amount.to_i * 100
 end

 def customer
   @customer ||= Stripe::Customer.create(customer_attributes)
 end

 def customer_attributes
   {
     email: email,
     source: source
   }
 end

 def charge_attributes
   {
     customer: customer.id,
     amount: amount,
     description: description,
     currency: currency
   }
 end
end
```

最终由`CheckoutService`来负责客户账号的创建和支付，从而解决了Controller中业务代码过多的问题。但是，还有一个问题需要解决。如果外部服务抛出异常时（如，信用卡无效）该如何处理，需要重定向的其他页面吗？

```ruby
class ChargesController < ApplicationController
 def create
   CheckoutService.new(params).call
   redirect_to charges_path
 rescue Stripe::CardError => exception
   flash[:error] = exception.error
   redirect_to new_charge_path
 end
end
```

为了解决这个问题，可以在一个Interactor对象中调用`CheckoutService`，并捕获可能产生的异常。Interactor模式常用于封装业务逻辑，每个Interactor一般只描述一条业务逻辑。

Interactor模式通过简单Ruby对象（plain old Ruby objects, POROs）可以帮助我们实现单一原则（Single Responsibility Principle, SRP）。Interactor与Service Object类似，只是通常会返回执行状态及相关信息，而且一般会在Interactor内部使用Service Object。下面是该设计模式的使用示例：

```ruby
class ChargesController < ApplicationController
 def create
   interactor = CheckoutInteractor.call(self)

   if interactor.success?
     redirect_to charges_path
   else
     flash[:error] = interactor.error
     redirect_to new_charge_path
   end
 end
end

# interactor
class CheckoutInteractor
 def self.call(context)
   interactor = new(context)
   interactor.run
   interactor
 end

 attr_reader :error

 def initialize(context)
   @context = context
 end

 def success?
   @error.nil?
 end

 def run
   CheckoutService.new(context.params)
 rescue Stripe::CardError => exception
   fail!(exception.message)
 end

 private

 attr_reader :context

 def fail!(error)
   @error = error
 end
end
```

移除所有信用卡错误相关的异常，Controller就达到了瘦身的目的。瘦身以后，Controller只负责成功支付和失败支付时的页面跳转。



### 继续简化 `Interactor`

考虑到我们平时最多还是直接使用`service`来封装复杂的业务逻辑，我们将`service`和`interactor`结合，使之不仅能够正确的处理业务逻辑， 还可以捕获特定的异常,捕获的异常可以直接通过`service`返回的结果读取出来。

~~~ruby
class ChargesController < ApplicationController
 def create
   result = CheckoutService.new(params).run

   if result.success?
     redirect_to charges_path
   else
     flash[:error] = result.error
     redirect_to new_charge_path
   end
 end
end

# service
class CheckoutService
 DEFAULT_CURRENCY = 'USD'.freeze
    
 attr_reader :error

 # 可以使用 instance_variable_set来批量设置实例变量
 def initialize(options = {})
   options.each_pair do |key, value|
     instance_variable_set("@#{key}", value)
   end
 end

 def run
   Stripe::Charge.create(charge_attributes)
 rescue Stripe::CardError => exception
   fail!(exception.message)
 end
    
 def success?
   @error.nil?
 end

 private

 attr_reader :email, :source, :amount, :description

 def currency
   @currency || DEFAULT_CURRENCY
 end

 def amount
   @amount.to_i * 100
 end

 def customer
   @customer ||= Stripe::Customer.create(customer_attributes)
 end

 def customer_attributes
   {
     email: email,
     source: source
   }
 end

 def charge_attributes
   {
     customer: customer.id,
     amount: amount,
     description: description,
     currency: currency
   }
 end
 
 def fail!(error)
   @error = error
 end
end
~~~



> 个人认为回调应该处理和业务逻辑无关的东西，比如刷新冗余字段、添加操作记录之类，否则考虑什么时候会触发回调本身就是灾难。



总结一下什么时候应该抽取 service:

- 当发生跨model的写的时候。这不是必然，但是可以认为是一个信号，表示你的业务逻辑开始变的复杂了。同时，当跨model的“写”都遵守了这个规则时，rails的model层就会变成一个真正的 DAL（Data Access Layer），不再是混合了数据逻辑和业务逻辑的 “Fat Model”；

- 一般来讲，callback 是要慎用的，特别是 callback 里面涉及到了调用其他 model 、修改其他 model 的情况，这个时候就可以考虑把相关的逻辑抽成 service 。

其他像文章最初提到的一些规则都比较模糊，需要经验丰富的工程师才能比较明确的判断，比如业务逻辑比较复杂、相对独立、将来可能会被升级成独立的模块的时候，这些需要一定的经验积累才比较容易判断。

service 的好处，基本上是抽象层独立的类之后的好处：

1. 复用性比较好。因为是 ruby plain object，所以复用性上很简单，可以用在各种地方；
2. 比较独立，可扩展性比较好。可以扩展 service ，给它添加新的方法、修改原有的行为均可；
3. 可测试性也会较好。

抽取service 的本质是要把数据逻辑层和业务逻辑区别对待，让 model 层稍微轻一些；Rails 里面有 view logic、data logic、domain logic，把它们区别对待是最基本的，这样才能写出更清晰、可维护的大型应用来。





## Form Objects



Form Object模式适用于封装数据校验和持久化。

### 示例

假设我们有一个典型Rails Model和Controller用于创建新用户。

### 问题分析

Model中包含了所有校验逻辑，因此不能为其他实体重用，如Admin。

```ruby
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user
    else
      render json: @user.error, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params
      .require(:user)
      .permit(:email, :full_name, :password, :password_confirmation)
  end
end
class User < ActiveRecord::Base
  EMAIL_REGEX = /@/ # Some fancy email regex

  validates :full_name, presence: true
  validates :email, presence: true, format: EMAIL_REGEX
  validates :password, presence: true, confirmation: true
end
```

解决方案就是将所有校验逻辑移到一个单独负责校验的类中，可以称之为`UserForm`。

```ruby
class UserForm
  EMAIL_REGEX = // # Some fancy email regex

  include ActiveModel::Model
  include Virtus.model

  attribute :id, Integer
  attribute :full_name, String
  attribute :email, String
  attribute :password, String
  attribute :password_confirmation, String

  validates :full_name, presence: true
  validates :email, presence: true, format: EMAIL_REGEX
  validates :password, presence: true, confirmation: true

  attr_reader :record

  def persist
    @record = id ? User.find(id) : User.new

    if valid?
      @record.attributes = attributes.except(:password_confirmation, :id)
      @record.save!
      true
    else
      false
    end
  end
end
```

现在，就可以在Controller里面像这样使用它了：

```ruby
class UsersController < ApplicationController
  def create
    @form = UserForm.new(user_params)

    if @form.persist
      render json: @form.record
    else
      render json: @form.errors, status: :unpocessably_entity
    end
  end

  private

  def user_params
    params.require(:user)
          .permit(:email, :full_name, :password, :password_confirmation)
  end
end
```

最终，用户Model不在负责校验数据：

```
class User < ActiveRecord::Base
end
```

这样可以精简我们的`model`,让我们的`model`更关注于核心业务。

> form表单存在的意义主要在于创建或者更新`model`,我们可以在form中添加一些model层才会有的校验，所以当我们新建一个record比如注册用户或者订单时我们可以使用form表单来进行抽象。
>
> 如果新建record时涉及多个model,业务非常复杂时，还是推荐使用services.





## Query Objects



该模式适用于从Controller和Model中抽取查询逻辑，并将它封装到可重用的类。

### 示例

假设我们请求一个文章列表，查询条件是类型为video、查看数大于100并且当前用户可以访问。

### 问题分析

所有查询逻辑都在Controller中（即所有查询条件都在Controller中添加）。

- 不可重用
- 难于测试
- 文章Scheme的任何改变都可能影响这段代码

```ruby
class Article < ActiveRecord::Base
    # t.string :status
    # t.string :type
    # t.integer :view_count
  end

 class ArticlesController < ApplicationController
    def index
      @articles = Article
                  .accessible_by(current_ability)
                  .where(type: :video)
                  .where('view_count > ?', 100)
    end
  end
```

重构的第一步就是封装查询条件，提供简洁的API接口。在Rails中，可以使用scope实现：

```ruby
class Article < ActiveRecord::Base
  scope :with_video_type, -> { where(type: :video) }
  scope :popular, -> { where('view_count > ?', 100) }
  scope :popular_with_video_type, -> { popular.with_video_type }
end
```

现在就可以使用这些简洁的API接口来查询，而不用关心底层是如何实现的。如果article的scheme发生了改变，仅需要修改article类即可。

```ruby
class ArticlesController < ApplicationController 
  def index 
    @articles = Article 
                .accessible_by(current_ability) 
                .popular_with_video_type 
  end
end
```

看起来不错，不过又有一些新问题出现了。首先，需要为每个想要封装的查询条件创建scope，最终会导致Model中充斥诸多针对不同应用场景的scope组合。其次，scope不能在不同的model中重用，比如不用使用Article的scope来查询Attachment。最后，将所有查询相关的逻辑都塞到Article类中也违反了单一原则。解决方案是使用Query Object。

```ruby
class PopularVideoQuery 
  def call(relation) 
    relation 
      .where(type: :video) 
      .where('view_count > ?', 100) 
  end
end

class ArticlesController < ApplicationController 
  def index 
    relation = Article.accessible_by(current_ability) 
    @articles = PopularVideoQuery.new.call(relation) 
  end
end
```

哈，这样就可以做到重用了！现在可以将它用于查询任何具有相似scheme的类了：

```ruby
class Attachment < ActiveRecord::Base 
  # t.string :type 
  # t.integer :view_count
end

PopularVideoQuery.new.call(Attachment.all).to_sql
# "SELECT \"attachments\".* FROM \"attachments\" WHERE \"attachments\".\"type\" = 'video' AND (view_count > 100)"
PopularVideoQuery.new.call(Article.all).to_sql
# "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"type\" = 'video' AND (view_count > 100)"
```

如果想进一步支持链式调用的话，也很简单。只需要让`call`方法遵循`ActiveRecord::Relation`接口即可：

```ruby
class BaseQuery
  def |(other)
    ChainedQuery.new do |relation|
      other.call(call(relation))
    end
  end
end

class ChainedQuery < BaseQuery
  def initialize(&block)
    @block = block
  end

  def call(relation)
    @block.call(relation)
  end
end

class WithStatusQuery < BaseQuery
  def initialize(status)
    @status = status
  end

  def call(relation)
    relation.where(status: @status)
  end
end

query = WithStatusQuery.new(:published) | PopularVideoQuery.new
query.call(Article.all).to_sql
# "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"status\" = 'published' AND \"articles\".\"type\" = 'video' AND (view_count > 100)"
```

现在，我们得到了一个封装所有查询逻辑，可重用，提供简洁接口并易于测试的类。



我们还可以借鉴`gitlab`的做法，将查询接口和`model`独立开来,将需要查询的对象作为参数传入`Query Object`:

~~~ruby
# Finders

This type of classes responsible for collection items based on different conditions.
To prevent lookup methods in models like this:

```ruby
class Project
  def issues_for_user_filtered_by(user, filter)
    # A lot of logic not related to project model itself
  end
end

issues = project.issues_for_user_filtered_by(user, params)
```

Better use this:

```ruby
issues = IssuesFinder.new(project, user, filter).execute
```

It will help keep models thiner.
这样可以使我们的model更精简

~~~



以`users_query.rb`为例:

~~~ruby
# UsersFinder
#
# Used to filter users by set of params
#
# Arguments:
#   current_user - which user use
#   params:
#     username: string
#     extern_uid: string
#     provider: string
#     search: string
#     active: boolean
#     blocked: boolean
#     external: boolean
#
class UsersFinder
  include CreatedAtFilter
  include CustomAttributesFilter

  attr_accessor :current_user, :params

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    users = User.all.order_id_desc
    users = by_username(users)
    users = by_search(users)
    users = by_blocked(users)
    users = by_active(users)
    users = by_external_identity(users)
    users = by_external(users)
    users = by_2fa(users)
    users = by_created_at(users)
    users = by_custom_attributes(users)

    users
  end

  private

  def by_username(users)
    return users unless params[:username]

    users.where(username: params[:username])
  end

  def by_search(users)
    return users unless params[:search].present?

    users.search(params[:search])
  end

  def by_blocked(users)
    return users unless params[:blocked]

    users.blocked
  end

  def by_active(users)
    return users unless params[:active]

    users.active
  end

  def by_external_identity(users)
    return users unless current_user&.admin? && params[:extern_uid] && params[:provider]

    # Merges in the conditions from other, if other is an ActiveRecord::Relation. 
    # Returns an array representing the intersection of the resulting records with other, if other is an array.
    users.joins(:identities).merge(Identity.with_extern_uid(params[:provider], params[:extern_uid]))
  end

  def by_external(users)
    return users = users.where.not(external: true) unless current_user&.admin?
    return users unless params[:external]

    users.external
  end

  def by_2fa(users)
    case params[:two_factor]
    when 'enabled'
      users.with_two_factor
    when 'disabled'
      users.without_two_factor
    else
      users
    end
  end
end


module CreatedAtFilter
  def by_created_at(items)
    items = items.created_before(params[:created_before]) if params[:created_before].present?
    items = items.created_after(params[:created_after]) if params[:created_after].present?

    items
  end
end

module CustomAttributesFilter
  def by_custom_attributes(items)
    return items unless params[:custom_attributes].is_a?(Hash)
    return items unless Ability.allowed?(current_user, :read_custom_attribute)

    association = items.reflect_on_association(:custom_attributes)
    attributes_table = association.klass.arel_table
    attributable_table = items.model.arel_table

    custom_attributes = association.klass.select('true').where(
      attributes_table[association.foreign_key]
        .eq(attributable_table[association.association_primary_key])
    )

    # perform a subquery for each attribute to be filtered
    params[:custom_attributes].inject(items) do |scope, (key, value)|
      scope.where('EXISTS (?)', custom_attributes.where(key: key, value: value))
    end
  end
end


~~~



上述的 `UserFinder`根据传入的参数来选择过滤`users`.不过我们可以利用`relation chain`来改造上述的`Query Object`:

~~~ruby
# UsersQuery
#
# Used to filter users by set of params
# We use scope to obtain relation chain ability.
#
# Arguments:
#   current_user - which user use
#   params:
#     username: string
#     extern_uid: string
#     provider: string
#     search: string
#     active: boolean
#     blocked: boolean
#     external: boolean
#
class UsersQuery
  include CreatedAtFilter
  include CustomAttributesFilter

  attr_accessor :current_user, :params, :scope

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
    @scope = User.all.order_id_desc
  end

  def execute
    by_username
    by_search
    by_blocked
    by_active
    by_external_identity
    by_external
    by_2fa
    by_created_at
    by_custom_attributes

    scope
  end

  private

  def by_username
    return @scope unless params[:username]

    scope.where(username: params[:username]) # here we can define scope in models/user.rb
  end

  def by_search
    return scope unless params[:search].present?

    scope.search(params[:search])
  end

  def by_blocked
    return scope unless params[:blocked]

    scope.blocked
  end

  def by_active
    return scope unless params[:active]

    scope.active
  end

  def by_external_identity
    return scope unless current_user&.admin? && params[:extern_uid] && params[:provider]

    scope.joins(:identities).merge(Identity.with_extern_uid(params[:provider], params[:extern_uid]))
  end

  def by_external
    return scope = scope.where.not(external: true) unless current_user&.admin?
    return scope unless params[:external]

    scope.external
  end

  def by_2fa
    case params[:two_factor]
    when 'enabled'
      scope.with_two_factor
    when 'disabled'
      scope.without_two_factor
    else
      scope
    end
  end
end


~~~



## View Objects(Serializer/Presenter)

> Presenter: It's just a class that represents display logic for a model.



先明确两个概念:

1. **Attribute**：特指用来保存 *数据* 的属性（如 Ruby 中的实例变量）而不是 *行为*（如 Ruby 中的方法）；
2. **Property**：这是一种统称，无论是用来表示 *数据* 的 **Attribute**，还是用来表示 *行为* 的 **Method**，它们都是对象的 **Property**
   * 虚拟属性也有被称作 **Computed Property** 的. **计算后属性**这个词虽然拗口，但我觉得还是比较形象的。

我们可以将API需要对外的数据格式和类型通过`Serializer/Presenter/Representer`暴露出去，这样就无需在`model`层添加多余的代码。

View Object适用于将View中的数据及相关计算从Controller和Model抽离出来，如一个网站的HTML页面或API终端请求的JSON响应。

## 示例

View中一般通常存在以下计算：

- 根据服务器协议和图片路径创建图片URL
- 获取文章的标题和描述，如果没有返回默认值
- 连接姓和名来显示全名
- 用合适的方式显示文章的创建日期

## 问题分析

View中包含了太多计算逻辑。

```erb
# 重构之前
#/app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
 def show
   @article = Article.find(params[:id])
 end
end

#/app/views/articles/show.html.erb
<% content_for :header do %>
 <title>
     <%= @article.title_for_head_tag || I18n.t('default_title_for_head') %>
 </title>
 <meta name='description' content="<%= @article.description_for_head_tag || I18n.t('default_description_for_head') %>">
  <meta property="og:type" content="article">
  <meta property="og:title" content="<%= @article.title %>">
  <% if @article.description_for_head_tag %>
    <meta property="og:description" content="<%= @article.description_for_head_tag %>">
  <% end %>
  <% if @article.image %>
     <meta property="og:image" content="<%= "#{request.protocol}#{request.host_with_port}#{@article.main_image}" %>">
  <% end %>
<% end %>

<% if @article.image %>
 <%= image_tag @article.image.url %>
<% else %>
 <%= image_tag 'no-image.png'%>
<% end %>
<h1>
 <%= @article.title %>
</h1>

<p>
 <%= @article.text %>
</p>

<% if @article.author %>
<p>
 <%= "#{@article.author.first_name} #{@article.author.last_name}" %>
</p>
<%end%>

<p>
 <%= t('date') %>
 <%= @article.created_at.strftime("%B %e, %Y")%>
</p>
```

为了解决这个问题，可以先创建一个presenter基类，然后再创建一个`ArticlePresenter`类的实例。`ArticlePresenter`方法根据适当的计算返回想要的标签。

```ruby
#/app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
 def show
   @article = Article.find(params[:id])
 end
end

#/app/presenters/base_presenter.rb
class BasePresenter
 def initialize(object, template)
   @object = object
   @template = template
 end

 def self.presents(name)
   define_method(name) do
     @object
   end
 end

 def h
   @template
 end
end

#/app/helpers/application_helper.rb
module ApplicationHelper
  def presenter(model)
    klass = "#{model.class}Presenter".constantize
    presenter = klass.new(model, self)
    yield(presenter) if block_given?
  end
end

#/app/presenters/article_presenters.rb
class ArticlePresenter < BasePresenter
 presents :article
 delegate :title, :text, to: :article

 def meta_title
   title = article.title_for_head_tag || I18n.t('default_title_for_head')
   h.content_tag :title, title
 end

 def meta_description
   description = article.description_for_head_tag || I18n.t('default_description_for_head')
   h.content_tag :meta, nil, content: description
 end

 def og_type
   open_graph_meta "article", "og:type"
 end
  def og_title
   open_graph_meta "og:title", article.title
 end

 def og_description
   open_graph_meta "og:description", article.description_for_head_tag if article.description_for_head_tag
 end

 def og_image
   if article.image
     image = "#{request.protocol}#{request.host_with_port}#{article.main_image}"
     open_graph_meta "og:image", image
   end
 end

 def author_name
   if article.author
     h.content_tag :p, "#{article.author.first_name} #{article.author.last_name}"
   end
 end

 def image
  if article.image
    h.image_tag article.image.url
  else
     h.image_tag 'no-image.png'
  end
 end

 private
 def open_graph_meta content, property
   h.content_tag :meta, nil, content: content, property: property
 end
end
```

现在View中不包含任何与计算相关的逻辑，所有组件都抽离到了presenter中，并可在其他View中重用，如下：

```erb
#/app/views/articles/show.html.erb
# here @templete is view object 
<% presenter @article do |article_presenter| %>
 <% content_for :header do %>
   <%= article_presenter.meta_title %>
   <%= article_presenter.meta_description %>
   <%= article_presenter.og_type %>
   <%= article_presenter.og_title %>
   <%= article_presenter.og_description %>
   <%= article_presenter.og_image %>
 <% end %>

 <%= article_presenter.image%>
 <h1> <%= article_presenter.title %> </h1>
 <p>  <%= article_presenter.text %> </p>
 <%= article_presenter.author_name %>
<% end %>
```





## Policies Objects

Policy Object模式与Service Object模式相似，前者负责读操作，后者负责写操作。Policy Object模式适用于封装复杂的业务规则，并易于替换。比如，可以使用一个访客Policy Object来识别一个访客是否可以访问某些特定资源。当用户是管理员时，可以很方便的将访客Policy Object替换为包含管理员规则的管理员Policy Object。


### 示例

在用户创建一个项目之前，Controller将检查当前用户是否为管理者，是否有权限创建项目，当前用户项目数量是否小于最大值，以及在Redis中是否存在阻塞的项目创建。

### 问题分析

- 自由Controller知道项目创建的规则
- Controller包含了额外的逻辑代码

```ruby
class ProjectsController < ApplicationController
   def create
     if can_create_project?
       @project = Project.create!(project_params)
       render json: @project, status: :created
     else
       head :unauthorized
     end
   end

  private

  def can_create_project?
     current_user.manager? &&
       current_user.projects.count < Project.max_count &&
       redis.get('projects_creation_blocked') != '1'
   end

  def project_params
     params.require(:project).permit(:name, :description)
  end

  def redis
    Redis.current
  end
end

class User < ActiveRecord::Base
  enum role: [:manager, :employee, :guest]
end
```

为了让Controller瘦身，可以将规则代码移到Model中。所有检查逻辑都将移出Controller。但是这样一来，User类就知道了Redis和Project类的逻辑。并且Model也变胖了。

```
class User < ActiveRecord::Base
  enum role: [:manager, :employee, :guest]

  def can_create_project?
    manager? &&
      projects.count < Project.max_count &&
        redis.get('projects_creation_blocked') != '1'
  end

  private

  def redis
    Redis.current
  end
end

class ProjectsController < ApplicationController
  def create
    if current_user.can_create_project?
       @project = Project.create!(project_params)
       render json: @project, status: :created
    else
       head :unauthorized
    end
  end

  private

  def project_params
     params.require(:project).permit(:name, :description)
  end
end
```

在这种情况下，可以将这些规则抽取到一个Policy Object中，从而使Controller和Model同时瘦身。

```ruby
class CreateProjectPolicy
  def initialize(user, redis_client)
    @user = user
    @redis_client = redis_client
  end

  def allowed?
    @user.manager? && below_project_limit && !project_creation_blocked
  end

 private

  def below_project_limit
    @user.projects.count < Project.max_count
  end

  def project_creation_blocked
    @redis_client.get('projects_creation_blocked') == '1'
  end
end

class ProjectsController < ApplicationController
  def create
    if policy.allowed?
       @project = Project.create!(project_params)
       render json: @project, status: :created
     else
       head :unauthorized
     end
  end

  private

  def project_params
     params.require(:project).permit(:name, :description)
  end

  def policy
     CreateProjectPolicy.new(current_user, redis)
  end

  def redis
     Redis.current
  end
end

def User < ActiveRecord::Base
   enum role: [:manager, :employee, :guest]
end
```

最终的结果是一个干净的Controller和Model。Policy Object封装了所有权限检查逻辑，并且所有外部依赖都从Controller注入到Policy Object中。所有的类都各司其职。



## Value Objects



## Decorators Objects

### SimpleDecorator

> A concrete implementation of [Delegator](https://ruby-doc.org/stdlib-2.2.1/libdoc/delegate/rdoc/Delegator.html), this class provides the means to delegate all supported method calls to the object passed into the constructor and even to change the object being delegated to at a later time with #__setobj__.

Decorators are great - especially for building Ruby on Rails applications. They help separate the functionality from your models that some would consider "not core". Ruby has a neat class called SimpleDelegator that we've been using to implement the decorator pattern. It's clean, simple, attractive, and good with children which makes it a great candidate for this type of work. So let's use it!

Lets say we have a `Person` class with `#first_name` and `#last_name` attributes and we want to add a `#full_name`method to this `Person`

~~~ruby
class Person

  attr_reader :first_name, :last_name

  def initialize(first_name, last_name)
    @first_name, @last_name = first_name, last_name
  end

end
~~~



Create our `PersonDecorator` that inherits from SimpleDelegator



And add our `#full_name` method

```ruby
class PersonDecorator < SimpleDelegator

  def full_name
    first_name + " " + last_name
  end

end
```
So there is our decorator. But how would one actually use this? Actual use could look something like this:

Create our person object

~~~ruby
person = Person.new('Joe', 'Hashrocket')

person.first_name #=> 'Joe'
person.last_name #=> 'Hashrocket'
person.full_name #=> Method_Missing error
~~~



~~~ruby
decorated_person = PersonDecorator.new(person)

decorated_person.first_name #=> 'Joe'
decorated_person.last_name #=> 'Hashrocket'
decorated_person.full_name #=> 'Joe Hashrocket'
~~~



All SimpleDelegator is really doing is giving you method missing. Good stuff...

> every method which is not defined will delegate to an object

Now, I want to add a way to handle collections with this decorator. That is something often done with decorators. So, let's add the class method `.wrap` to this decorator. Our final version looks like this:

~~~ruby
class PersonDecorator < SimpleDelegator

  def self.wrap(collection)
    collection.map do |obj|
        new obj
    end
  end

  def full_name
    first_name + " " + last_name
  end

end

person1 = Person.new('Joe', 'Hashrocket')
person2 = Person.new('Han', 'Wenbo')
collection = [person1, person2]
decorated_people = PersonDecorator.wrap(collection)
~~~



#### SimpleDecorator 拓展

* `__get_obj__`: return the current object method calls are being delegated to

* `__set_obj__`: We can change the original object decoratin in the same instance of decorator class

~~~ruby
class TicketSeller
  def sellTicket()
    'Here is a ticket'
  end
end


class NoTicketSeller
  def sellTicket()
    'Sorry-come back tomorrow'
  end
end


class TicketOffice < SimpleDelegator
  def initialize
    @seller = TicketSeller.new
    @noseller = NoTicketSeller.new
    super(@seller)
  end
  def allowSales(allow = true)
    __setobj__(allow ? @seller : @noseller)
    allow
  end
end

to = TicketOffice.new
to.sellTicket   		#   "Here is a ticket"
to.allowSales(false)    #   false here we set decoratin object is @noseller
to.sellTicket   		#   "Sorry-come back tomorrow"
to.allowSales(true)     #   true
to.sellTicket   		#  "Here is a ticket"
~~~



装饰器让你可以对现有操作分层，所以它和回调有点像。当回调逻辑仅仅只在某些环境中使用或者将它包含在模型里会给模型增加太多权责，装饰器是很有用的。

给一篇博文加一条评论会触发在某人的 facebook 墙上发一条帖子，但这并不意味着需要将这个逻辑硬编码到 Comment 类。一个你给回调加了太多权责的信号是：测试变得很慢并且很脆弱或者你恨不得将所有不相关的测试屏蔽掉。

这里展示了你如何将 Facebook 发贴的逻辑提取到装饰器里面：

```ruby
class FacebookCommentNotifier
  def initialize(comment)
    @comment = comment
  end

  def save
    @comment.save && post_to_wall
  end

private

  def post_to_wall
    Facebook.post(title: @comment.title, user: @comment.author)
  end
end
```

控制器这样使用：

```ruby
class CommentsController < ApplicationController
  def create
    @comment = FacebookCommentNotifier.new(Comment.new(params[:comment]))

    if @comment.save
      redirect_to blog_path, notice: "Your comment was posted."
    else
      render "new"
    end
  end
end
```

装饰器之所以和服务对象不同，是因为它对权责分层。一旦加上装饰器，使用者就就可将 FacebookCommentNotifier 实例看作 Comment 。

在标准库里面， Ruby 利用元编程提供了很多[工具来构建装饰器](http://robots.thoughtbot.com/post/14825364877/evaluating-alternative-decorator-implementations-in)。

## Observes Objects



## Worker Objects(Job/Worker)

`Worker`实际上也就是我们常说的`Job`(后台任务)。

在Rails中,`Active Job`负责声明作业，在各种队列后端中运行。

作业可以是各种各样，可以是定时任务、账单支付、发送邮件等。

`Active Job`的作用就是确保所有的`Rails`应用都有作业基础设施。这样便可以在此基础上构建各种功能，无需担心不同作业运行程序(Delayed Job/Resque/Sidekiq)的API的差异。

选用哪个队列只是战术问题，切换队列后端也不用重写作业。

我们通常将异步任务置于`workers`或者`jobs`目录下面





## 轻量级应用集群(转载)

为解决复杂的Rails系统产生的一系列问题，我们将单一系统按照业务功能进行划分，每一部分用一个独立的Rails应用来实现，从而形成若干个轻量Rails应用集群，这些应用相互协作，共同实现整体业务逻辑。

拆分后每一个Rails应用具有如下特征：

- 有独立的数据库，可以独立运行；
- 程序代码量比较小，一般情况下只需要一到两个程序员开发与维护；
- 高内聚、低耦合。

系统进行拆分后，需要解决一系列关键的问题，例如：如何保持用户体验的一致性、应用之间如何交互、如何共享用户等。下面将逐一针对这些问题介绍解决方案。

### 用户体验一致性

系统进行拆分后，由若干个轻量级应用共同协作来完成某项业务操作。由于每一个应用都是独立的Rails程序，而一个较为复杂的业务流程可能要在多个应用间跳转，所以首先要解决用户体验的一致性问题。

#### 统一的css框架

用户体验最直观的方面就是页面的样式。为了保证用户在不同的程序间跳转时没有突兀的感觉，每个应用看起来都应该“长的一样”。为达到这一目的，我们采用统一的css框架来控制样式。

在layout里面调用Helper方法：

```
<%= idp_include_js_css %>
```

这将产生以下html代码：

```
<script src ="/assets/javascripts/frame.js" type="text/javascript"></script>
<link href="/assets/stylesheets/frame.css" media="screen" rel="stylesheet" type="text/css" />
```

在frame.css中，会设定好html标签以及如导航等常用结构的样式，应用中的页面只要使用定义好的标签及css类，就可以实现统一风格的界面。

#### 通用客户端组件

拆分后的Rails应用虽然处理的业务逻辑各不相同，但在用户交互上有很多相似的元素，例如查询表单、日历形式显示信息等。把产生这些元素的代码抽象成通用的方法，不仅可以保持用户体验的一致性，更可以减少代码重复，提高开发效率。

例如要产生如下图所示的查询表单，只需要指定待查询的数据库字段以及必要的查询参数即可，具体的实现逻辑封装在`search_form_for`这个Helper方法中。

```
<%= search_form_for(Course, :id, [:price, {:range=>true}], :published, [:created_at, {:ampm=>true}]) %>
```

![img](https://res.infoq.com/articles/rails-app-refactoring/zh/resources/1.png)

### 数据共享与交互

由于每个Rails应用都是整个业务系统的一部分，除了保证用户体验的一致性外，还需要解决程序间的数据交互与共享问题。下面我们以一个简单的例子来说明如何实现。

#### 示例程序

示例程序是一个简单的在线学习系统，用户在线购买和学习课程。按照业务逻辑将系统拆分成四个应用，分别用于课程信息管理（course）、用户注册登录及帐号管理（user）、订单系统（purchase）以及在线学习系统（learning）。这几个Rails应用中各自业务的实现比较简单，不再赘述。

![img](https://res.infoq.com/articles/rails-app-refactoring/zh/resources/2.png)

#### 只读数据库

在示例程序中，用户需要购买课程后才能开始学习。由于我们对系统进行了拆分，订单和课程在两个不同的应用中进行管理，而用户下定单时需要查看课程列表，这就涉及到一个应用（purchase）如何获取另一个应用（course）数据的问题。

最直观的做法是course提供一个service，purchase调用这个service来取得课程列表。但service调用效率比较低，代码处理也比较复杂，所以应该尽量避免使用。我们仔细分析一下这个需求就会发现，在purchase显示的课程列表逻辑上很简单，只需要知道课程的名称、价格等基本属性就足够了，所以可以考虑直接从数据库读取这些信息。

由于系统拆分后每个应用都有独立的数据库，所以我们需要给purchase中的Model类设定指向course的数据库连接。代码如下：

```
# purchase: /app/models/course_package.rb:
class CoursePackage < ActiveRecord::Base 
  acts_as_readonly :course 
end 
```

这样CoursePackage除了数据库指向不同外，其他和普通的Model一样。

```
# purchase: /app/views/orders/new.erb.html
<ul>
<% CoursePackage.all.each do |package| %>
    <li><%= package.title %> <%= package.price %></li>
<% end %>
</ul>
```

通过`acts_as_readonly`这个方法，可以让purchase的类CoursePackage从course数据库中读取数据。需要注意的是，为了保证数据维护的一致性，CoursePackage的数据库连接是只读的，这样可以避免数据在多个应用中被修改。

`acts_as_readonly`的核心实现如下(限于篇幅，设置连接为只读等代码并未列出)：

```
def acts_as_readonly(app_name, options = {})
  config = CoreService.app(app_name).database
  establish_connection(config[Rails.env])
  set_table_name(self.connection.current_database + "." + table_name)
end
```

app_name是每个应用在集群中的唯一标识。purchase通过CoreService来获取course的数据库配置并设置连接。那么，CoreService向什么地方发送请求，又是如何知道course的配置信息呢？

在应用集群中，为了降低应用间的耦合性，我们采用集中式的配置管理。选择某一个应用作为core，其他应用在server启动时将自己的配置信息发送到core集中存储。例如我们在示例程序中选择user做为core应用，purchase需要查询course的配置时，就通过CoreService向user发送请求，user根据名称查询出course包括数据库在内的所有配置信息，并返回给purchase。交互过程如下图所示：

![img](https://res.infoq.com/articles/rails-app-refactoring/zh/resources/3.png)

采用集中式的配置管理后，应用之间的调用都通过core来进行，这样就把应用之间的交互由网状结构变成以core为中心的星型结构，降低了系统配置管理的复杂度。

应用程序的配置信息保存在config/app_config.yml中，示例如下：

```
app: course #名称，应用在系统中的唯一标识
url: example.com/course #url
api:
  course_list: package/courses
```

从上文可以看出，通过只读数据库，我们可以完全无缝地读取其他应用的数据，并且代码非常简单明了，并没有增加应用间的耦合性。

只读数据库适应于业务逻辑比较简单的数据读取，如果数据需要预先进行复杂的操作，就无法简单地通过只读数据库取得数据。另一方面，应用间有时候确实需要进行一些写操作，这时候就需要借助于其他手段了。

#### Web Service

示例程序中，用户在purchase成功购买课程后，需要在learning这个应用中激活课程。这个过程可以通过Web Service来实现，由learning提供service接口，purchase调用这个接口并传递必要的参数。

Rails程序一般通过ActiveResource来简化service的开发，learning中提供服务的Controller代码示例如下：

```
# learning: app/controllers/roadmap_services_Controller.rb
def create
  Roadmap.generate(params[:roadmap_service])
end
```

purchase通过RoadmapService来调用learning的service接口。

```
# purchase: app/models/roadmap_service.rb 
class RoadmapService < ActiveResource::Base
  self.site = :learning
end

RoadmapService.create(params)
```

我们对`ActiveResource::Base`类的`site=`方法进行了扩展，这样只需要指定提供service的应用名称（learning）就可以找到service的url。实现的原理仍然是通过向core发送请求，查询应用的url。

#### DRY

以上介绍了如何保持用户体验的一致性以及应用间如何交互，我们可以看到这些功能的实现方法与应用的业务逻辑并不相关，属于“框架支持代码”，所以为了避免代码重复并且进一步简化开发，我们把这些方法封装到gem里面，这样每个Rails应用只需要引用这个gem，就可以无缝地集成到框架中来，并且可以使用gem里面包装好的一系列方法。

我们已经将数据共享部分的核心代码开源，文中一些省略的代码（如`acts_as_readonly`）也可以在此处找到，具体可参见<http://github.com/idapted/eco_apps>。

### 用户及权限控制

除了数据交互外，另一个重要问题是用户的管理，包括系统登录、权限控制等方面。示例程序中，我们用user这个应用来管理用户信息。

#### 单点登录

在应用集群中，用户登录某一个应用后，再访问其他应用时应该不需要再次验证，这就需要实现多个应用间的单点登录。

实现单点登录有很多方法，我们采取一种非常简单的方式，就是多个应用共享session。代码如下：

```
# config/initializers/idp_initializer.rb 
ActionController::Base.session_store = :active_record_store 
ActiveRecord::SessionStore::Session.acts_as_remote :user, :readonly => false
```

在initializer中指定所有应用都用user的sessions表存储session数据。当然也可以使用其他session存储方式，例如memcache等，只要保证所有应用的设置都一样即可。

#### 权限控制

我们采用基于角色的权限管理来控制对应用程序的访问，并且在core应用中集中管理。应用中每一个Controller作为一个权限控制节点，在server启动时，像配置信息一样，各个应用将自己的Controller结构发送到core，由core统一管理与配置。如下图所示：

![img](https://res.infoq.com/articles/rails-app-refactoring/zh/resources/4.png)

从示例程序可以看出，将大系统拆分成小应用是基于业务来进行的，每一个应用处理一套功能上接近的、完整的业务逻辑。而每一个小应用Controller的结构，对于有多种角色的系统来说，应该按照角色来组织，这样可以有比较清晰的结构。Controller做为节点的方案也在一定程度上强迫开发者按照角色设计良好的Controller结构。

#### 辅助系统

除了统一的UI、数据交互和用户共享外，还可以把一些常用的功能如上传附件、发送邮件等抽象出来，在更高级别上减少重复代码。

由于这些功能比较复杂，不像UI Helper等用简单的一两个方法就可以完成，所以我们用独立应用和对应的gem相结合来实现。

以发送邮件功能为例，首先创建一个Rails应用mail，主要功能包括管理邮件模版、统计发送数量、完成邮件发送等；然后创建一个gem，在这个gem中包含MailService，其他应用引用这个gem后就可以调用MailService的相关方法完成邮件发送。例如：

```
MailService.send(:welcome_mail, "customer@example.com", :username=>"张三")
```

## 架构优势及系统拆分原则

### 小应用集群架构的优势

我们在第一部分已经详细说明了复杂Rails系统的种种弊端，将大系统拆分成小应用集群后，可以从根本上解决这些问题，并且还可以带来许多其他好处。