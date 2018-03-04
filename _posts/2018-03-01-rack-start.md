---
layout: post
toc: true
permalink: /rack-start
title: Ruby Rack 协议及其应用(一)
tags: Rack系列  rack  ruby  rails  server
desc:  Rack是Ruby应用服务器和Rack应用程序之间的一个接口,用于两者之间的交互. 不仅仅是大名鼎鼎的Ruby on Rails ,几乎所有的Ruby Web 框架都是一个Rack应用. 除了Web框架之外, Rack同样支持很多Ruby Web服务器. 本系列文章就深入探讨Rack协议的原理以及实现.
---

## Rack协议

### 什么是Rack

Rack是Ruby Web服务器和Rack应用程序之间的一个接口

![Rack接口](https//img.nju520/me/2018-03-03-rack.png)

上图给出了一个简单的图示. 当用户的请求抵达Web服务器时, Web服务器就会调用(call)Rack, Rack对请求进行包装, 然后调用Rack应用程序(一般是一个封装好的框架). Rack程序可以方便地利用Rack提供的各种API, 分析请求(request), 进行处理, 返回响应(response). 

### 为什么是Rack

Rack提供了一种标准的接口, 便于应用程序和Web服务器之间进行交互. 一个Rack应用程序可以被任何和Rack兼容的Web服务器调用.



目前几乎所有的主流Ruby服务器都支持Rack接口. Rack通过一种被称作句柄(Handler)的机制实现对Web服务器的支持.



另一方面, 几乎所有的主流Web框架都支持Rack接口. 这就意味着使用这些框架编写的应用程序都是标准的Rack应用程序.



Rack还有一个杀手锏:Rack中间件. Rack利用中间件(Middleware)实现最大程度的模块化编程. Rack中间件对Ruby Web框架也有很深的影响:

* 不同的Web框架之间可以重用中间件,这意味着你编写的一个中间件可以在几乎所有的主流框架中使用
* 可以通过不同的中间件组合组装出同一个Web框架的不同变种, 以适应不同的应用场合.
* 可以组合多个不同的Web应用框架为同一个更大的系统服务



### Rack的使用

Rack协议将Rack应用描述成一个可以响应call方法的Ruby对象, 它接收一个来自外界的参数(env),然后返回一个只包含三个值的数组. 

> A Rack application is an Ruby Object(not a class) that responds to call. It tasks exactly one argument, the enviroment and returns an Array of exactly three values: the status,  the headers, and the body.



一个Rack应用程序就是一个Ruby对象, 只要这个对象能够响应call. Ruby中能够响应call方法的对象很多, 包括:

* 一个 Proc 对象
* 一个 lambda 对象
* 一个 method 对象
* 任何一个对象, 它的类的实例方法中包含一个 call 方法



Rack应用对象接收一个环境(env)参数, 然后返回一个三元数组:

* 一个状态码(status), 即HTTP协议定义的状态码
* 一个头(headers), 是一个Hash, 包含了所有的HTTP header
* 一个响应体(body), 它是一个字符串数组



Rack在Web Server 和应用程序之间提供了最小的API接口, 如果Web Server都遵循Rack提供的这套规则, 那么所有的框架都能通过Rack协议使用Web Server. 

所有的Web Server只需要在Rack::Handler模块中实现一个 run方法的类即可:

~~~ruby
# Rack 内置的 Web Server:  WEBrick
module Rack
  module Handler
    class WEBrick < ::WEBrick::HTTPServlet::AbstractServlet
      def self.run(app, options = {})
        environment  = ENV['RACK_ENV'] || 'development'
        default_host = environment == 'development' ? 'localhost' : nil

        options[:BindAddress] = options.delete(:Host) || default_host
        options[:Port] ||= 8080
        @server = ::WEBrick::HTTPServer.new(options)
        @server.mount '/', Rack::Handler::WEBrick, app
        yield @server if block_given?
        @server.start
      end
    end
  end
end
~~~

这个类方法接收两个参数: Rack应用对象和包含各种参数的options 字典. 所有应用程序对象在接受到一个#call方法传来的env时, 都会返回一个三元组:

~~~ruby
[status, headers, body]
~~~

最后的body响应体是一个由多个响应内容组成的数组, Rack使用的Web Server会将body中几个部分连接到一起最后拼成一个完整的HTTP响应后返回.



我们可以使用Pry在 console中尝试使用Rack:

~~~shell
$ pry
[7] pry(main)> require 'rack'
=> false
[8] pry(main)> app = -> (env) {[200, {}, ["Hello World"]]}
=> #<Proc:0x00007fc1644f62d0@(pry):8 (lambda)>
[9] pry(main)> Rack::Handler::WEBrick.run app, Port: 3000

[2018-03-03 10:45:59] INFO  WEBrick 1.3.1
[2018-03-03 10:45:59] INFO  ruby 2.4.2 (2017-09-14) [x86_64-darwin17]
[2018-03-03 10:45:59] INFO  WEBrick::HTTPServer#start: pid=32799 port=3000

::1 - - [03/Mar/2018:10:46:23 CST] "GET /admin HTTP/1.1" 200 11
- -> /admin
::1 - - [03/Mar/2018:10:46:25 CST] "GET / HTTP/1.1" 200 11
- -> /
::1 - - [03/Mar/2018:10:46:26 CST] "GET /favicon.ico HTTP/1.1" 200 11
http://localhost:3000/ -> /favicon.ico

~~~

在浏览器中输入 `http://localhost:3000`, 就会出现`Hello World`.



除了使用 lambda外,我们的应用程序还可以使用method对象:

~~~ruby
[10] pry(main)> def my_method(env)
[10] pry(main)*   [200, {}, ['Hello World']]
[10] pry(main)* end
=> :my_method

[11] pry(main)> rack_app = method(:my_method)
=> #<Method: Object#my_method>
[12] pry(main)> rack_app.call({})
=> [200, {}, ["Hello World"]]
[13] pry(main)>

# 此处我们使用另外一个Web Server Thin
[14] pry(main)> Rack::Handler::Thin.run rack_app, Port: 3000
Thin web server (v1.7.2 codename Bachmanity)
Maximum connections set to 1024
Listening on localhost:3000, CTRL+C to stop
~~~



一个合法的Rack程序也可以是任何对象, 只要它的类定义了call方法:

~~~ruby
[15] pry(main)> class MyRackApp
[15] pry(main)*   def call(env)
[15] pry(main)*     [200, {}, ['Hello from MyRackApp']]
[15] pry(main)*   end
[15] pry(main)* end
=> :call
[16] pry(main)> rack_app = MyRackApp.new
=> #<MyRackApp:0x00007f8e6aecd880>
[17] pry(main)>
~~~



以上几种方式都是在 console中启动的Web Server 来处理浏览器的请求, 实际应用中一般是将代码统一放在 config.ru 文件中:

~~~ruby
# config.ru
run Proc.new { |env| ['200', {'Content-Type' => 'text/html'}, ['Hello World']] }
~~~

在同一目录下使用 backup 命令就可以启动一个 Web Server 进程:

~~~shell
# 如果文件名恰好为 config.ru, 我们可以省略配置文件直接运行 rackup
$ rackup config.ru

Puma starting in single mode...
* Version 3.11.2 (ruby 2.4.2-p198), codename: Love Song
* Min threads: 0, max threads: 16
* Environment: development
* Listening on tcp://localhost:9292
Use Ctrl-C to stop

~~~

>我们可以使用  httpie 工具代替 curl 在命令行中发出 HTTP请求, 这样可以直接在命令行中获取我们需要的诸多信息.

使用 http 工具发出请求:

~~~shell
http http:localhost:9292

HTTP/1.1 200 OK
Content-Type: text/html
Transfer-Encoding: chunked

Hello World
~~~

从上述请求返回的响应中可以看出, Puma 按照 config.ru文件中的代码对HTTP请求进行了处理

### Rack初探

本节探究一下Rack为Rack应用程序提供的几个基础接口和概念, 对Rack源码也解读一下.

#### 环境变量(env)

Rack用一个环境参数(env)来调调用Rack应用程序, 它是一个`Hash`实例,它包含了全部的HTTP请求信息.

首先将env对应的 key => value 打印出来:

~~~ruby
# !/usr/bin/env ruby
require 'rack'

app = lambda do |env|
  env.to_a.sort.each {|key, value| puts "#{key} => #{value}"}
  [200, {}, ['Hello World']]
end

Rack::Handler::Thin.run app, Port: 3000
~~~

这个简单的Rack应用程序会把env的内容都打印出来. 采用 http 发出请求 `http :3000/admin/?name=hwbnju`可以看到如下输出:

~~~~shell
GATEWAY_INTERFACE => CGI/1.2
HTTP_ACCEPT => */*
HTTP_ACCEPT_ENCODING => gzip, deflate
HTTP_CONNECTION => keep-alive
HTTP_HOST => localhost:8080
HTTP_USER_AGENT => HTTPie/0.9.9
HTTP_VERSION => HTTP/1.1
PATH_INFO => /admin
QUERY_STRING => name=hwbnju
REMOTE_ADDR => ::1
REQUEST_METHOD => GET
REQUEST_PATH => /
REQUEST_URI => /?name=hwbnju
SCRIPT_NAME =>
SERVER_NAME => localhost
SERVER_PORT => 3000
SERVER_PROTOCOL => HTTP/1.1
SERVER_SOFTWARE => thin 1.7.2 codename Bachmanity
async.callback => #<Method: Thin::Connection#post_process>
async.close => #<EventMachine::DefaultDeferrable:0x00007ffe978b6030>
rack.errors => #<IO:0x00007ffe950a27d8>
rack.input => #<StringIO:0x00007ffe978b67d8>
rack.multiprocess => false
rack.multithread => false
rack.run_once => false
rack.url_scheme => http
rack.version => [1, 0]
~~~~



环境变量大致可以分为两类:

* CGI变量: 

  * REQUEST_METHOD: HTTP请求的方法, 可以是 GET POST
  * PATH_INFO: 访问的路径, 此处为 `/admin`
  * QUERY_STRING: 查询字符串, 此处为 `name=hwbnju`

* rack特定的变量: `rack.**`

  * rack.input: 一个IO对象, 可以读取 raw HTTP request

  * rack,errors: 一个IO对象, 用于错误输出. Web服务器会把它输出到服务器日志文件. 它也是Rack::Logger以及 Rack::CommenLogger的输出对象

  * rack.hijack, rack.hijack? rack.hijack_to: 实现 websocket

  * rack.multiprocess, rack.multithread: 这两个对象知识了Rack应用的运行环境是否是多进程、多线程. 

    这里着重说明一下: Rack 服务器可以根据负载情况同时启动Rack应用的多个实例.一般来说,多进程方式比较安全: 如果要使用多线程, 不但要保证Rack应用程序是线程安全, 还需要保证Rack中间件是线程安全.

    * 即有可能通过多进程(每个进程是一个实例) Unicorn
    * 通过多线程(一个进程, 多个线程, 每个线程一个实例) Thin
    * 将二者结合起来(多进程, 同时每个进程内多个线程实例) Puma Passeger

  * rack.run_once: 服务器是否只运行Rack应用实例一次就把它释放掉. 这意味着服务器会对每个HTTP请求构造一个新的Rack应用实例(包括所有的中间件的初始化工作). 一般来说只有CGI服务器会这么做.

  * rack.url_scheme: http or https

  * rack.verison: rack spec 的版本



**Rack env 不但可以从Web Server向Rack应用程序和中间件传递这些信息, 还用于在Rack中间件中间或者中间件与应用程序之间传递消息**

![rack env](http://img.nju520.me/2018-03-03-rack-env.png)



现在可以想象我们自己编写一个Rack程序, 我可以直接判断用户请求的方法、路径名、查询参数等信息, 然后直接调用对应的处理程序, 非常高效地实现各种丰富多彩的功能.

但是直接存取环境虽然直接高效, 但却需要手工处理很多麻烦的事情. 比如解析查询的参数, 维护用户的会话信息, 处理浏览器不支持PUT的情况, 在响应时添加合适的HTTP头等等.



Rack提供了丰富的API可以帮助我们快速方便地编写灵活的应用逻辑. 我们从两个最重要的类开始研究: Request 和 Response

#### Rack::Request

我们可以将传入Rack应用程序的环境变量(env)是包含一次HTTP请求的所有参数信息.  在Rack内部是将 env 转换成一个 request对象进行操作. `Rack::Request`为存取 env 提供了方便的接口. 

> Rack::Request provides a convenient interface to a Rack environment.  It is stateless, the environment +env+ passed to the constructor will be directly modified.
>   req = Rack::Request.new(env)
>   req.post?
>   req.params["data"]

~~~ruby
request = Rack::Request.new
~~~

新创建的`request`对象直接持有传入的env对象并在需要的时候对它进行修改, 它自己没有任何状态.

我们可以通过Hash的形式取得用户请求的参数, 比如:

~~~ruby
request.params[:somekey]
~~~



下面的程序就是让用户猜测我们最喜欢的浏览器. 用户可以输入 http://localhost:3000/guess?client=XXX 这样的 url

~~~ruby
#! /usr/bin/env ruby
require 'rack'

app = -> (env) do
  request = Rack::Request.new(env)
  if request.path_info == '/guess'
    client = request['client']
    if client == 'chrome'
      [200, {}, ['Google Chrome']]
    else
      [200, {}, ['Please choose another browser']]
    end
  else
    [200, {}, ['you need guess something']]
  end
end

Rack::Handler::WEBrick.run app, :Port => 3000

~~~

当用户请求的 `path_info` 不是 `/guess`, 我们就返回`you need guess something`. 当用户输入的查询参数不包括 `client=chrome`时,我们则要求用户更换另外的浏览器名字.

我们直接用Hash存取用户的请求参数在很大程度上方便我们程序的实现.

`Rack::Request`提供了询问当前HTTP请求类型的简洁方法

* request_method: 请求的HTTP方法, 包含 GET POST PUT DELETE HEAD 
* get? : HTTP请求是否为 GET
* head? : HTTP请求是否为 HEAD
* post? : HTTP请求是否为 POST
* puts? : HTTP请求是否为 PUT
* xhr? : HTTP请求是否为 XMLHttpRequest请求(即Ajax请求)



##### 源码解读:

~~~ruby
# rack/lib/request.rb
# request 类比较简单, 主要是对 env 进行处理
# Rack::Request 本身是无状态的,  env 传入 Request对象的构造方法中, 它可以直接被修改
# 以下代码为节选, 完整代码请参考: 
# 重点说明一下 super 方法的使用
# 1. super       调用时, 将沿着继承链调用祖先类/模块的方法, 并携带传递给当前调用对象的全部方法参数
# 2. super()     调用时, 则不会传递调用者任何参数
# 3. super(a, b) 调用时, 则传递部分参数a, b

require 'rack/utils'
require 'rack/media_type'

module Rack
  class Request
    def initialize(env)
      @params = nil
      super(env)
    end
      
    def params
      @params ||= super
    end
      
    def update_param(k, v)
      super
      @params = nil
    end
      
    def delete_param(k)
      v = super
      @params = nil
      v  
    end
      
    # 对 header 进行操作的 helper
    module Env
      # the enviroment of the request
      attr_reader :env
      
      # env is an instance of Hash 
      def initialize(env)
        @env = env
        super()
      end
      
      def has_header?(name)
        @env.key? name
      end
        
      def fetch_header(name, &block)
      end
        
      def set_header(name, v)
      end
        
      def add_header(key, v)
      end
        
      def delete_header(name)
      end
        
      def initialize_copy(other)
        @env = other.env.dup
      end
    end
      
    # 一些辅助方法, 用来解析 env
    module Helpers
        
	  def body;  			get_header(RACK_INPUT); end
      def path_info;    	get_header(PATH_INFO); end
      def request_method;	get_header(REQUEST_METHOD); end
        
      # 判断请求的方法类型
      def get?;				request_method == GET; end
      def trace?;			request_method == TRACE; end
    end
      
    # 将上述两个模块 include 加入 Request类的继承链中
    # Rack::Request.ancestors
    #[Env, Helpers, ...]
    include Env
    include Helpers
  end
end
~~~



#### Rack::Response

前面的例子中我们都是手动构造返回数组, 但是在一个复杂的应用程序中, 我么可能需要对响应做更多的控制. 例如设置各种各样的HTTP响应头, 处理 cookie 等工作.

`Rack::Response`提供了对响应的状态、HTTP头和内容进行处理的方便接口

##### 响应体

`Request`提供了两种方式来生成响应体:

* 直接设置 `response.body`. 此时必须手动设置 `Content-Length` 的值
* 采用 `response.write` 增量写入内容, 自动填充 `Content-Length`的值

不管采用哪种方式, 最后都得采用` response.finish` 完成 `response`的构建. 除了一些必要的检查外, `finish` 将装配出符合Rack规范的一个三元数组,也就是之前手动返回的那个数组: [status, heades, body]



采用第一种形式构造 body:

~~~ruby

#! /usr/bin/env ruby
require 'rack'
require_relative 'decorator'

app = -> (env) do
 request = Rack::Request.new(env)
 response = Rack::Response.new

 body = "===========header==========<br/>"
 if request.path_info == '/hello'
   body << "you say hello"
   client = request['client']
   body << " from #{client}" if client
 else
   body << "you need provide some client information"
 end
 body << "<br/>===========footer=========="
 response.body = [body]
 response.headers['Content-Length'] = body.bytesize.to_s
 response.headers['Content-type'] = 'text/html' 
 response.finish
end

Rack::Handler::WEBrick.run app, :Port => 3000
~~~



采用第二种形式构造 body:

~~~ruby

#! /usr/bin/env ruby
require 'rack'
require_relative 'decorator'

app = -> (env) do
  request = Rack::Request.new(env)
  response = Rack::Response.new

  response.write("===========header==========<br/>")
  if request.path_info == '/hello'
    response.write("You say hello")
    client = request['client']
    response.write(" from #{client}") if client
  else
    response.write("You need provide some client information")
  end
  response.write"<br/>===========footer=========="
  response.headers['Content-type'] = 'text/html'  
  response.finish
end

# use Decorator
# run app
Rack::Handler::WEBrick.run app, :Port => 3000

~~~

##### 响应码

我们可以直接存取`Response`的对象来改变状态码. 如果没有任何设置, 状态码就为200.

Response还提供了一个 `redirect`方法直接进行重定向:

~~~ruby
redirect(target, status = 302)
~~~

### 响应头

我们还可以直接写入 `Response`的头信息 `headers`, 这是一个`Hash`

~~~ruby
response.headers['Content-Type'] = 'text/plain'
~~~



##### 源码解读

~~~ruby
require 'rack/request'
require 'rack/utils'
require 'rack/body_proxy'
require 'rack/media_type'
require 'time'

module Rack
  # Rack::Response 为创建 Rack response提供了简介的接口.
  # 它允许设置响应头(header) cookies
  # 我们可以使用 write 增量不断地写入响应内容, 直到调用 finish 结束
  
  class Response
  	attr_accessor :length, :status, :body
    attr_reader :header
    alias headers haeder
    
    def	initialize(body = [], status = [], header = [])
      @status = status.to_i
      @header = Utils::HeaderHash.new.merge(header)
      
      @writer = lambda {|x| @body << x} # 后续调用 @writer.call(x) 向body中添加内容
      @block = nil
      @length = 0
      @body = []
      if body.respond_to? :to_str
      	write body.to_str
      elsif body.respond_to? :each
      	body.each {|part| write part.to_s}
      else
      	raise TypeError, 'stringable or iterable required'
      end
      
      yield self if block_given?
    end
    
    def	finish(&block)
      @block = block
      
      if [204, 304].include?(status.to_i)
      	delete_header CONTENT_TYPE
      	delete_header CONETENT_LENGTH
      	close
      	[status.to_i, header, []]
      else
        [status, header, BodyProxy.new(self){}]
      end
    end
    
    # 向body后插入数据
    def write(str)
      s = str.to_s
      @length += s.bytesize unless chunked
      @writer.call s
      
      set_header(CONTENT_LENGTH, @length.to_s) unless chunked?
      str
    end
    
    # 关闭
    def close
      body.close if body.respond_to?(:close)
    end
    
    
  end
end
~~~



##Rack中间件

什么是中间件? 简单讲中间件就是在Ruby Web Server和Rack应用程序之间执行的代码. 

Rack协议和中间件是Rack能达到今天地位不可或缺的两个特性. Rack协议规定了 WebServer 和 Rack 应用程序之间应该如何通信, 而Rack中间件能够在上层改变HTTP的响应或者请求, 在不改变应用的基础上为Rack应用增加新的功能.

### 一个简单的中间件

前面一节中介绍`Rack::Response`时,我们在程序输出的前后分别添加了头信息和尾信息. 我们可以尝试把实际的程序输出和包装的过程剥离开来. 首先去掉头信息和尾信息的输出:

~~~ruby
#! /usr/bin/env ruby
require 'rack'
require_relative 'decorator'

app = -> (env) do
  request = Rack::Request.new(env)
  response = Rack::Response.new

  if request.path_info == '/hello'
    response.write("You say hello")
    client = request['client']
    response.write(" from #{client}") if client
  else
    response.write("You need provide some client information")
  end
  response.headers['Content-type'] = 'text/html'
  # response.finish 返回的正是 response 本身.
  response.finish
end

# use Decorator
# run app
Rack::Handler::WEBrick.run Decorator.new(app), :Port => 3000
	
~~~

最后一行我们采用的是

~~~ruby
Rack::Handler::WEBrick.run Decorator.new(app), Port: 3000
~~~

接下来我们就要定义一个 Decorator类, 创建 Decorator实例时传入原始的 rack_app 作为其参数. 这个实例也能够被Rack的Handler调用--显然这个实例也是合法的Rack应用程序. 因此 Decorator类需要一个call方法.

~~~ruby
# decorator.rb
class Decorator
  # 初始化方法接收一个标准的Rack应用程序参数, 并且可以传入 代码块
  def initialize(app, &block)
    @app = app
    @block = @block
  end
  
  def call(env)
    status, headers, body = @app.call(env)
    new_body = "===========header==========<br/>"
    # 这里的body实际上是一个 response实例, 它能够响应`each`方法
    body.each {|str| new_body << str}
    new_body << "<br/>===========footer=========="
    headers['Content-Length'] = new_body.bytesize.to_s
    
    # 最后返回加上头尾信息的新的三元数组
    [status, headers, [new_body]]
  end
end
~~~

运行程序, 我们可以在命令行中得到和之前一样的结果:

~~~shell
$ http http://localhost:3000/hello
===========header==========
You say hello
===========footer==========
~~~



### Rack响应的标准

**任何中间件本身必须是一个合法的Rack应该程序**

Rack协议要求Rack应用程序的call方法返回一个数组, 包含三个成员

* status(状态码): 这是一个HTTP状态, 不一定是整数, 但是必须能够响应`to_i`方法并返回一个整数
* headers(响应头): 这个头必须能够响应`each`放啊, 并且每次产生一个key和value.
* body(响应体): 必须能够响应`each`方法, 而且每次必须产生一个字符串.  Rack::Response的实例是合法的响应体, 应为它能够正确响应`each`方法.所以body不一定非得是数组, 只要能响应`each`方法即可.



中间件可以实现 通用逻辑和业务逻辑分离, 这些通用的逻辑可以被应用到各种各样不同的业务逻辑.

比如说我们实现了一个用于身份认证的中间件, 那么这个中间件就可以应用到任何Rack应用程序中.

由于几乎所有的Ruby Web框架编写的应用程序都是Rack应用, 因此任何Web应用程序都可以不加修改地使用我们编写的身份认证中间件来实现用户身份认证.



![中间件架构]()

Web框架的作者可以用中间件的形式实现整个框架. 由于中间件本身也是合法的Rack应用程序, 这就意味着中间件外面还可以包装中间件. 原先需要单片实现的整个框架被分割成多个中间件, 每个中间件只关系自己需要实现的功能. 这样的好处显而易见:

* 每个中间件独立开发, 甚至可以被独立地替换
* 我们可以用不同方式去组合中间件, 最大程度低满足不同应用程序的需要


### 装配中间件

我们往往需要在一个应用程序里面装载很多中间件, 最直接的方式是采用 `new` 方法. 

~~~ruby
# 两个中间件 Middleware1 Middleware2, 一个应用程序 rack_app
Rack::Handler::Thin.run(Middleware1.new(Middleware2.new(rack_app, options2), options1))
~~~

如果我们要使用很多中间件, 上述代码肯定会越来越繁琐.在Ruby中,我们可以使用`DSL`来优雅地装配中间件:

~~~ruby
class Builder
  # 加入中间件
  def use
  end
  
  # 加入应用程序
  def run
  end
end

# Builder生成一个最终程序
app = Builder.new {
    use Middleware1
    use Middleware2
    run RackApplication
}.to_app
# 启动Web Server来运行此app
Rack::Handler::XXX.run app
~~~

`use`  和 `run`  作为DSL中的动词. 这些DSL使用的范围通常是一个 `block`

* use: 使用一个中间件
* run: 运行原始的rack程序(在Rack源代码中run也仅仅是将原始的rack程序加入中间件栈中, 并没有运行)



前述例子中`Decorator` 只必须得在生成新的响应体 `new_body`以后设置新的 `Content-Type`:

~~~ruby
headers['Content-Type'] = new_body.bytesize.to_s
~~~

Rack自带了很多中间件, 其中一个中间件就是 `Rack::ContentLength`, 它可以自动设置响应中的`Content-Length. 我们可以使用如下方式使用 `Rack` 自带的中间件:

~~~ruby
#! usr/bin/env ruby
require 'rack'
require 'decorator'

app = Builder.new {
    use Rack::ContentLength
    use Decorator
    run lambda {|env| [200, {"Content-Type" => "text/html"}, ["Hello World"]]}
}.to_app

Rack::Handler::WEBrick.run app, Port: 3000

~~~

~~~ruby
# decorator.rb
class Decorator
  def initialize(app, &block)
    @app = app
    @block = @block
  end
  
  def call(env)
    status, headers, body = @app.call(env)
    new_body = ""
    new_body << "===========header==========<br/>"
    body.each {|str| new_body << str}
    new_body << "<br/>===========footer=========="
    # 注释掉下面一行, 采用Rack自带的中间件自动添加头部信息: Content-Length
    # headers['Content-Length'] = new_body.bytesize.to_s
    
    # 最后返回加上头尾信息的新的三元数组
    [status, headers, [new_body]]
  end
end
~~~



万事俱备, 只欠东风. 现在我们还是思考如何实现`Builder`.

根据上面的模板, 我们对 `Builder`几个方法要求如下:

* initialize: 签名应该是 initialize(&block). 为了能够让 `use`、`run`这些方法称为DSL语言的**动词**,initialize应该 `initialize_eval`当前实例
* use: 签名应该是 `use(middleware_class, options, &block). 它应该记录需要创建的中间件以及它们的顺序. 同时还可以保存传入中间件时携带的参数和代码块
* run: 签名应该为 `run(rack_app)`. 记录原始的`rack应该程序`
* to_app: 根据`use`和`run`记录的信息创建出最终的应用程序



#### 简单实现

我们首先通过传统方法来实现`Builder`, 用数组记录所有需要创建的中间件信息, 最后`to_app`时候把它们创建出来

~~~ruby
#Rack应用构造类
class Builder
  def initialize(&block)
    @middlewares = []
    self.instance_eval(&block)
  end

  def use(middleware)
    @middlewares << middleware
  end

  def run(app)
    @app = app
  end

  def to_app
    @middlewares.reverse.inject(@app) {|app, middleware| middleware.new(app)}
  end

end
~~~

`Builder`类中`to_app`的实现,首先对加入的`middlewares`进行了`reverse`,这是因为对所有使用的中间件, 我们必须持有它们的顺序信息. 第一个被`use`的中间件包在最外面一层, 第二个被`use`的中间件在第二层, 依次类推, 直至包含了原始的`Rack应用程序`. 



#### 更`Ruby`化的实现

上面传统的方法有一定的局限性. 例如如果我们需要在`use`中间件的过程中带上一些选项, 甚至执行某些代码. `use`描述的是中间件创建的过程, 创建过程需要携带自动的参数, 需要执行某些代码--但是这个创建过程并不是在现在就要被执行, 而是在`to_app`时候被执行.



**对那些需要在以后执行的代码, Ruby给出了最好的解决答案就是`lambda`**.

~~~ruby
class Builder
  def initialize(&block)
    @middlewares = []
    self.instance_eval(&block)
  end

  def use(middleware_class, *options, &block)
    @middlewares << lambda {|app| middleware_class.new(app, *options, &block)}
  end

  def run(app)
    @app = app
  end

  def to_app
    @middlewares.reverse.inject(@app) {|app, middleware| middleware.call(app)}
  end
end

~~~

`use`方法把中间件的创建过程以`lambda`的方式保存在`@middlewares`数组中, 而中间件的创建过程就是以`app`为参数创建一个最终版的`app`.

我们可以修改之前的`Decorator`, 为其加上参数配置和代码块.

~~~ruby
#! /usr/bin/env ruby
require 'rack'

class Decorator

  def initialize(app, *options, &block)
    @app = app
    @options = (options[0] || {})
    @block = block
  end

  def call(env)
    # body is an instance of Array
    status, headers, body = @app.call(env)
    @block.call if @block

    new_body = ""
    new_body << (@options[:header] || "===========header==========<br/>")
    body.each {|str| new_body << str}
    new_body << (@options[:footer] || "<br/>===========footer==========")
    [status, headers, [new_body]]
  end
end

~~~

 

最后修改一下我们的运行程序, 为`Decorator`添加参数和代码块

~~~ruby
# my_app.rb
# !/usr/bin/env ruby

require 'rack'
require_relative 'builder'
require_relative 'decorator'

app = Builder.new {
  use Rack::ContentLength
  use Decorator, header: '************* header ****************<br/>'
  run lambda { |env| [200, {'Content-Type' => 'text/html'}, ['Hello World']] }
}.to_app

Rack::Handler::WEBrick.run app, Port: 3000
	
~~~

运行程序, 我们可以看到如下输出:

~~~shell
$ ./my_app.rb
λ ruby my_app.rb
[2018-03-04 09:57:04] INFO  WEBrick 1.3.1
[2018-03-04 09:57:04] INFO  ruby 2.4.2 (2017-09-14) [x86_64-darwin17]
[2018-03-04 09:57:04] INFO  WEBrick::HTTPServer#start: pid=32569 port=3000
::1 - - [04/Mar/2018:09:57:07 CST] "GET /hello HTTP/1.1" 200 85
- -> /hello
::1 - - [04/Mar/2018:09:58:59 CST] "GET /hello HTTP/1.1" 200 85
- -> /hello
::1 - - [04/Mar/2018:09:58:59 CST] "GET /favicon.ico HTTP/1.1" 200 85
http://localhost:3000/hello -> /favicon.ico


************* header ****************
Hello World
===========footer==========
~~~





以上主要对`Rack`进行了简单的介绍, 并且自行实现了中间件的构造和装载代码. 

下一篇着重研究`Rack`源码, 以及Web Server的启动过程

