---
layout: post
toc: true
permalink: /how-rails-session-work
title: Rails Sessions 原理
tags: Rails session
desc: session可以存储多个请求需要共享的数据。当你对一个页面发送请求的时候，rails服务器的response将会返回一个cookie.浏览器会保存这些cookie, 直到cookie过期.当你每次发送一个请求。浏览器会把这个cookie发送到服务器。
---

如果 Rails 不能告诉你谁在访问你的网站？如果你不知道同一个人在访问2个不同的页面？ 如果所有的数据在你返回 response 之前都消失的话？

对于一个静态网站来说也许没有问题。但是大多数应用程序需要存储一个用户的数据的。可能是一个 用户 id 或者 选择的语言偏好，或者他们通过 iPad 访问你的网站，想看看桌面的版本。

session 是一个非常好的地方来放置这些数据。一般是存储一些不止一个请求需要用的数据。

Session 使用起来很简单。

```ruby
session[:current_user_id] = @user.id
```

但是它们会有点神奇。 session 是什么？ Rails 是怎么处理这些数据，对于不同的人显示不同的数据。 还有你怎么决定在哪里存储你的 session 数据呢？

什么是 Session？
session 就是存储多个请求需要共享的数据。你可以设置一些数据在 controller 里面。
```ruby
app/controllers/sessions_controller.rb
def create
  # ...
  session[:current_user_id] = @user.id
  # ...
end
```
然后在另外一个 controller 里面读取。

```ruby
app/controllers/users_controller.rb

def index
  current_user = User.find_by_id(session[:current_user_id])
  # ...
end
```
这个看起来可能不是很有趣。但是这个协调了浏览器和 Rails 应用之间的联系。这个是通过 cookies 实现的。

当你对一个页面发送请求的话，rails 服务器的response将会返回一个 cookie。

```shell
$ curl -I http://www.google.com | grep Set-Cookie

Set-Cookie: NID=67=J2xeyegolV0SSneukSOANOCoeuDQs7G1FDAK2j-nVyaoejz-4K6aouUQtyp5B_rK3Z7G-EwTIzDm7XQ3_ZUVNnFmlGfIHMAnZQNd4kM89VLzCsM0fZnr_N8-idASAfBEdS; expires=Wed, 16-Sep-2015 05:44:42 GMT; path=/; domain=.google.com; HttpOnly
```

你的浏览器将会保存这些 cookie。直到你的 cookie 过期，每次你发送一个请求，浏览器将会把这个 cookie 发送 到服务器。

```
> GET / HTTP/1.1
> User-Agent: curl/7.37.1
> Host: www.google.com
> Accept: */*
> Cookie: NID=67=J2xeyegolV0SSneukSOANOCoeuDQs7G1FDAK2j-nVyaoejz-4K6aouUQtyp5B_rK3Z7G-EwTIzDm7XQ3_ZUVNnFmlGfIHMAnZQNd4kM89VLzCsM0fZnr_N8-idASAfBEdS; expires=Wed, 16-Sep-2015 05:44:42 GMT; path=/; domain=.google.com; HttpOnly
```
很多 cookie 看起来是乱码一样的文字组合，其实应该这样。这个数据并不是给浏览器的使用用户看的， 是给你的 Rails 应用读的，也只有它可以读出来里面的信息。

对于 session 我们需要做什么呢？
这时候，我们有了 cookie，你把数据放在里面，下一个请求的时候就可以读取了。那和 session 有什么不同呢? 默认情况下，在 Rails 里面是没有什么不同的。只不过 Rails 做了更多处理来保证 cookie 数据的安全。 除了这个以外，它工作的和你期待的一样。你的 Rails 应用把一些数据放 cookie，然后你从 cookie 里面读 取这些数据。但是 cookie 也不是 session 最好的存储方案。

在 cookie 里面你最多只能存储 4K 的数据 一般情况下是足够了，但有时也会不够。
每次发送请求都会发送 cookie。 如果 cookie 比较大意味着request和response的请求也会比较大，将会影响网站的访问速度。
如果你不小心泄露了你的 secret_key_base， 那就意味着你的用户可以伪造 cookie 入侵的你网站。
存储一些不安全的数据到 cookie。
如果你对这些问题都很小心的话，不是什么大问题。如果当年由于某些原因不想把 session 数据存储到 cookie里面的 话， rails 也提供了其他方式供你选择。

其他存储方式
虽然session数据不存储在 cookie 里面，但他们工作的流程基本类似。下面是实际的一个例子来解释下：

把 session 数据存储在数据库里面 1. 当年使用 session[:current_user_id] = 1 这个赋值。 2. Rails 将会创建一个 sessions 表产生一个随机的 session Id。（09497d46978bf6f32265fefb5cc52264） 3. 他将会存储 {current_user_id: 1} （Base 64编码）到 session 的 data 属性里面。 4. 而且将会返回 session id，然后将这个 id (09497d46978bf6f32265fefb5cc52264) 存到 cookie 里面发送到浏览器。

下次浏览器发送请求的时候

将会把 cookie 发送到服务器端：
```
Cookie: _my_app_session=09497d46978bf6f32265fefb5cc52264;
path=/; HttpOnly
```
当你使用 session[:current_user_id] 取值的时候
Rails 会使用这个 id 去 sessions 表里面查询出对应的 session 值。
最后从找到的记录的 data 属性里面返回 current_user_id
不管你的 session 存储在 数据库还是 memcache,还是 Redis 里面。大多数都是 按照这样的流程在工作。这个时候 cookie 只是存储的 session ID, rails 会 自己根据这个 ID 去找 session 里面存储的数据。

cookie，cache 还是数据库存储呢？
首先存储到 cookie 是最简单的，他不需要你设置什么额外的操作。如果不想存在 cookie,可以 选择存储到 数据库 或 cache 里面。

存储 session 到 cache
你可能已经使用 memcache 存储你的一些页面缓存。cache 是第二方便存储 session 的地方。 你不需要担心 session 过度增长的问题，因为旧的 session 会自动被删除掉如果 cache 变得很大。 而且他访问速度很快，就相当于访问内存数据一样。 但也有缺点的：

如果你想保存旧的 session 数据，可能你并不希望被删除掉。
你的 session 将会占空间，如果你没有足够的内存，会遇到内存很多被 占用的情况，或者 session 很早就过期了。
如果你想重置你的 cache，可能由于 rails 升级之类导致的，这样会导致所有人的 session 都失效了。
存储到数据库
如果你想保存旧的 session 直到过期之前，你可以考虑存储到数据库。例如 Redis 或者 ActiveRecord。 但是数据库存储也有缺点的：

如果存储到数据库，session 不会自动清理的。需要你自己手动做的。
你必须知道如果很多 session 数据的话，数据库有什么影响？ 例如： redis 的话，你必须保证有足够大的内存，不要一会就占满内存了。

你必须得小心，可能由于网络攻击或者网络蜘蛛导致产生大量无用的 session 数据，浪费了你的数据库空间。

大多数问题可能发生的比较少，但你必须有和这个意识。

该如何选择呢?
如果你确定 cookie 里面保存的缺点不会是问题的话，那就首选 cookie吧，毕竟不需要什么特殊配置，而且也不需要 特别维护。

cookie 之外，我一般首选 cache，然后是数据库。因为我认为 session 只是临时数据，所以放 cache 里面好一点。
