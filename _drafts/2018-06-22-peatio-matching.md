---
layout: post
toc: true
permalink: /digital-cryptocurrency-matching
title: 数字加密货币撮合交易系统
tags: Peatio Cryptocurrency Matching
desc: 一个高端的数字货币交易平台离不开的重点那就是'撮合交易'的运用,撮合交易打破传统交易模式,在数字货币交易系统中尤为重要,可以大大的提高交易速度和质量,能够把撮合交易系统的的非常完善就需要一个好的数字货币系统开发公司.本篇文章就以开源的数字货币交易系统 peatio 为例来深入研究数字货币撮合系统的架构和实现.  
---

数字交易系统是数字货币市场上能够提供的最有流动性,效率最高的交易场所.和传统的金融证券交易不同的是,数字交易系统提供的买卖标的物是标准的数字化资产,如BTC、ETH、USDT等,它们的特点是数字计价,可分割买卖.

数字交易系统通过买卖双方各自的报价,按照价格优先、时间优先的顺序,对买卖双方进行撮合,实现每秒成千上万的交易量,可以为市场提供高度的流动性和价格发现机制.

本文通过对开源数字交易平台 [`peatio`](https://github.com/peatio/peatio)架构分析， 来让更多的开发者熟悉数字货币交易平台的开发与学习。


## 撮合系统架构

### 撮合交易简介 Match

#### 撮合原则

`peatio`交易所和大多数的交易平台类似, 都是遵从 **价格优先, 时间优先** 的原则.

* 价格优先: 以买方为例子,就是谁出的价格高,谁就优先与卖方撮合.
* 时间优先: 就是是相同的出价下, 谁报单早,谁就优先被撮合.

#### 挂单分类
挂单一般分为限价单和市价单

##### limit_order
一种以等同或者低于指定价格买进特定数量数字货币的委托单， 或者以等同或高于指定价格(一般称之为限定价格)卖出数字货币的委托单。

举个例子说明一下.

限价单主要有四个信息,方向（买还是卖）,市场交易对（BTC/ETH）,数量（500个）, 相对价格（30）.

当市场有很多你样的'挂单者'的时候, 就形成了orderbook

* 卖3 10.02   2000
* 卖2 10.01  8000
* 卖1 10.00   3200
* 买1  9.98    2800
* 买2  9.96    800
* 买2 9.95     500

买1一定小于卖1,不然交易所就直接撮合成交了.

这些挂单者为市场提供了流动性.


##### market_order

以市场价买进或者卖出股票的委托单。 成交价格通常等同或者接近下单时的报价， 主要视成交速度和交易所活跃度而定。


其他的投资者可以下`市价单`或者挂有交叉价格的`限价单（cross ）`来立马买入. 比如投资者下个市价单, 买入700股`BTC/ETH`（注意,市价单不用说价格）, 那么这挂着的3200股`BTC/ETH`就会有700股以10块钱的价格成交.

如果投资者下个市价单,买入3500股`BTC/ETH`. 那么,会有3200股以10块钱成交,余下300股以10.02成交.  Orderbook就会变成如下的样子

* 卖1 10.02   1700
* 买1  9.98    2800
* 买2  9.96    800...

如果投资者挂500股以9.99块钱的限价单,那么不好意思,成交不了, 但是他的报单会成为新的买1, 并且比9.98的买家有更高的优先级等待别人成交. 如果投资者特意挂了超过卖1价格的买单限价单（如果交易所允许）,比如买入800股 10块钱,那么也会立刻成交.

##### 其他 挂单类型

* FAK: fill and kill
* FOK: fill or kill.

1. 你看到市场有人挂单要以10块买入500股`BTC/ETH`, 你下一个10块钱买入4000股的`FAK`单.那么这个单会买入500股（fill）的同时, 撤掉另外3500股的单（kill）. 
2. 如果你下的是FOK单, 因为你没法全部成交买到4000股（fill）,所以马上就撤单（kill）.



#### 交易系统简化流程

我们以一个美元计价的数字货币交易所为例， 实现一个`ETH`的`EHT/USDT`交易系统。

一个完整的数字货币交易系统是由用户系统、账户系统、挂单系统、撮合系统以及清算系统等子系统构成。

每个子系统相互配置， 完成数字货币报价交易。

```
           1  ┌───────────┐  2  ┌───────────┐  7  ┌───────────┐
Request  ────>│   User    │────>│  Account  │<────│ Clearing  │
              └───────────┘     └───────────┘     └───────────┘
                                     3│                 ▲
                                      ▼                 │
                                ┌───────────┐           │
                                │   Order   │          6│
                                └───────────┘           │
                                     4│                 │
                                      ▼                 │
                                ┌───────────┐  5  ┌───────────┐
                                │ Sequence  │────>│   Match   │
                                └───────────┘     └───────────┘
                                                        │
                                                        ▼
                                                  ┌───────────┐
Market   <────────────────────────────────────────│ Quotation │
                                                  └───────────┘
```



当一个挂单请求进入交易系统后，首先由用户系统（User）识别用户身份，然后由账户系统（Account）对用户资产进行冻结，买入冻结USD，卖出冻结`ETH`，冻结如果成功，订单就进入定序系统（Sequence）。

为什么需要定序系统呢？因为交易系统的所有订单是一个有序队列。不同的用户在同一时刻下单， 也必须由定序系统确定先后顺序， 只有这样后续的撮合才有条件使用`价格优先、时间优先`的准则。

经过定序的订单被送往撮合引擎`Matching`.

撮合引擎是交易系统的核心。 撮合引擎本质就是一个维护买卖盘列表/委托单列表(OrderBook)， 然后按照**价格优先原则** 对订单进行撮合， 能够成交的就输出成交结果， 不能成交的就放入买卖盘/委托单列表(OrderBook). 这里需要注意的是无需关注时间优先原则， 因为经过定序的订单队列已经是一个时间优先的队列了。

当撮合引擎输出了成交结果后， 该成交记录由清算系统(Clearing)进行清算。 清算的工作就是把买单冻结的`USDT`扣除， 并加上买入所得的`ETH`；同时把卖单冻结的`ETH`扣除， 并加上卖出所得的`USDT`.根据`taker/maker`的费率， 向买卖双方收取手续费。

清算系统完成清算后， 更新订单的状态；通知用户， 用户就可以查询买卖的成交情况。

在撮合引擎输出成交记录给清算系统时， 它还把去用户和订单信息的成交记录输出给行情系统(Quotation),由行情系统保存市场的成交价， 成交量等信息， 并输出实时价格、K线图等技术数据， 以便公开市场查询。

经过这样的一个简化版的模块设计， 一个数字货币交易系统就具备了雏形。

本文分析的开源数字货币交易平台`peatio`的大体思路和上述的模型基本一致， 不过在架构层面更为复杂和精妙。



#### 其他概念



##### 市场深度 Depth

简单来说， 深度是指某个价位上的挂单数量。

`depth`



![img](http://bjiebtc.com/wp-content/uploads/2018/01/shendu0.png)



市场深度是指市场在承受大额交易时比特币的价格不出现大幅波动。

![img](http://bjiebtc.com/wp-content/uploads/2018/01/shendu.png)



如上图所示， 如果你想快速完成100个比特币交易。

在交易所A： 你需要以10000的价格购买20个，以10100的价格购买20个，以10200的价格购买20个，以10500的价格购买20个，以10800的价格购买20个。

你的总成本就是：10000*20+10100*20+10200*20+10500*20+10800*20=1,032,000（比交易所贵了32,000）

购买后，交易所里的价格被推高到10800.

在交易所B： 你需要以10000的价格购买100个.

你的总成本就是：10000*100=1,000,000

购买后，交易所里的价格任然是10000.



**一般选择市场深度好的交易所**

* 大额交易时市价相对稳定
* 大额交易的成本更低



好了， 以上都是一些开胃菜， 下面我们就从模型开始一步步揭开数字交易系统的面纱。



### 数据模型 Model

交易系统使用的数据表并不是很多，这里我就拿出最核心的几个模块来解读一下。



#### Account 账户

~~~ruby
create_table "accounts", force: true do |t|
  t.integer  "member_id"
  t.integer  "currency"
  t.decimal  "balance",                         precision: 32, scale: 16
  t.decimal  "locked",                          precision: 32, scale: 16
  t.datetime "created_at"
  t.datetime "updated_at"
  t.decimal  "in",                              precision: 32, scale: 16
  t.decimal  "out",                             precision: 32, scale: 16
  t.integer  "default_withdraw_fund_source_id"
end

belongs_to :member # 属于用户
has_many :payment_addresses # 收款地址
has_many :versions, class_name: "::AccountVersion" # 账户变更历史

~~~

从数据库字段来看， `accounts`比较简单， 但是如果把充值提现等影响账户变动的情况都考虑进来的话， `accounts`还是相当复杂。

值得一提是`models/account.rb`中有一个元编程的技巧:

~~~ruby

  FUNS = { :unlock_funds => 1, :lock_funds => 2, :plus_funds => 3, :sub_funds => 4, :unlock_and_sub_funds => 5, :plus_private_locked => 6, :sub_private_locked => 7, :unlock_private_locked => 8, :lock_private_locked => 9 }.freeze


  def self.after(*names)
    names.each do |name|
      m = instance_method(name.to_s)
      define_method(name.to_s) do |*args, &block|
        m.bind(self).(*args, &block)
        yield(self, name.to_sym, *args)
        self
      end
    end
  end


# 通过回调记录account历史版本
  after(*FUNS.keys) do |account, fun, changed, opts|
    begin
      opts ||= {}
      fee = opts[:fee] || ZERO
      reason = opts[:reason] || Account::UNKNOWN

      attributes = { fun: fun,
                     fee: fee,
                     reason: reason,
                     amount: account.amount,
                     currency: account.currency.to_sym,
                     member_id: account.member_id,
                     account_id: account.id }

      if opts[:ref] and opts[:ref].respond_to?(:id)
        ref_klass = opts[:ref].class
        attributes.merge! \
          modifiable_id: opts[:ref].id,
          modifiable_type: ref_klass.respond_to?(:base_class) ? ref_klass.base_class.name : ref_klass.name
      end

      locked, balance, private_locked = compute_locked_and_balance_and_private_locked(fun, changed, opts)

      attributes.merge! locked: locked, balance: balance, private_locked: private_locked

      AccountVersion.optimistically_lock_account_and_create!(account.balance, account.locked, account.private_locked, attributes)
    rescue ActiveRecord::StaleObjectError
      Rails.logger.info "Stale account##{account.id} found when create associated account version, retry."
      account = Account.find(account.id)
      raise ActiveRecord::RecordInvalid, account unless account.valid?
      retry
    end
  end
~~~

`self.after`是一个类方法， 也可以看做是一个类宏， 目的就是通过`bind`方法将`self`绑定到实例方法上， 执行在`account.rb`中定义的正常的`method`。然后通过`yield`来调用挂载在`self.after`后面的代码块。

这就可以通过回调的方式完成.



#### Market 市场交易对

~~~ruby
create_table "markets" do |t|
  t.string   "code", comment: '市场交易对唯一编码 ethbtc'                                                            
  t.string   "name", comment: '交易对名称 ETH/BTC'                                                            
  t.string   "base_unit", comment: '基准货币'                                                       
  t.string   "quote_unit", comment: '报价货币'                                                      
  t.float    "sort_order", comment: '排序方式'  
  t.boolean  "visible", comment: '是否可见'                                          
  t.float    "bid_fee", comment: '买入手续费'    
  t.float    "ask_fee", comment: '卖出手续费'   
  t.integer  "bid_fixed", comment: ''                                        
  t.integer  "ask_fixed", comment: ''                                        
  t.decimal  "issue_price", comment: '市价单 价格'           
  t.datetime "created_at"
  t.datetime "updated_at"
  t.integer  "volume_fixed", comment: ''                                     
  t.integer  "bid_precision", comment: ''                                    
  t.integer  "ask_precision", comment: ''                                    
  t.float    "maker_fee", comment: 'maker 手续费'                              
  t.float    "taker_fee", comment: 'taker 手续费'                              
end
~~~

先解释一下两个概念：

* Maker: 制造者。 简单来说就是提供深度的人。 如果你下的一个挂单， 因为价格高或低没有立即成交，那么你的委托就会被加入到交易所的深度委托单(OrderBook)中.与此同时，你为交易所提供了深度。当你的委托被成交时， 交易所一般对`marker`收费的费用要低一些。
* Taker: 拿走深度的人。如果你的委托单会和已有的委托单马上成交， 那么你的委托会马上成交， 你的委托单会拿走深度。这个委托单会被收取一定的手续费， 其中一部分会返回给上述的 `Maker`.
* 优势：这样可以提供交易所的流动量，提高交易所的深度。深度的增加在一定程度上可以防止数字货币价格出现过大的波动幅度， 也使得交易市场更加健康。在有深度的市场中虽然`Taker`要付手续费， 但是一般来说购买成本要比免手续费交易所还要便宜。

市场交易对是交易中心的基本概念。一般交易所实力越强大，交易所中的交易对越多。

以`USDT/ETH`为例。

* base_unit: 基准货币
* quote_unit: 报价货币

* ask： 卖出 USDT换取 ETH.此时的挂单称之为 `ask`. 用户被称之为`seller`
* bid: 通过ETH买入 USDT，此时的挂单称之为 `bid`.用户被称之为 `buyer`.



后续的`挂单`以及`撮合`都是基于一个市场交易对进行的。

市场交易对还有一些重要信息实时更新，这些数据并没有存放在数据库，而是放在了`Redis`缓存中:

* last_price: 币种成交的最新价格。也就是基准货币相对于报价货币的价格
* ticker_low: 最低价格
* ticker_high: 最高价格
* ticker_volume: 成交量
* ticker_last: 最后成交价格(和 last_price 一致)
* ticker_last_cny: 币种交易对最后的人民币价格
* change_ratio: 变化率。反应了市场的涨跌幅情况。



~~~ruby
# 最新价格与开盘价格之间的变化比率
ticker[:change_ratio] = (_ticker[:last] - _ticker[:open]) / _ticker[:open]
~~~



#### Order 挂单

`order`是用户在交易页面下单产生的`挂单`. 挂单只是买单或者卖单， 还没有被撮合。

~~~ruby
create_table "orders", force: :cascade do |t|
    t.string   "bid", comment: '买入的币种'
    t.string   "ask", comment: '卖出的币种'
    t.decimal  "price",          comment: '挂单价格'
    t.decimal  "volume",         comment: '挂单数量'
    t.decimal  "origin_volume",  comment: '最初挂单数量'
    t.integer  "state", comment: '挂单的状态'                                              
    t.datetime "done_at",   comment: '订单完成时间'
    t.string   "type",      comment: 'STL: OrderAsk | OrderBid'
    t.integer  "member_id", comment: '挂单用户'
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sn"
    t.string   "source",   comment: '挂单来源',                                                           
    t.string   "ord_type", comment: '挂单类型 limit market'
    t.decimal  "locked",   comment: '被锁金额'
    t.decimal  "origin_locked", comment: '最初被锁金额'           
    t.decimal  "funds_received", comment: 'bid:已成交的货币数量 | ask: 成交的金额'
    t.integer  "trades_count",   comment: '成交记录个数'
    t.string   "market_code",    comment: '市场交易对'
    t.string   "uid"
end

# for OrderAsk
has_many :trades, foreign_key: :ask_id

# for OrderBid
has_many :trades, foreign_key: :bid_id
~~~



order就是用户下单生成的买单或者卖单。

> 一个挂单的成交不一定是一蹴而就的。比如说一个 10000的大单， 可能最后需要很多个其他人的挂单才能 fill.一个 成交的记录就为一个 trade, 如果 order 的 volume最终为0， 就说明挂单的量都被满足了， 此时 order 就算完成了。



挂单的分类：

* limit: 限价单，只在指定的价格成交. 
* market: 能成就成， 不成拉倒。 优先级比 limit 要高

##### OrderAsk 卖单

卖单也就是用户为了卖出而下的挂单。

卖单中存在一个`最优价格`的概念： 价格越低， 时间越早， 优先成交

~~~Ruby
scope :matching_rule, -> { order('price ASC, created_at ASC') }
~~~



##### OrderLimit

买单也就是用户购买某个报价货币而下的挂单。

买单中的最优价格也遵循一个原则： 价格越高， 时间约早， 越优先

~~~Ruby
scope :matching_rule, -> { order('price DESC, created_at ASC') }
~~~



其他的几个小概念:

以  `BTC/ETH`交易对为例：

order_bid: 通过 `eth`买入 `btc` . 买入数量 5, 买入价格 121 -> 实际需要花费的`eth`数量为 605

order_ask: 通过卖出`btc`来换取 `eth`. 卖出600个`ETH`.  -> 此时需要锁定用户`ETH`的数量就应该为 600

* original_locked:
  * bid: price   *   volume   -> 买入的时候是锁定的金额: 买多少其他币种 * 买入的价格
  * order_ask:      volume  -> 卖出的时候就直接锁定的为数量 (打算卖多少就锁定多少)

* avg_price： 买入或者卖出的均价.
  * order_bid: avg_price = funds_used / funds_received
    * 已花费的金额 / 已成交的数量 == 平均价格
    * funds_used = original_locked - locked (用户挂单已解锁的金额，也就是已花费的金额)
    * funds_received: 已成交的数量(也就是已买入的货币数量)
  * order_ask: avg_price =  fund_received / fund_used
    * fund_received:  已卖出的金额
    * fund_used: original_locked - locked. 已卖出的数量
      * original_locked: order.origin_volume: 最初挂单的卖出数量
      * locked: 目前挂单的数量 

#### Trade 交易记录



~~~Ruby
create_table "trades", force: :cascade do |t|
  t.decimal  "price",   comment: '成交价格'
  t.decimal  "volume",  comment: '成交量'
  t.integer  "ask_id",  comment: '卖单'
  t.integer  "bid_id",  comment: '买单'
  t.integer  "trend"
  t.datetime "created_at"
  t.datetime "updated_at"
  t.integer  "ask_member_id", comment: '卖家'
  t.integer  "bid_member_id", comment: '买家'
  t.decimal  "funds",   comment: '成交金额 = price * volume'
  t.string   "market_code", comment: '市场交易对 code ethbtc'                             
  t.index ["ask_id"]
  t.index ["ask_member_id"]
  t.index ["bid_id"]
  t.index ["bid_member_id"]
  t.index ["created_at"]
  t.index ["market_code"]
  t.index ["price"]
  t.index ["volume"]
end

belongs_to :ask, class_name: 'OrderAsk', foreign_key: 'ask_id'
belongs_to :bid, class_name: 'OrderBid', foreign_key: 'bid_id'
has_many :fees, :class_name => TradeFee

belongs_to :ask_member, class_name: 'Member', foreign_key: 'ask_member_id'
belongs_to :bid_member, class_name: 'Member', foreign_key: 'bid_member_id'

~~~

交易记录是在挂单撮合成功的情况下创建的。

我们可以对一段时间内的 trade进行分析， 得到一些有价值的信息:

* lastest_price: 币种的最新价格
* h24: 24小时成交的交易记录



以上我们简单回顾了和交易撮合紧密相关的模型， 接下来就从用户下单开始， 深入分析撮合系统是如何将用户的买单和卖单撮合，交易，清算， 最终在页面中展现的。

### 下单

#### 用户下单

1. 用户下单时，通过`api/v2/orders` url 发起一个 `POST`请求。

~~~Ruby
desc 'Create a Sell/Buy order.', scopes: %w(trade)
# order:  side ord_type price volume
params do
  use :auth, :market, :order
end
post "/orders" do
  order = create_order params # step 2
  present order, with: APIv2::Entities::Order
end
~~~

2. 在`api/api_v2/helpers.rb`中定义了方法`create_order`:

~~~ruby
def build_order(attrs)
  klass = attrs[:side] == 'sell' ? OrderAsk : OrderBid

  klass.new(
    source:        'APIv2',
    state:         ::Order::WAIT,
    member_id:     current_user.id,
    ask:           current_market.base_unit,
    bid:           current_market.quote_unit,
    currency:      current_market.code,
    ord_type:      attrs[:ord_type] || 'limit',
    price:         attrs[:price],
    volume:        attrs[:volume],
    origin_volume: attrs[:volume]
  )
end

# 下单
def create_order(attrs)
  # 创建一个订单(此时订单还只存在于内存中， 未入库)
  order = build_order attrs
  Ordering.new(order).submit # step 3
  order
rescue
  Rails.logger.info "Failed to create order: #{$!}"
  Rails.logger.debug order.inspect
  Rails.logger.debug $!.backtrace.join("\n")
  raise CreateOrderError, 'unknown'
end
~~~

3. 在 `app/services/ordering.rb`中定义了`Ordering`类：

~~~Ruby
class Order
  # 这里可以传入一个挂单， 也可以批量传入挂单
  def initialize(order_or_orders)
  	@orders = Array(order_or_orders)
  end
    
  def submit
    # 创建订单
    # 锁定用户账户资金
    ActiveRecord::Base.transaction do
      @orders.each {|order| do_submit order}
    end
      
    # 挂单进入消息队列等待撮合
    @orders.each do |order|
      AMQPQueue.enqueue(:matching, :action: 'submit', order: order.to_matching_attributes)
    end
      
    private
    # 账户锁定金额
    def do_submit(order)
      order.fix_number_precision
      order.locked = order.origin_locked = order.compute_locked
      order.save
        
      account = order.hold_account
      account.lock_funds(order.locked, reason: Account::ORDER_SUBMIT, ref: order)
    end
  end
end

# models/order.rb
def to_matching_attributes
  { 
  id: id,
  market: market,
  type: type[-3, 3].downcase.to_sym,
  ord_type: ord_type,
  volume: volume,
  price: price,
  locked: locked,
  timestamp: created_at.to_i 
  }
end
~~~





### 撮合处理器 Matching

`matching：`撮合系统， 是交易所的核心： 如何将买单和卖单匹配，让它们交易， 并生成数据。

其他的一切都是为了它服务。

在 `order`创建成功后， `order`被压入队列。

#### daemon

`peatio`的后台异步任务是通过`daemon`完成的。

在`lib/daemons/`目录下以`_ctl`结尾的文件都是控制后台的控制文件。对应的`daemon_name.rb`为其执行的文件。比如`k_ctl`和`k.rb`就是k线的后台异步任务。 

不过很多`_ctl`没有对应的`daemon_name.rb`，这是因为他们的`daemon_name.rb`都是同一个文件`amqp_daemon.rb`.所有的`AMQP`队列处理的任务都是在`amqp_daemon.rb`中进行处理。

以`matching_ctl`为例:

~~~Ruby
#!/usr/bin/env ruby
require 'rubygems'
require 'daemons/rails/config'

config = Daemons::Rails::Config.for_controller(File.expand_path(__FILE__))

config[:app_name] = 'peatio:amqp:matching'
# 执行文件为 amqp_daemon.rb
config[:script]   = "#{File.expand_path('../amqp_daemon.rb', __FILE__)}"
# 传入的参数为 matching
config[:ARGV]     = ARGV + %w(-- matching)

Daemons::Rails.run config[:script], config.to_hash

~~~

`amqp_daemon.rb`文件主要是选择交换器和路由，并且执行对应的`worker`.

具体过程容后再表。

` matching`最终的执行worker为`app/modes/worker/matching`

~~~Ruby
module Worker
  def initialize(options = {})
    @options = options
    # 重新加载所有的市场对委托单并启动引擎
    # 不管传来的参数是 submit cancel reload
    # 统统先重新加载一遍
    # 目的何在？
    reload 'all'
  end
    
  def process(payload, metadata, delivery_info)
    payload.symbolize_keys!
    case payload[:action]
    when 'submit'
      # 首先根据传入的参数创建 一个普通的 `plain object order`
      # 调用币种对的引擎处理器， 执行撮合引擎中的代码
      submit build_order(payload[:order])
    when 'cancel'
      # 取消订单
    when 'reload'
      # 重新加载市场交易对对应的订单
    end
  end
    
  # 创建委托账本 [卖3 卖2 卖1 买1 买2 买3]
  def build_order(attrs)
    ::Matching::OrderBookManager.build_order attrs
  end
    
  def submit(order)
    engines[order.market_code].submit(order)
  end
    
  def reload(market)
    if market == 'all'
      Market.all {|market| initialize_engine market}
    else
      initialize_engine Market.sematic_find(market)
    end
  end
    
  # 初始化撮合引擎
  def initialize_engine(market)
    create_engine market # 创建引擎
    load_orders market   # 加载市场对对应的挂单
    start_engine market  # 启动引擎，开始撮合工作
  end
    
  # 创建引擎
  def create_engine(market)
    engines[market.code] = ::Matching::Engine.new(market, @options)
  end
  
  # 加载所有的挂单-> 生成 plain object order
  def load_orders market
    ::Order.active.with_currency(market.code).order('id asc').each do |order|
      # engine submit action
      submit build_order(order.to_matching_attributes)
    end
  end
    
 # 启动引擎
 # 见后文分析
 def start_engine(market)
 
 end
    
  
end
~~~

1.首先调用`initialize`初始化方法， `reload all`. 加载所有的市场对对应的**委托单**. 

这里的`reload`完成了三件事情：

~~~Ruby
# 初始化撮合引擎
def initialize_engine(market)
  create_engine market # 创建引擎
  load_orders market   # 加载市场对对应的挂单
  start_engine market  # 启动引擎，开始撮合工作
end
~~~

不过这里的操作和`process`有部分重合， 暂时没有想明白。



2. `process`处理。

   因为我们传入的为`submit`,执行以下操作：

   ~~~ruby
   # 首先根据传入的参数创建 orderbook(深度委托单)
   # 调用币种对的引擎处理器， 执行撮合引擎中的代码
   submit build_order(payload[:order])
   ~~~

   首先通过`OrderBookManager`创建委托单列表，然后调用对应的引擎处理器进行撮合。


### 委托单处理器 OrderBookManager

~~~ruby
module Worker
  class OrderBookManager
    # 创建 order limit | market
    def self.build_order(attrs)
      attrs.symbolize_keys!

      raise ArgumentError, "Missing ord_type: #{attrs.inspect}" unless attrs[:ord_type].present?

      # ord_type: limit | market
      klass = ::Matching.const_get "#{attrs[:ord_type]}_order".camelize
      klass.new attrs
    end
  end
end
~~~

这里是通过`OrderBookManager`创建了一个`plain object`， 也就是存在于内存中的`order`.

通过判断`ord_type`来决定创建`limit_order`还是`market_order`.

最后返回一个普通的 order 对象， 供引擎调用 `submit`.



### 撮合引擎 Engine

~~~Ruby
module Matching
  class Engine
    # 初始化引擎
    # 一个市场交易对对应一个引擎
    # 一个引擎有一个OrderBook(数据结构采用的是红黑树)
    def initialize(market, options = {})
      @market    = market
      @orderbook = OrderBookManager.new(market.code)

      # Engine is able to run in different mode:
      # dryrun: do the match, do not publish the trades
      # run:    do the match, publish the trades (default)
      shift_gears(options[:mode] || :run)
    end
      
    # 引擎运转策略
    def shift_gears(mode)
      case mode
      when :dryrun
        @queue = []
        class <<@queue
          def enqueue(*args)
            push args
          end
        end
      when :run
        # 队列为 AMQPQueue
        @queue = AMQPQueue
      else
        raise "Unrecognized mode: #{mode}"
      end

      @mode = mode
    end

    def submit(order)
      # ask: book is ask_orders, counter_book is bid_orders
      # bid: book is bid_orders, counter_book is ask_orders
      book, counter_book = orderbook.get_books order.type
      # match order 和 对方委托单
      match order, counter_book
      # 刚开始没有挂单的时候， 就会执行 add_or_cancel
      # 委托单中添加或取消 挂单
      add_or_cancel order, book
    rescue
      Rails.logger.fatal "Failed to submit order #{order.label}: #{$ERROR_INFO}"
      Rails.logger.fatal $ERROR_INFO.backtrace.join("\n")
    end
  end
end
~~~



先来看一下 `matching.rb`中的`start_engine`

~~~ruby
# 启动引擎
# models/matching/engine.rb
def start_engine(market)
  engine = engines[market.code]
  if engine.mode == :dryrun
    if engine.queue.empty?
      engine.shift_gears :run
    else
      # 默认是采用 :run 形式的
      accept = ENV['ACCEPT_MINUTES'] ? ENV['ACCEPT_MINUTES'].to_i : 30
      order_ids = engine.queue
        .map {|args| [args[1][:ask_id], args[1][:bid_id]] }
        .flatten.uniq

      orders = Order.where('created_at < ?', accept.minutes.ago).where(id: order_ids)
      if orders.exists?
        # there're very old orders matched, need human intervention
        raise DryrunError, engine
      else
        # only buffered orders matched, just publish trades and continue
        engine.queue.each {|args| AMQPQueue.enqueue(*args) }
        engine.shift_gears :run
      end
    end
  else
    Rails.logger.info "#{market.code} engine already started. mode=#{engine.mode}"
  end
end
~~~

因为`engine`默认的运作方式为`:run`, 上述代码基本不起作用。

当运行方式为`:dryrun`时，再做分析。



接下来就是关键部分了：

~~~ruby
def submit(order)
  # ask: book is ask_orders, counter_book is bid_orders
  # bid: book is bid_orders, counter_book is ask_orders
  book, counter_book = orderbook.get_books order.type
  # match order 和 对方委托单
  match order, counter_book
  # 刚开始没有挂单的时候， 就会执行 add_or_cancel
  # 委托单中添加或取消 挂单
  add_or_cancel order, book
rescue
  Rails.logger.fatal "Failed to submit order #{order.label}: #{$ERROR_INFO}"
  Rails.logger.fatal $ERROR_INFO.backtrace.join("\n")
end
~~~

一行一行的分析， 不然会错过很多信息。

1.从委托单中找到最优挂单:

~~~ruby
# order is waiting for matching order
# counter: 对手单
# ask: book is ask_orders, counter_book is bid_orders
# bid: book is bid_orders, counter_book is ask_orders
book, counter_book = orderbook.get_books order.type
~~~

当我们的`order`为`order_bid`时， counter_book就为 `[卖1， 买2， 买3， 买4， 买5]`

当我们的`order`为`order_ask`时， counter_book就为`[买1， 买2， 买3， 买4， 买5]`

上述代码是从` orderbook`中获取`委托卖单列表`和`委托买单列表`.

~~~ruby
@orderbook = OrderBookManager.new(market.code)

# order_book_manager.rb
module Matching
  class OrderBookManager
    def initialize(market, options={})
      @market     = market
      @ask_orders = OrderBook.new(market, :ask, options)
      @bid_orders = OrderBook.new(market, :bid, options)
    end

    def get_books(type)
      case type
      when :ask
        [@ask_orders, @bid_orders]
      when :bid
        [@bid_orders, @ask_orders]
      end
    end
  end
end
~~~



2. 匹配订单:

~~~Ruby
# match order 和 委托账单
match order, counter_book

def match(order, counter_book)
  return if order.filled? #如果一个挂单已完成（买到或者卖到预期的数量）就直接返回
  # order 为 order_bid 时， counter_book.top 就是 卖 1
  # order 为 order_ask 时， counter_book.top 就是 买 1
  # counter_order 是买卖队列里的第一个 最优 order
  counter_order = counter_book.top
  return unless counter_order

  # matching limit_order | market_order
  # 返回值 匹配的价格， 数量， 金额 [trade_price, trade_volume, trade_funds]
  # 有返回值也就意味着买卖撮合成对了
  # trade_funds = trade_price * trade_volume
  trade = order.trade_with(counter_order, counter_book)
  return unless trade

  # 挂单队里的委托单列表中的 order volume - trade_volume
  # 对手委托单中的数量要相应的减少
  counter_book.fill_top(*trade) 
  # 挂单的数量也要相应的减少(减少的数量就是撮合成功的数量值)
  order.fill(*trade) # @volume = @volume - trade_volume
  publish order, counter_order, trade # 只发布成交消息，不实际操作委托单数据
  match order, counter_book
end
~~~

match 方法是个递归，它会一直尝试和最新的 counter_order 去配对成交。
可见我们下的每一单都会一直在尝试去成交，是需要很大内存的。又不能不这样，万一有大单把所有都吃掉呢。而且需要实时统计当前筹码等数据。

还是逐行分析：

(1) 定位委托单列表

~~~ruby
#如果一个挂单已完成（买到或者卖到预期的数量）就直接返回
return if order.filled? 
# order 为 order_bid 时， counter_book.top 就是 卖 1(ask_1)
# order 为 order_ask 时， counter_book.top 就是 买 1(bid_1)
# counter_order 是买卖队列里的第一个 最优 order
# 这里 counter_book 采用的数据结构为红黑树， 插入和查询的效率均为 O(logn)
counter_order = counter_book.top
# 如果没有委托单就直接返回
return unless counter_order
~~~

（2）查看当前订单和 委托单列表中是否可以撮合

~~~ruby
# matching limit_order | market_order
# 返回值 匹配的价格， 数量， 金额 [trade_price, trade_volume, trade_funds]
# 有返回值也就意味着买卖撮合成对了
# trade_funds = trade_price * trade_volume
#[trade_price, trade_volume, trade_funds]
trade = order.trade_with(counter_order, counter_book)
return unless trade

# matching/limit_order.rb
# 这里是限价单
def trade_with(counter_order, counter_book)
  if counter_order.is_a?(LimitOrder)
    # 限价单
    # 如果满足交叉价格， order 与 counter_order 撮合成功
    if crossed?(counter_order.price)
      trade_price  = counter_order.price # 成交的价格
      # volume: 撮合的数量(当前挂单和对手单数量取最小值)
      trade_volume = [volume, counter_order.volume].min 
      # trade_funds: # 撮合成交的金额
      trade_funds  = trade_price * trade_volume 
      [trade_price, trade_volume, trade_funds]
    end
  else
    # 市价单, 能成就成
    # 成交量 取 三个值中的最小值
    trade_volume = [volume, counter_order.volume, counter_order.volume_limit(price)].min
    trade_funds  = price * trade_volume
    [price, trade_volume, trade_funds]
  end
end
~~~

上述返回的是撮合成交的三元数组:

* 撮合的价格
* 撮合的数量
* 撮合的金额 = 价格 * 数量

~~~ruby
# 更新委托单完成成交量
# 减去 trade(撮合成功的挂单)中的 volume
counter_book.fill_top(*trade) 
# 当前挂单的数量也要相应的减少(减少的数量就是撮合成功的数量值)
order.fill(*trade) # volume - trade_volume

~~~

`counter_book`中调用`fill_top`来实现最优委托单数量更新:

~~~Ruby
# order_book
def fill_top(trade_price, trade_volume, trade_funds)
  order = top
  # OrderBook 中为空， 此时无法撮合交易
  raise 'No top order in empty book.' unless order

  # order_book最优挂单order 对应的 volume 需要减少
  # 但是这里并不创建 trade
  # 这里只是预撮合
  order.fill trade_price, trade_volume, trade_funds
  if order.filled?
    # 订单预撮合完成之后，需要移除此订单
    # 具体细节见下面
    remove order
  else
    broadcast(action: 'update', order: order.attributes)
  end
end

# limit_order.rb
def fill(trade_price, trade_volume, trade_funds)
  raise NotEnoughVolume if trade_volume > @volume
  @volume -= trade_volume
end
~~~



~~~Ruby
def remove(order)
  case order
  when LimitOrder
    remove_limit_order(order)
  when MarketOrder
    remove_market_order(order)
  else
    raise ArgumentError, "Unknown order type"
  end
end

def remove_limit_order(order)
  # 先根据 price 找到对应 price_level
  # 也就是同属于一个价格的 挂单列表
  price_level = @limit_orders[order.price]
  return unless price_level
  # 找到订单
  # 这么做的原因就是 order 的数量一直有变化
  # 要根据 id 找到最新的 order 数据
  order = price_level.find order.id # so we can return fresh order
  return unless order
  # price_level 中移除订单
  price_level.remove order
  # 如果 price 对应的挂单列表为空，就移除这个价格
  @limit_orders.delete(order.price) if price_level.empty?

  broadcast(action: 'remove', order: order.attributes)
  order
end

def remove_market_order(order)
  # 市价单匹配了一圈之后
  if order = @market_orders[order.id]
    @market_orders.delete order.id
    broadcast(action: 'remove', order: order.attributes)
    order
  end
end

# 消息广播到 slave_book 队列中
# slave_book 将 order_book 中的数据写入到 Redis 中，供 api 使用

def broadcast(data)
  return unless @broadcast
  # 将 OrderBook 中的值复制到 Redis 中
  AMQPQueue.enqueue(:slave_book, data, { persistent: false })
  Rails.logger.info(data)
end
~~~



（4）最后将撮合的订单信息推到消息队列中:

~~~Ruby
publish order, counter_order, trade # 只发布成交消息，不实际操作委托单数据
# 实际执行 trade 创建和清算的是在 trade_executor 中

def publish(order, counter_order, trade)
  ask, bid = order.type == :ask ? [order, counter_order] : [counter_order, order]

  price  = @market.fix_number_precision :bid, trade[0]
  volume = @market.fix_number_precision :ask, trade[1]
  funds  = trade[2]

  # ask_id bid_id price volume funds 这些参数就足够创建撮合交易记录了
  # 入队之后就是实际创建 trade 了
  @queue.enqueue(
    :trade_executor,
    { market_id: @market.code, ask_id: ask.id, bid_id: bid.id, strike_price: price, volume: volume, funds: funds },
    { persistent: false }
  )
end
~~~

（5）递归执行 `match`, 继续撮合订单和委托单列表（order_book)

~~~Ruby
match order, counter_book
~~~




3. 添加或者取消订单

~~~Ruby
# 刚开始没有挂单的时候，就会执行 add_or_cancel
# 委托单中添加或取消挂单
# 如果上述的撮合没有完成，此时就需要将当前的 order 加入到 order_book 中
# 如果当前的 order 是 market_order,并且未 fill，就把它从 order_book 中移除
add_or_cancel order, book

def add_or_cancel(order, book)
  return if order.filled?
  if order.is_a?(LimitOrder)
    book.add(order)
  else
    # Order 是市价单, 但 Match 了一轮以后没有被满足 (filled), 故取消 Order
    publish_cancel(order, 'fill or kill market order')
  end
end
~~~

`order_book`中添加未撮合完毕的订单:

~~~ruby
# order_book.rb
def add(order)
  raise InvalidOrderError, 'volume is zero' if order.volume <= ZERO

  case order
  when LimitOrder
    # 向 price 对应的队列中添加当前的 order
    # 红黑树中会将 price key 按照大小顺序插入到正确的位置
    @limit_orders[order.price] ||= PriceLevel.new(order.price)
    @limit_orders[order.price].add order
  when MarketOrder
    # 市价单由于没有价格， 所以直接保存 order.id -> order 的hash 映射
    @market_orders[order.id] = order
  else
    raise ArgumentError, 'Unknown order type'
  end

  broadcast(action: 'add', order: order.attributes)
end

~~~

这时候我们先来看一下 `order_book`的初始化都做了哪些事情:

~~~Ruby
def initialize(market, side, options = {})
  @side = side.to_sym
  # limit_orders 和 market_orders 均为红黑树
  @limit_orders = RBTree.new
  @market_orders = RBTree.new

  @broadcast = options.key?(:broadcast) ? options[:broadcast] : true
  market_code = market.is_a?(Market) ? market.code : market
  broadcast action: 'new', market: market_code, side: @side

  # 向这个实例的 Metaclass 添加一个方法 :limit_top
  # 即, 添加一个实例方法 :limit_top
  # -> bid_limit_top
  # -> ask_limit_top
  singleton = class<<self; self; end
  singleton.send :define_method, :limit_top, self.class.instance_method("#{@side}_limit_top")
end

def broadcast(data)
  return unless @broadcast
  # 将 OrderBook 中的值写入到 Redis 中
  # 只是进行数据的写入和更新， 不进行任何撮合交易
  AMQPQueue.enqueue(:slave_book, data, { persistent: false })
  Rails.logger.info(data)
end

~~~

`@limit_orders`和`@market_orders`均为红黑树。 红黑树的优势就是插入和查询的复杂度均为 Ologn.

撮合系统需要进行频繁的将挂单插入到价格`price`对应的队列中，同时需要拿到最优的委托单和进入的 order 进行撮合。

我们这里是使用的一个`rbtree` gem, 后续有针对红黑树的文章。



### 交易成交处理器 Executor

在 `engine`中我们将配对的订单相关的信息发布到 AMQPQueue中:

~~~ruby
@queue.enqueue(
        :trade_executor,
        { market_id: @market.code, ask_id: ask.id, bid_id: bid.id, strike_price: price, volume: volume, funds: funds },
        { persistent: false }
      )
~~~

通过消息队列我们将行情系统更新至需要展示的地方。



交易记录的创建工作就落在了`trade_executor`中。

我们先来查看一下 `lib/worker/trade_executor`:

~~~ruby
module Worker
  class TradeExecutor

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!
      ::Matching::Executor.new(payload).execute!
    rescue
      SystemMailer.trade_execute_error(payload, $!.message, $!.backtrace.join("\n")).deliver
      raise $!
    end

  end
end

~~~

这里最终的执行委托给`Matching::Executor`这个类

~~~ruby
module Matching
  class Executor

    def initialize(payload)
      @payload = payload
      @market  = Market.sematic_find payload[:market_id]
      # strike 成交的价格
      @price   = BigDecimal.new payload[:strike_price]
      # 成交的数量
      @volume  = BigDecimal.new payload[:volume]
      # 成交的金额
      @funds   = BigDecimal.new payload[:funds]
    end

    def execute!
      retry_on_error(5) { create_trade_and_strike_orders }
      publish_trade
      @trade
    end
  end
end
~~~

`execute!`方法实现了最终的成交逻辑:

~~~ruby
def create_trade_and_strike_orders
  ActiveRecord::Base.transaction do
    @ask = OrderAsk.lock(true).find(@payload[:ask_id])
    @bid = OrderBid.lock(true).find(@payload[:bid_id])

    raise TradeExecutionError.new({ask: @ask, bid: @bid, price: @price, volume: @volume, funds: @funds}) unless valid?

    @trade = Trade.create!(ask_id: @ask.id, ask_member_id: @ask.member_id,
                           bid_id: @bid.id, bid_member_id: @bid.member_id,
                           price: @price, volume: @volume, funds: @funds,
                           currency: @market.code, trend: trend)

    if @bid.created_at > @ask.created_at 
      @bid.strike @trade, :taker # 拿走深度的人
      @ask.strike @trade, :maker # 创建深度的人
    else
      @bid.strike @trade, :maker
      @ask.strike @trade, :taker
    end
  end

  # TODO: temporary fix, can be removed after pusher -> polling refactoring
  if @trade.ask_member_id == @trade.bid_member_id
    @ask.hold_account.reload.trigger
    @bid.hold_account.reload.trigger
  end
end
~~~

上面的方法首先根据队列中的数据来创建`trade`, 然后调用`order.strike`, 进行清算和手续费扣除.



Order strike 方法完成清算功能：

~~~ruby
# strike 完成一笔交易
# Strike Price （Exercise Price）敲定格（履约价）：期权合约中双方协定的相关期货商品的价格
def strike(trade, role = :taker)
  raise "Cannot strike on cancelled or done order. id: #{id}, state: #{state}" unless state == Order::WAIT

  # 当 order 为 order_bid时: get_account_changes 返回的是 [trade.funds, trade.volume]
  # 成交金额 成交量
    
  # 当 order 为 order_ask 时: get_account_changes 返回的是 [trade.volume, trade.funds]
  # 成交量 成交金额
  real_sub, add = get_account_changes trade

  real_fee = fee_result[:fee]
  real_add = add - real_fee
  expect_account.plus_funds real_add,
        fee: real_fee,
        reason: Account::STRIKE_ADD,
        ref: trade

  hold_account.unlock_and_sub_funds real_sub,
    locked: real_sub,
    reason: Account::STRIKE_SUB,
    ref: trade

  self.volume         -= trade.volume
  self.locked         -= real_sub
  # 当 order_bid时: 这里的 funds_received 实际上已成交的数量
  # 当 order_ask时: 这里的 funds_received 实际上就是已成交的金额
  self.funds_received += add
  self.trades_count   += 1

  if volume.zero?
    # 委托单全量成交
    self.state = Order::DONE

    # 当成交总金额小于委托金额时需要退款给用户
    unless locked.zero?
      hold_account.unlock_funds locked,
                                reason: Account::ORDER_FULLFILLED,
                                ref: trade
    end
  elsif ord_type == 'market' && locked.zero?
    # partially filled market order has run out its locked fund
    self.state = Order::CANCEL
  end

  save!
end
~~~

至此一笔订单的撮合交易完成。

### 消息中心 AMQPQueue

消息队列和 行情发布系统`Quotation`密切相关。

我们的交易系统每次更新或者移除数据的时候都会将信息发送到消息队列中， 由 `AMQPQueue`进行处理。

我们依次来看看到底哪些信息丢到了 `RabbitMQ`中。



#### add order_book

当我们在委托单列表中添加了一个`order`时， 我们会将订单的信息放到`slave_book`队列中:

~~~ruby
def add(order)
  raise InvalidOrderError, 'volume is zero' if order.volume <= ZERO

  case order
  when LimitOrder
    @limit_orders[order.price] ||= PriceLevel.new(order.price)
    @limit_orders[order.price].add order
  when MarketOrder
    @market_orders[order.id] = order
  else
    raise ArgumentError, 'Unknown order type'
  end

  broadcast(action: 'add', order: order.attributes)
end

def broadcast(data)
  return unless @broadcast
  AMQPQueue.enqueue(:slave_book, data, { persistent: false })
  Rails.logger.info(data)
end
~~~

`slave_book`的作用就是每隔一秒更新 Redis中的深度值：

~~~ruby
module Worker
  class SlaveBook
    def initialize(run_cache_thread = true)
      @managers = {}

      if run_cache_thread
        cache_thread = Thread.new do
          loop do
            sleep 1
            cache_book
          end
        end
      end
    end
      
    # 缓存 order_book
    def cache_book
      @managers.keys.each do |market_code|
        asks = get_depth(market_code, :ask)
        bids = get_depth(market_code, :bid)

        Rails.cache.write("peatio:#{market_code}:depth:asks", asks)
        Rails.cache.write("peatio:#{market_code}:depth:bids", bids)

        RedisJsonCache.write("peatio:#{market_code}:depth:asks", asks)
        RedisJsonCache.write("peatio:#{market_code}:depth:bids", bids)
      end
    rescue StandardError => e
      Raven.capture_exception(e)
      Rails.logger.error "Failed to cache book: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
    end
      
    # 获取委托单深度列表
    def get_depth(market_code, side)
      depth = Hash.new { |h, k| h[k] = 0 }
      @managers[market_code].send("#{side}_orders").limit_orders.each do |price, orders|
        depth[price] += orders.map(&:volume).sum
      end

      depth = depth.to_a
      depth.reverse! if side == :bid
      depth
    end
      
  end
end
~~~

当我们更新`order_book`时， 我们会将`order_book`的改变通过`rabbitmq`通知到`slave_book`,进而使`slave_book`的缓存值得到更新.



~~~ruby
def process(payload, _metadata, _delivery_info)
  @payload = Hashie::Mash.new payload

  case @payload.action
  when 'new'
    @managers.delete(@payload.market)
    initialize_orderbook_manager(@payload.market)
  when 'add'
    book.add order
  when 'update'
    book.find(order).volume = order.volume # only volume would change
  when 'remove'
    book.remove order
  else
    raise ArgumentError, "Unknown action: #{@payload.action}"
  end
rescue => e
  Raven.capture_exception(e)
  Rails.logger.error "Failed to process payload: #{$!}"
  Rails.logger.error $!.backtrace.join("\n")
end
~~~

 

当`action`为`add`时, 我们将新加入的`order`加入到委托单深度列表中

~~~ruby
book.add order

def order
  ::Matching::OrderBookManager.build_order @payload.order.to_h
end

def book
  manager.get_books(@payload.order.type.to_sym).first
end

def manager
  market_code = @payload.order.market
  @managers[market_code] || initialize_orderbook_manager(market_code)
end

def initialize_orderbook_manager(market_code)
  @managers[market_code] = ::Matching::OrderBookManager.new(market_code, broadcast: false)
end
~~~



#### update order_book中 order volume

~~~ruby
when 'update'
    book.find(order).volume = order.volume # only volume would change
~~~



~~~ruby
def fill_top(trade_price, trade_volume, trade_funds)
  order = top
  raise 'No top order in empty book.' unless order

  order.fill trade_price, trade_volume, trade_funds
  if order.filled?
    remove order
  else
    broadcast(action: 'update', order: order.attributes)
  end
end
~~~

当一个挂单和委托深度列表撮合成功时，需要更新`slave_book`深度的`volume`值



#### remove order_book order

~~~ruby
when 'remove'
    book.remove order
~~~



~~~ruby
def remove_limit_order(order)
  price_level = @limit_orders[order.price]
  return unless price_level

  order = price_level.find order.id # so we can return fresh order
  return unless order

  price_level.remove order
  @limit_orders.delete(order.price) if price_level.empty?

  broadcast(action: 'remove', order: order.attributes)
  order
end

def remove_market_order(order)
  if order = @market_orders[order.id]
    @market_orders.delete order.id
    broadcast(action: 'remove', order: order.attributes)
    order
  end
end

~~~





### 数据结构与算法 Algorithm

### 依赖包 Gems
