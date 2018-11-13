---
layout: post
toc: true
permalink: /api-good-part
title: api good part
tags: api rails
desc: 本篇文章着重从Rails构建API的角度来聊聊如何构建优雅而且可维护性强的API


---



## 什么是Web API

> Application Programming Interface: 软件组件的外部接口

对于某个软件集合体，人们能了解它的外部功能，但无需知道其内部的运作细节。

为了从外部调用该功能，需要制定该软件集合体的调用规范等信息，这种规范就是API。

对于Web API而言，其实就是一个Web系统，我们可以通过URL与服务器完成信息交互。



## Rails开发API



### 开发API的流程

一个API其实主要包括三个部分:

* 请求参数的校验(包括业务相关的校验)
* 逻辑处理
* 数据返回

很多初学者使用`Ruby on Rails`开发时，都会将所有的校验逻辑和处理逻辑放在`Controller`中。

当项目越来越大的时候，我们就会发现`Controller`变得愈发臃肿。

当我重构代码时，我会尽量保证`controller`部分的代码足够精简，一般不会超过十行。

每个请求如果按照上述的三个部分来展开的话非常好处理。

下面我也主要通过上述三个模块来阐述一下 Rails开发API的规范。

#### 请求参数的校验

一个请求过来，我们首先想到的是参数的校验:

* 参数的存在性
* 参数与参数之间是否存在互斥，包含等关系
* 参数是否可选

与此同时，还存在一些与我们具体业务逻辑密切相关的校验:

*  转账时用户的余额是否足够
* 体现时该用户是否可以体现
* 下单时用户是否需要输入资金密码，资金密码是否正确

这种虽然与请求参数没有直接关系，但是在API开发时，应该先于具体的业务逻辑进行的必不可少的校验。

我们以交易所用户体现为例:

~~~ruby
# withdraw polymerization api
desc 'create withdraw record'
params do
  requires :type, values: %w[internal external private_transfer]
  use :create_withdraw_params
end
post '/funds/withdraws' do
  before_create_withdraw(params[:type])
  create_withdraw(params[:type])
end
~~~

当一个用户提现时，会触发API `api/funds/withdraws/`。

在进行具体的提现操作之前，我们需要进行必要的校验

1. 请求参数的校验:

~~~ruby
params :create_withdraw_params do
  requires :currency, type: String, allow_blank: false
  requires :amount, type: String, allow_blank: false
  requires :fund_source_id, type: String, allow_blank: false
  requires :two_factor_type, type: String, allow_blank: false, values: %w[sms app]
  requires :otp, type: String, allow_blank: false
  optional :memo, type: String, allow_blank: true
  optional :email_otp, type: String, allow_blank: true
  optional :fund_password, type: String, allow_blank: true
end
~~~

上述的校验是集成在`grape gem`中完成的，我认为这也是我喜欢使用`grape`写API的原因之一:它可以对请求的参数进行全面的校验.

需要注意一点，`grape`校验参数返回的信息应该是面向开发者而不是普通用户的，比如说请求中遗漏了一个必需的参数

~~~

~~~

看到上述信息，开发者就会在各种端设备对请求的参数做校验，保证请求的参数都符合我们的规范.



2. 业务相关的校验:

before_create_withdraw`:



~~~ruby
def before_create_withdraw(withdraw_type)
  check_fund_source(withdraw_type)          # 验证提现地址是否正确
  check_current_user_withdrawable           # 当前用户是否可以提现
  check_currency_withdraw                   # 当前币种是否可以提现
  check_delay_withdraw                      # 是否存在延迟提现
  check_kyc1                                # 是否通过 KYC level1 验证
  check_fund_password({ kind: :withdraw })  # 验证资金密码
  check_withdraw_two_factors                # 提现相关的二次验证 [放在最后验证]
end
~~~

业务相关的校验，我们是通过定义对于的`check_`方法来实现,以`check_current_user_withdrawable`为例:

~~~ruby
def check_current_user_withdrawable
    if !current_user.allow_withdraw || current_user.disabled
      raise Errors::Funds::MemberWithdrawForbiddenError 
    end
end

~~~

如果校验不通过，我们会`raise`一个业务相关的错误，此错误信息是面向开发者和普通用户的:

~~~

~~~

其中`code`为我们业务相关的自定义`code`码，与`http status code`无任何关联。

`message`为友好的提示信息，指引开发者或用户进行下一步的操作。



### 逻辑处理

API核心部分就是我们的业务相关的逻辑处理。

如果更好的抽象这部分的功能，将决定我们的API可维护性和可阅读性。

一般有以下几种处理方式:

#### 简单的业务处理



#### `创建`表单

`Form Object`可以帮助我们创建一个`record`,同时简化我们的`model`.以用户注册为例，当一个新用户在我们的网站注册时，我们需要在`models/user`中添加各种`attributes`的校验。

通过`Form Object`我们可以将其都转移到	`Form Object`中从而简化我们的`user`(一般来说用户模式是一个系统中最为复杂的模型之一):

~~~ruby
# frozen_string_literal: true

# User Story
# 这里是 [用户注册]的表单
require "#{Rails.root}/app/models/two_factor/email.rb"
require "#{Rails.root}/app/models/two_factor/sms.rb"

# 注册之后绑定对应的二次验证
# 绑定操作会触发延迟提现

class MemberForm
  REQUESTED_SCOPES = "profile history trade"

  # @param :scope                    Oauth scope
  # @param :client_id                Oauth client
  # @param :client_secret            Oauth client secret
  # @param :password                 密码
  # @param :password_confirmation    密码确认
  # @param :otp                      验证码
  # @param :email                    邮箱
  # @param :country                  国家(手机号)
  # @param :phone_number             手机号码
  # @param :refer                    推荐人ID(sn)

  attr_reader :scope, :client_id, :client_secret
  attr_reader :password, :password_confirmation, :email, :country, :phone_number, :refer
  attr_reader :member, :oauth_app, :error, :message

  def initialize(params)
    params.each_pair do |key, value|
      instance_variable_set("@#{key}", value)
    end
    @oauth_app = Doorkeeper::Application.find_by({ uid: client_id, secret: client_secret })
  end

  def run
    ActiveRecord::Base.transaction do
      create_identity
      create_member
      active_two_factor
      add_refer
      create_access_token
    end
    self
  rescue StandardError => exception
    fail!(exception.message)
    self
  end

  def success?
    @error.nil?
  end

  private

  def create_identity
    identity_params = {}
    identity_params[:password] = password
    identity_params[:password_confirmation] = password_confirmation
    identity_params[:phone_number] = phone_number if phone_number.present?
    identity_params[:email] = email if email.present?
    @identity = Identity.create!(identity_params)
  end

  def create_member
    member_params = {}
    member_params[:phone_number] = TwoFactor::Sms.phone_number(country, phone_number) if phone_number.present?
    member_params[:email] = email if email.present?
    member_params[:activated] = true # 用户已激活
    @member = Member.create!(member_params)
    @member.create_auth_for_identity(@identity)
  end

  # 激活二次验证之前需要确保二次验证已绑定
  # 激活之后需要触发延迟提现
  def active_two_factor
    if phone_number.present?
      sms_two_factor = @member.sms_two_factor
      sms_two_factor.update_columns(type_value: phone_number)
      sms_two_factor.active!
      DelayWithdraw.trigger(member.id, :phone_binding)
    end
    if email.present?
      email_two_factor = @member.email_two_factor
      email_two_factor.update_columns(type_value: email)
      email_two_factor.active!
      DelayWithdraw.trigger(member.id, :email_binding)
    end
  end

  def add_refer
    return unless refer.present?
    refer_member = Member.find_by_sn(refer)
    @member.add_refer(refer_member.id)
  end

  def create_access_token
    scopes ||= REQUESTED_SCOPES
    api_token = @member.api_tokens.create!(label: oauth_app.name, scopes: scopes)
    access_token = Doorkeeper::AccessToken.create!(
      application_id: oauth_app.id,
      resource_owner_id: @member.id,
      scopes: scopes,
      token: api_token.to_oauth_token,
      expires_in: 1.week
    )
    # 这里返回APP端登录需要的 `access_token`
    @message = Doorkeeper::OAuth::TokenResponse.new(access_token).body
  end

  def fail!(error)
    @error = error
  end
end

~~~



在我们的API层，我们就可以将所有的注册逻辑放在 `MemberForm`中了:

~~~ruby
# 1. create member
params do
  use :member_signup_params
end
post '/users/signup' do
  before_build_member
  create_member
end

def create_member
  @result = ::MemberForm.new(params).run
  if @result.success?
    login
    present({ data: @result.message })
  else
    raise Errors::Users::SignupError, @result.error
  end
end

def login
  session[:current_user_id] = @result.member.id # 保存登录状态
end
~~~

错误处理方面，因为我们在API前验过程就过滤了绝大部分的参数和逻辑异常，这么只会捕获我们前验未校验的异常，然后保存到`form`实例变量中。

#### Services

当我们的API业务逻辑涉及到多个模型之间的变动时，此时如果在使用之前`controller`中的处理方式，代码中就会充斥很多`callback`。我们将这种复杂的逻辑抽象成一个`service`,所有的事情都会变得可维护:

~~~ruby
# frozen_string_literal: true

# User Story
# 这里是创建提现记录的 Service
# withdraw_type:
# internal:         内部转账
# external:         外部提现
# private_transfer: 锁定转账
module Funds
  class CreateWithdrawService
    # Transfer currency directly between accounts
    # @param current_user [Member]     发起方
    # @param params [Hash]            参数
    # requires :currency, type: String
    # requires :amount, type: String
    # requires :fund_source_id, type: String
    # optional :memo, type: String
    # @param withdraw_type [String]  : internal[内部转账] external[外部提现] private_transfer[锁定转账]

    INTERNAL = 'internal'
    EXTERNAL = 'external'
    PRIVATE_TRANSFER = 'private_transfer'

    attr_reader :current_user, :params, :withdraw_type, :fund_source, :currency, :amount, :memo, :error

    def initialize(current_user, params, withdraw_type)
      @current_user = current_user
      @params = params
      @withdraw_type = withdraw_type
      @fund_source = current_user.fund_sources.find_by(id: params[:fund_source_id])
      @currency = params[:currency]
      @amount = params[:amount]
      @memo = params[:memo]
    end

    def run
      create_withdraw
      self
    rescue StandardError => exception
      fail!(exception.message)
      self
    end

    def success?
      @error.nil?
    end

    private

    def create_withdraw
      case withdraw_type
      when INTERNAL
        create_internal_withdraw
      when EXTERNAL
        create_external_withdraw
      when PRIVATE_TRANSFER
        create_private_transfer_withdraw
      end
    end

    def create_internal_withdraw
      ::Funds::InternalWithdraw.new(current_user, fund_source, currency, amount).run
    end

    def create_external_withdraw
      ::Funds::ExternalWithdraw.new(current_user, fund_source, currency, amount, memo).run
    end

    def create_private_transfer_withdraw
      ::Funds::PrivateTransferWithdraw.new(current_user, fund_source, currency, amount).run
    end

    def fail!(error)
      @error = error
    end
  end
end

~~~



~~~ruby
# frozen_string_literal: true

# User Story
# 这里是创建 外部提现 记录 Service
module Funds
  class ExternalWithdraw
    # Transfer currency directly between accounts
    # @param source_member [Member]    发起方
    # @param fund_source [FundSource]  转账渠道
    # @param currency [String]         货币类型
    # @param amount [Float]            转帐数量

    attr_reader :source_member, :fund_source, :currency, :amount, :memo

    def initialize(source_member, fund_source, currency, amount, memo)
      @source_member = source_member
      @fund_source = fund_source
      @currency = currency
      @amount = amount
      @memo = memo.strip if memo.present?
    end

    def run
      build_withdraw
      if @withdraw.valid?
        do_submit!
      else
        raise StandardError, @withdraw.errors.full_messages.join(', ')
      end
    end

    private

    def build_withdraw
      @withdraw = source_member.withdraws.create(build_withdraw_params)
    end

    def do_submit!
      @withdraw.with_lock do
        @withdraw.submit!
      end
    end

    def build_withdraw_params
      account = source_member.get_account(currency)
      channel = account.withdraw_channel
      find_or_load_withdraw_class(channel.key)
      {
        type: "Withdraws::#{channel.key.capitalize}",
        account: account,
        currency: currency,
        fund_source: fund_source,
        sum: amount,
        memo: memo
      }
    end

    def find_or_load_withdraw_class(key)
      Withdraws.get_class(key)
    end
  end
end

~~~



### 返回数据

通过使用`Serializer`或者`Presenter`,我们可以将我们API的返回数据结构和`model`或者`controller`层面剥离开。



```ruby
# frozen_string_literal: true

module APIv2
  module Entities
    class Withdraw < Base
      expose :id, documentation: "Unique withdraw id."
      expose :currency
      expose :amount, format_with: :decimal
      expose :fee
      expose :txid
      expose :fund_uid
      expose :created_at, format_with: :iso8601
      expose :done_at, format_with: :iso8601
      expose :aasm_state, as: :state
      expose :state_text do |d| d.aasm_state end
      expose :txid_link

      def txid_link
        return if object.is_a?(Withdraws::Transfer) || object.is_a?(Withdraws::PrivateTransfer)
        object.currency_obj.blockchain_url(object.txid)
      end
    end
  end
end

```





## Grape 最佳实践



### 参数校验

通过`grape`开发API时，我们可以充分利用`grape`提供的参数校验，从源头保证API的稳健性。

~~~ruby
# 用户注册时的参数和校验
params :member_signup_params do
    requires :client_id, allow_blank: false
    requires :client_secret, allow_blank: false
    requires :password, allow_blank: false
    requires :password_confirmation, allow_blank: false
    requires :otp, allow_blank: false
    optional :email
    optional :country
    optional :phone_number
    optional :refer
    exactly_one_of :email, :phone_number
    all_or_none_of :country, :phone_number
end

~~~



### Helpers

`grape`一个特点或者说是不太好的地方是不能直接在`api_endpoint`中定义`method`,我们只能通过`helpers`来定义`method`.

我们可以通过`helper`后面挂在的代码块来定义`helper method`，或者在`module`中定义`helper methods`,然后通过`helpers`加载到当前`class`上。

~~~ruby
module StatusHelpers
  def user_info(user)
    "#{user} has statused #{user.statuses} status(s)"
  end
end

module HttpCodesHelpers
  def unauthorized
    401
  end
end

class API < Grape::API
  # define helpers with a block
  helpers do
    def current_user
      User.find(params[:user_id])
    end
  end

  # or mix in an array of modules
  helpers StatusHelpers, HttpCodesHelpers

  before do
    error!('Access Denied', unauthorized) unless current_user
  end

  get 'info' do
    # helpers available in your endpoint and filters
    user_info(current_user)
  end
end
~~~

`helpers`还可以定义参数,这样很多通用的参数形式或者复杂的参数列表我们就可以单独定义在文件中,保证我们的API端的简洁性.

~~~ruby
class API < Grape::API
  helpers do
    params :pagination do
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
  end

  desc 'Get collection'
  params do
    use :pagination # aliases: includes, use_scope
  end
  get do
    Collection.page(params[:page]).per(params[:per_page])
  end
end
~~~

`helpers`还可以传入参数进行参数设置.

~~~ruby
# Helpers support blocks that can help set default values. 
# The following API can return a collection sorted by id or created_at in asc or desc order.

module SharedParams
  extend Grape::API::Helpers

  params :order do |options|
    optional :order_by, type: Symbol, values: options[:order_by], default: options[:default_order_by]
    optional :order, type: Symbol, values: %i(asc desc), default: options[:default_order]
  end
end

class API < Grape::API
  helpers SharedParams

  desc 'Get a sorted collection.'
  params do
    use :order, order_by: %i(id created_at), default_order_by: :created_at, default_order: :asc
  end

  get do
    Collection.send(params[:order], params[:order_by])
  end
end
~~~



#### Grape::API::Helpers

我们只有在定义可复用的`params helper`的时候才会将`Grape::API::Helpers`加入到我们的`module`中:

~~~ruby
module API
  module Helpers
    module Users
      module SendOtpHelper
        extend ::Grape::API::Helpers
        params :send_otp_before_binding_params do
          requires :two_factor_type, type: String, values: %w[email sms app], allow_blank: false
          optional :email
          optional :country
          optional :phone_number
          all_or_none_of :country, :phone_number
          exactly_one_of :email, :phone_number
        end

        params :send_otp_activated_params do
          requires :two_factor_type, type: String, values: %w[sms email], default: 'sms'
        end
      end
    end
  end
end
~~~



### Concern

除了定义`helpers`，我们还可以使用`Rails`自带的`ActiveSupport::Concern`来扩展我们的`helpers`:

~~~ruby
module API
  module MilestoneResponses
    extend ActiveSupport::Concern

    included do
      helpers do
        params :optional_params do
          optional :description, type: String, desc: 'The description of the milestone'
          optional :due_date, type: String, desc: 'The due date of the milestone. The ISO 8601 date format (%Y-%m-%d)'
          optional :start_date, type: String, desc: 'The start date of the milestone. The ISO 8601 date format (%Y-%m-%d)'
        end

        params :list_params do
          optional :state, type: String, values: %w[active closed all], default: 'all',
                           desc: 'Return "active", "closed", or "all" milestones'
          optional :iids, type: Array[Integer], desc: 'The IIDs of the milestones'
          optional :search, type: String, desc: 'The search criteria for the title or description of the milestone'
          use :pagination
        end

        params :update_params do
          requires :milestone_id, type: Integer, desc: 'The milestone ID number'
          optional :title, type: String, desc: 'The title of the milestone'
          optional :state_event, type: String, values: %w[close activate],
                                 desc: 'The state event of the milestone '
          use :optional_params
          at_least_one_of :title, :description, :start_date, :due_date, :state_event
        end

        def list_milestones_for(parent)
          milestones = parent.milestones.order_id_desc
          milestones = Milestone.filter_by_state(milestones, params[:state])
          milestones = filter_by_iid(milestones, params[:iids]) if params[:iids].present?
          milestones = filter_by_search(milestones, params[:search]) if params[:search]

          present paginate(milestones), with: Entities::Milestone
        end

        def get_milestone_for(parent)
          milestone = parent.milestones.find(params[:milestone_id])
          present milestone, with: Entities::Milestone
        end

        def create_milestone_for(parent)
          milestone = ::Milestones::CreateService.new(parent, current_user, declared_params).execute

          if milestone.valid?
            present milestone, with: Entities::Milestone
          else
            render_api_error!("Failed to create milestone #{milestone.errors.messages}", 400)
          end
        end

        def update_milestone_for(parent)
          milestone = parent.milestones.find(params.delete(:milestone_id))

          milestone_params = declared_params(include_missing: false)
          milestone = ::Milestones::UpdateService.new(parent, current_user, milestone_params).execute(milestone)

          if milestone.valid?
            present milestone, with: Entities::Milestone
          else
            render_api_error!("Failed to update milestone #{milestone.errors.messages}", 400)
          end
        end

        def milestone_issuables_for(parent, type)
          milestone = parent.milestones.find(params[:milestone_id])

          finder_klass, entity = get_finder_and_entity(type)

          params = build_finder_params(milestone, parent)

          issuables = finder_klass.new(current_user, params).execute
          present paginate(issuables), with: entity, current_user: current_user
        end

        def build_finder_params(milestone, parent)
          finder_params = { milestone_title: milestone.title, sort: 'label_priority' }

          if parent.is_a?(Group)
            finder_params.merge(group_id: parent.id)
          else
            finder_params.merge(project_id: parent.id)
          end
        end

        def get_finder_and_entity(type)
          if type == :issue
            [IssuesFinder, Entities::IssueBasic]
          else
            [MergeRequestsFinder, Entities::MergeRequestBasic]
          end
        end
      end
    end
  end
end

~~~



我们在需要使用的使用直接`include`进来即可,无需进行额外的操作.因为`include`进来之后，就相当于在当前文件中使用`helpers do ... end`,所以可以在`module`中定义`params`.

~~~ruby
module API
  class GroupMilestones < Grape::API
    include MilestoneResponses
    include PaginationParams

    before do
      authenticate!
    end
  end
end
~~~



### Mount

我们最好不要将所有的`endpoint`都塞到`api.rb`文件中，这样会导致我们的`api.rb`愈发膨胀。

借鉴`route.rb`的做法，我们可以定义一个`draw method`,将所有的`endpoint`都定义在`mount/:version.rb`中:

~~~ruby
def self.draw(version)
  instance_eval(File.read(Rails.root.join("lib/api/mounts/#{version}.rb")))
end

# draw version splitly
# we should only draw web and version
draw :web
draw :v2
draw :v3
~~~

~~~ruby
# frozen_string_literal: true

# 这里是 api version 3
version 'v3', using: :path do
  # helpers
  helpers ::API::V3::NamedParams
  helpers ::API::V3::Helpers

  # Keep in alphabetical order
  # Common     通用资源
  mount ::API::V3::Common::Articles
  mount ::API::V3::Common::Currencies
  mount ::API::V3::Common::CurrencyInfos
  mount ::API::V3::Common::Geetest
  mount ::API::V3::Common::Markets
  mount ::API::V3::Common::ApplicationSettings
  
  # Exchange 币币交易
  mount ::API::V3::Exchange::MarketQuotes
  mount ::API::V3::Exchange::OrderBooks
  mount ::API::V3::Exchange::Orders
  mount ::API::V3::Exchange::Trades

  # Funds 资产相关
  mount ::API::V3::Funds::Deposits
  mount ::API::V3::Funds::FundPasswords
  mount ::API::V3::Funds::FundSources
  mount ::API::V3::Funds::Withdraws

  # Otc  法币交易 [Over the Counter]
  mount ::API::V3::Otc::OtcMarkets
  mount ::API::V3::Otc::OtcMerchants
  mount ::API::V3::Otc::OtcOrders
  mount ::API::V3::Otc::OtcPaymentChannels
  # Stream   推送相关
  mount ::API::V3::Stream::Pusher
  # Users    用户相关
  mount ::API::V3::Users::Accounts
  mount ::API::V3::Users::APITokens
  mount ::API::V3::Users::FundPasswords
  mount ::API::V3::Users::IdDocument
  mount ::API::V3::Users::LoginHistories
  mount ::API::V3::Users::MarketFavors
  mount ::API::V3::Users::Members
  mount ::API::V3::Users::Referrees
  mount ::API::V3::Users::ResetPassword
  mount ::API::V3::Users::Signup
  mount ::API::V3::Users::Trades
  mount ::API::V3::Users::TwoFactors
end

~~~



### Params Eager load

如果指定传入的参数有一个变化的默认值，需要将其定义在`lambda`中，否则每次请求的默认值都是一样的。

```ruby
params do
  optional :random_number, type: Integer, default: -> { Random.rand(1..100) }
  optional :non_random_number, type: Integer, default:  Random.rand(1..100)
end
```

**Default values are eagerly evaluated**. Above `:non_random_number` will evaluate to the same number for each call to the endpoint of this `params` block. To have the default evaluate lazily with each request use a lambda, like `:random_number`above.

~~~ruby
params do
    requires :message,   type: String,   desc: 'Message to display'
    optional :starts_at, type: DateTime, desc: 'Starting time', default: -> { Time.zone.now }
    optional :ends_at,   type: DateTime, desc: 'Ending time',   default: -> { 1.hour.from_now }
    optional :color,     type: String,   desc: 'Background color'
    optional :font,      type: String,   desc: 'Foreground color'
  end
~~~

