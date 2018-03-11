---
layout: post
toc: true
permalink: /rack-webrick
title: WEBrick 源码分析
tags: rack webrick socket thread
desc: WEBrick是 Ruby 最古老的一款 Web Server, 本文就从源码入手, 解读 WEBrick的实现原理, 从线程和进程的角度分析 WEBrick的优缺点.  
---

`WEBrick`是`Rack`自带的一个 `Web Server`, 历史悠久, 代码量一共才 4000多行. 本文就从源码入手, 解读 `WEBrick`实现原理, 并从进程和线程的角度来分析 `WEBrick` 的优缺点.



## 源码分析

我们知道 `WEBrick`是`Rack`自带的 `WEB Server`,  它的`Handler`是在`Rack`中实现的, 它的运行也是从这个`Handler`开始的.

~~~ruby
[2] pry(main)> $ Rack::Handler::WEBrick.run

From: **/gems/rack-2.0.3/lib/rack/handler/webrick.rb @ line 25:
Owner: #<Class:Rack::Handler::WEBrick>
Visibility: public
Number of lines: 11

def self.run(app, options={})
  environment  = ENV['RACK_ENV'] || 'development'
  default_host = environment == 'development' ? 'localhost' : nil

  options[:BindAddress] = options.delete(:Host) || default_host
  options[:Port] ||= 8080
  @server = ::WEBrick::HTTPServer.new(options)
  @server.mount "/", Rack::Handler::WEBrick, app
  yield @server  if block_given?
  @server.start
end
~~~

  我在 `Rack`协议以及应用中介绍`Rack`的实现原理时, 最终就调用到上述`run`方法. 我们就从此方法开始解读`WEBrick`的源码.

  在`run`方法中, 先处理传入的一些参数比如 `host` `port` `enviroment`. 在这之后会使用`WEBrick`提供的`HTTPServer`创建一个 `server`实例.  `@server`实例会调用`mount`在根路由上挂载应用程序`app`和 `Rack::Handler::WEBrick`. 最后调用 `#start`方法启动服务器.



### 初始化服务器

`HTTPServer`初始化分为两个阶段, 首先是调用父类的 `initialize`方法, 进行一些配置; 然后是其本身的初始化. 在`HTTPServer`构造器中, 会配置当前服务器能够处理的 `HTTP`版本并出示还一个新的`MountTable`实例.

~~~ruby
[2] pry(main)> require 'webrick'
=> true
[3] pry(main)> $ WEBrick::HTTPServer#initialize

From: **/lib/ruby/2.4.0/webrick/httpserver.rb @ line 46:
Owner: WEBrick::HTTPServer
Visibility: private
Number of lines: 19

  class HTTPServer < ::WEBrick::GenericServer
	#...
    def initialize(config={}, default=Config::HTTP)
      # 调用父类 `GenericServer` 初始化方法
      super(config, default)
      @http_version = HTTPVersion::convert(@config[:HTTPVersion])

      #创建一个 `MountTable`实例
      @mount_tab = MountTable.new
      if @config[:DocumentRoot]
        mount("/", HTTPServlet::FileHandler, @config[:DocumentRoot],
              @config[:DocumentRootOptions])
      end

      unless @config[:AccessLog]
        @config[:AccessLog] = [
          [ $stderr, AccessLog::COMMON_LOG_FORMAT ],
          [ $stderr, AccessLog::REFERER_LOG_FORMAT ]
        ]
      end

      @virtual_hosts = Array.new
    end
  end
~~~

`WEBrick::HTTPServer`父类`WEBrick::GenericServer`中初始化用于监听端口号的 `socket`连接:

~~~ruby
From: **/lib/ruby/2.4.0/webrick/server.rb @ line 89:
Owner: WEBrick::GenericServer
Visibility: private
Number of lines: 26

#.方法有删减, 去除一些不必要的配置
def initialize(config={}, default=Config::General)
  @config = default.dup.update(config)
  @status = :Stop
  @config[:Logger] ||= Log::new
  @logger = @config[:Logger]

  
  @listeners = []
  unless @config[:DoNotListen]
    if @config[:Listen]
      warn(":Listen option is deprecated; use GenericServer#listen")
    end
    # 在此创建一系列的 `listeners`
    listen(@config[:BindAddress], @config[:Port])
    if @config[:Port] == 0
      @config[:Port] = @listeners[0].addr[1]
    end
  end
end

##
# Adds listeners from +address+ and +port+ to the server.  See
# WEBrick::Utils::create_listeners for details.

def listen(address, port)
  @listeners += Utils::create_listeners(address, port)
end

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

[8] pry(main)> $ WEBrick::Utils.create_listeners

From: **/lib/ruby/2.4.0/webrick/utils.rb @ line 61:
Owner: #<Class:WEBrick::Utils>
Visibility: public
Number of lines: 13

def create_listeners(address, port)
  unless port
    raise ArgumentError, "must specify port"
  end
  # 创建一组 `socket`
  sockets = Socket.tcp_server_sockets(address, port)
  sockets = sockets.map {|s|
    s.autoclose = false
    # 为文件描述符`s.fileno`创建一个新的 `TCPServer`实例
    ts = TCPServer.for_fd(s.fileno)
    # 关闭 当前 `socket`
    s.close
    ts
  }
  return sockets
end
~~~

每一个服务器在初始化期间都会创建一系列的`listeners`用于监听地址和端口号组成的元组.

`Socket#tcp_server_scokets`会创建一组`scoket`, 实际上返回两个套接字, 一个可以通过`IPV4`连接, 一个可以通过`IPV6`连接,两者都在同一个端口上进行侦听. 通过`TCPServer.for_fd`	我们又基于`socket#fileno`创建了 `TCPServer` 的实例. 最后`create_listeners`返回数组形式的`TCPServer`实例.

### 挂载应用

在使用`WEBrick`启动服务的时候, 第二个阶段就是将`Handler`和`Rack应用程序`挂载到根路由下

~~~ruby
@server.mount "/", Rack::Handler::WEBrick, app
~~~

`WEBrick::HTTPServer#mount`方法非常简单. 在`初始化服务器`阶段我们曾创建了一个`MountTable`的实例, 这一步只是将传入的多个参数放到这个表中:

~~~ruby
[9] pry(main)> $ WEBrick::HTTPServer#mount

From: **/lib/ruby/2.4.0/webrick/httpserver.rb @ line 155:
Owner: WEBrick::HTTPServer
Visibility: public
Number of lines: 4

def mount(dir, servlet, *options)
  @logger.debug(sprintf("%s is mounted on %s.", servlet.inspect, dir))
  @mount_tab[dir] = [ servlet, options ]
end

mount '/', Rack::Handler::WEBrick, app
mount '/admin', Rack::Hanlder::WEBrick, admin_app
mount '/worker', Rack::Handler::WEBrick, worker_app
~~~

`MountTable`实际上是一个包含从路由到`Rack 应用App`的映射表

![映射](MountTable)



当初始化 `MountTable`时会调用`MountTable#compile`方法. `MountTable`会将表中的所有键按照加入顺序的逆序拼接成一个如下的正则表达式用来匹配传入的路由:

~~~ruby
^(/|/admin|/user)(?=/|$)
~~~

上述正则表达式在使用时如果匹配到了指定的路由就会返回`$&`和`$`两部分.

* `$&`: 匹配的整个文本
* `$`匹配文本后面的字符串



~~~ruby
[12] pry(main)> $ WEBrick::HTTPServer::MountTable#initialize

From: **/lib/ruby/2.4.0/webrick/httpserver.rb @ line 234:
Owner: WEBrick::HTTPServer::MountTable
Visibility: private
Number of lines: 4

def initialize
  @tab = Hash.new
  compile
end

def compile
  k = @tab.keys
  k.sort!
  k.reverse!
  k.collect!{|path| Regexp.escape(path) }
  @scanner = Regexp.new("^(" + k.join("|") +")(?=/|$)")
end
~~~

 



### 启动服务器

在`Rack::Handler::WEBrick`中的`.run`方法第一阶段进行`@server`的初始化工作, 并将`Handler`挂载到根路由上, 最后执行	`#start`方法启动服务器:

~~~ruby
From: **/lib/ruby/2.4.0/webrick/server.rb @ line 152:
Owner: WEBrick::GenericServer
Visibility: public
Number of lines: 64

##
# Starts the server and runs the +block+ for each connection.  This method
# does not return until the server is stopped from a signal handler or
# another thread using #stop or #shutdown.
# 方法有删减, 主要是移除日志打印
def start(&block)
  raise ServerError, "already started." if @status != :Stop

  setup_shutdown_pipe

  server_type.start{
    @logger.info "#{self.class}#start: pid=#{$$} port=#{@config[:Port]}"
    @status = :Running
    # 执行回调
    call_callback(:StartCallback)

    shutdown_pipe = @shutdown_pipe

    thgroup = ThreadGroup.new
    begin
      while @status == :Running
        begin
          sp = shutdown_pipe[0]
          # 监听一组`Socket`
          if svrs = IO.select([sp, *@listeners])
            # for_reading TCPSocket
            svrs[0].each{|svr|
              @tokens.pop          # blocks while no token is there.
              # accept 连接
              if sock = accept_client(svr)
                # 开启新的线程处理请求
                th = start_thread(sock, &block)
                th[:WEBrickThread] = true
                thgroup.add(th)
              else
                @tokens.push(nil)
              end
            }
          end
        rescue Errno::EBADF, Errno::ENOTSOCK, IOError => ex
          # if the listening socket was closed in GenericServer#shutdown,
          # IO::select raise it.
        rescue StandardError => ex
          msg = "#{ex.class}: #{ex.message}\n\t#{ex.backtrace[0]}"
          @logger.error msg
        rescue Exception => ex
          @logger.fatal ex
          raise
        end
      end
    ensure
      cleanup_shutdown_pipe(shutdown_pipe)
      cleanup_listener
      @status = :Shutdown
      @logger.info "going to shutdown ..."
      # 管理线程
      thgroup.list.each{|th| th.join if th[:WEBrickThread] }
      call_callback(:StopCallback)
      @logger.info "#{self.class}#start done."
      @status = :Stop
    end
  }
end

~~~



上述代码包括处理服务器的关闭, 接收 `socket`请求, 我们可以把接收并处理`socket`请求抽象出来 

~~~ruby
def start(&block)
  raise ServerError, "already started." if @status != :Stop

  @status = :Running
  begin
    while @status == :Running
      begin
        if svrs = IO.select([*@listeners], nil, nil, 2.0)
          svrs[0].each{ |svr|
            sock = accept_client(svr)
            start_thread(sock, &block)
          }
        end
      rescue Errno::EBADF, Errno::ENOTSOCK, IOError, StandardError => ex
      rescue Exception => ex
        raise
      end
    end
  ensure
    cleanup_listener
    @status = :Stop
  end
end
~~~

关键部分为 `IO.select`. `IO.select`方法对一组`Socket`进行监听, 当有消息需要处理时就依次执行`#accept_client`和`#start_thread`两个方法处理来自客户端的请求.

~~~ruby
From: **/lib/ruby/2.4.0/webrick/server.rb @ line 254:
Owner: WEBrick::GenericServer
Visibility: private
Number of lines: 14

def accept_client(svr)
  sock = nil
  begin
    sock = svr.accept
    sock.sync = true
    Utils::set_non_blocking(sock)
  rescue Errno::ECONNRESET, Errno::ECONNABORTED,
         Errno::EPROTO, Errno::EINVAL
  rescue StandardError => ex
    msg = "#{ex.class}: #{ex.message}\n\t#{ex.backtrace[0]}"
    @logger.error msg
  end
  return sock
end
~~~



`WEBrick::GenericServer#accept_client`方法中调用`accept` 获得一个`TCP`客户端的`Socket`,通过设置`set_non_blocking`将该`Socket`变为非阻塞的, 最后在方法末尾返回创建的`Socket`.



~~~ruby
From: **/lib/ruby/2.4.0/webrick/server.rb @ line 278:
Owner: WEBrick::GenericServer
Visibility: private
Number of lines: 32
#代码有删减, 移除日志打印、异常处理等
def start_thread(sock, &block)
  Thread.start{
    begin
      Thread.current[:WEBrickSocket] = sock
      # 回调
      call_callback(:AcceptCallback, sock)
      # 处理请求
      block ? block.call(sock) : run(sock)
    ensure
      @tokens.push(nil)
      Thread.current[:WEBrickSocket] = nil
      sock.close
    end
  }
end
~~~



`WEBrick::GenericServer#start_thread`方法会开启一个新的线程, 在此线程中处理`HTTP 请求` 



### 处理请求

处理`HTTP` 请求的逻辑并不是由通过服务器`GenericServer`处理, 它只处理通用的逻辑. 对于`HTTP`请求的处理都是在`HTTPServer#run`方法中完成:

~~~ruby
From: **/lib/ruby/2.4.0/webrick/httpserver.rb @ line 69:
Owner: WEBrick::HTTPServer
Visibility: public
Number of lines: 52

# 代码有删减, 移除日志打印和一些异常处理和回调处理
def run(sock)
  while true
    res = HTTPResponse.new(@config)
    req = HTTPRequest.new(@config)
    server = self
    begin
      timeout = @config[:RequestTimeout]
      while timeout > 0
        break if sock.to_io.wait_readable(0.5)
        break if @status != :Running
        timeout -= 0.5
      end
      raise HTTPStatus::EOFError if timeout <= 0 || @status != :Running
      raise HTTPStatus::EOFError if sock.eof?
      # 解析请求
      req.parse(sock)
      res.request_method = req.request_method
      res.request_uri = req.request_uri
      res.request_http_version = req.http_version
      res.keep_alive = req.keep_alive?
      # 处理响应
      # 此方法中就会涉及我们之前分析的`Rack`以及`Middleware`
      server.service(req, res)
    ensure
      if req.request_line
        if req.keep_alive? && res.keep_alive?
          req.fixup()
        end
        # 发送响应
        res.send_response(sock)
        server.access_log(@config, req, res)
      end
    end
    break if @http_version < "1.1"
    break unless req.keep_alive?
    break unless res.keep_alive?
  end
end
~~~

`WEBrick::HTTPServer#run`主要工作涉及三个方面:

* 等待监听的`Socket`变成 `readable`
* 执行`#parse`方法解析`Socket`上的数据
* 最后调用`#service`方法完成处理请求的响应

我们依次解读:

#### 监听 `Socket`

~~~ruby
sock.to_io.wait_readable
~~~



#### 解析 `request`

调用`parse`对请求`request`进行解析:

~~~ruby
From: **/lib/ruby/2.4.0/webrick/httprequest.rb @ line 192:
Owner: WEBrick::HTTPRequest
Visibility: public
Number of lines: 47

def parse(socket=nil)
  @socket = socket
  begin
    @peeraddr = socket.respond_to?(:peeraddr) ? socket.peeraddr : []
    @addr = socket.respond_to?(:addr) ? socket.addr : []
  rescue Errno::ENOTCONN
    raise HTTPStatus::EOFError
  end

  read_request_line(socket)
  
  return if @request_method == "CONNECT"
  return if @unparsed_uri == "*"

  begin
    setup_forwarded_info
    # 设置一些 实例属性, 为后续处理请求做准备
    @request_uri = parse_uri(@unparsed_uri)
    @path = HTTPUtils::unescape(@request_uri.path)
    @path = HTTPUtils::normalize_path(@path)
    @host = @request_uri.host
    @port = @request_uri.port
    @query_string = @request_uri.query
    @script_name = ""
    @path_info = @path.dup
  rescue
    raise HTTPStatus::BadRequest, "bad URI `#{@unparsed_uri}'."
  end

  if /close/io =~ self["connection"]
    @keep_alive = false
  elsif /keep-alive/io =~ self["connection"]
    @keep_alive = true
  elsif @http_version < "1.1"
    @keep_alive = false
  else
    @keep_alive = true
  end
end
~~~

上述代码主要是对`HTTP`请求的解析, 具体内容还要参阅源码. 



#### 处理 `service`

在处理完`HTTP请求`之后, 就可以执行`#service`来响应该`HTTP请求`了:

~~~ruby
From: **/lib/ruby/2.4.0/webrick/httpserver.rb @ line 125:
Owner: WEBrick::HTTPServer
Visibility: public
Number of lines: 17

# 移除 OPTIONS 请求的逻辑代码
def service(req, res)

  servlet, options, script_name, path_info = search_servlet(req.path)
  raise HTTPStatus::NotFound, "`#{req.path}' not found." unless servlet
  req.script_name = script_name
  req.path_info = path_info
  # 返回一个 `servlet`实例
  si = servlet.get_instance(self, *options)
  @logger.debug(format("%s is invoked.", si.class.name))
  # 调用实例的 `service`
  si.service(req, res)
end

def search_servlet(path)
  script_name, path_info = @mount_tab.scan(path)
  servlet, options = @mount_tab[script_name]
  if servlet
    [ servlet, options, script_name, path_info ]
  end
end

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[29] pry(main)> $ WEBrick::HTTPServer::MountTable#scan

From: **/lib/ruby/2.4.0/webrick/httpserver.rb @ line 258:
Owner: WEBrick::HTTPServer::MountTable
Visibility: public
Number of lines: 4

def scan(path)
  @scanner =~ path
  [ $&, $' ]
end
~~~



通过调用`search_servlet`定位到之前注册的`Handler`以及`Rack应用程序`.

得到了`Handler`之后, 通过`get_instance`获得一个新的实例, 随后又调用了该`Rack::Handler::WEBrick`的`service`方法:

~~~ruby
From: **/gems/rack-2.0.3/lib/rack/handler/webrick.rb @ line 57:
Owner: Rack::Handler::WEBrick
Visibility: public
Number of lines: 61

def service(req, res)
  res.rack = true
  # 将 `request`的 `meta_vars`赋值给 `env`(环境变量)
  env = req.meta_vars
  env.delete_if { |k, v| v.nil? }

  # 请求携带的内容
  rack_input = StringIO.new(req.body.to_s)
  rack_input.set_encoding(Encoding::BINARY)

  # 更新 env
  env.update(
    RACK_VERSION      => Rack::VERSION,
    RACK_INPUT        => rack_input,
    RACK_ERRORS       => $stderr,
    RACK_MULTITHREAD  => true,
    RACK_MULTIPROCESS => false,
    RACK_RUNONCE      => false,
    RACK_URL_SCHEME   => ["yes", "on", "1"].include?(env[HTTPS]) ? "https" : "http",
    RACK_IS_HIJACK    => true,
    RACK_HIJACK       => lambda { raise NotImplementedError, "only partial hijack is supported."},
    RACK_HIJACK_IO    => nil
  )

  env[HTTP_VERSION] ||= env[SERVER_PROTOCOL]
  env[QUERY_STRING] ||= ""
  unless env[PATH_INFO] == ""
    path, n = req.request_uri.path, env[SCRIPT_NAME].length
    env[PATH_INFO] = path[n, path.length-n]
  end
  env[REQUEST_PATH] ||= [env[SCRIPT_NAME], env[PATH_INFO]].join

  # 关键部分: Rack应用 接收 env 返回一个三元数组
  status, headers, body = @app.call(env)
  begin
    res.status = status.to_i
    io_lambda = nil
    headers.each { |k, vs|
      if k == RACK_HIJACK
        io_lambda = vs
      elsif k.downcase == "set-cookie"
        res.cookies.concat vs.split("\n")
      else
        # Since WEBrick won't accept repeated headers,
        # merge the values per RFC 1945 section 4.2.
        res[k] = vs.split("\n").join(", ")
      end
    }

    if io_lambda
      rd, wr = IO.pipe
      res.body = rd
      res.chunked = true
      io_lambda.call wr
    elsif body.respond_to?(:to_path)
      res.body = ::File.open(body.to_path, 'rb')
    else
      # 将 body中的数据依次加入到 `res.body`中
      body.each { |part|
        res.body << part
      }
    end
  ensure
    body.close  if body.respond_to? :close
  end
end
~~~

上述代码主要完成以下几个工作:

* 构建`Rack应用`的环境变量`env`.
* 调用`#call` 返回一个三元数组: [status, headers, body]
* 对返回的三个元素进行处理, 填充此次请求的 `response`



#### 发送 响应

我们的 `response`构造成功后, 下一步就要将数据发送给请求的客户端

~~~ruby
From: lib/webrick/httpserver.rb @ line 69:
Owner: WEBrick::HTTPServer

def run(sock)
  while true
    res = HTTPResponse.new(@config)
    req = HTTPRequest.new(@config)
    server = self
    begin
      # ...
    ensure
      # 发送响应
      res.send_response(sock) if req.request_line
    end
  end
end


+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[35] pry(main)> $ WEBrick::HTTPResponse#send_response
From: **/lib/ruby/2.4.0/webrick/httpresponse.rb @ line 205:
Owner: WEBrick::HTTPResponse
Visibility: public
Number of lines: 13

def send_response(socket)
  begin
    setup_header()
    # 发送头部数据
    send_header(socket)
    # 发送 body 数据
    send_body(socket)
  rescue Errno::EPIPE, Errno::ECONNRESET, Errno::ENOTCONN => ex
    @logger.debug(ex)
    @keep_alive = false
  rescue Exception => ex
    @logger.error(ex)
    @keep_alive = false
  end
end

def setup_header
  # 处理 chunked 的请求
  app_chunking = rack && @header['transfer-encoding'] == 'chunked'
  @chunked = app_chunking if app_chunking
  _rack_setup_header
  @chunked = false if app_chunking
end


def send_header(socket) # :nodoc:
  if @http_version.major > 0
    data = status_line()
    @header.each{|key, value|
      tmp = key.gsub(/\bwww|^te$|\b\w/){ $&.upcase }
      data << "#{tmp}: #{value}" << CRLF
    }
    @cookies.each{|cookie|
      data << "Set-Cookie: " << cookie.to_s << CRLF
    }
    data << CRLF
    # 最终调用 _write_data 写入数据
    _write_data(socket, data)
  end
end


def send_body(socket) # :nodoc:
  if @body.respond_to? :readpartial then
    send_body_io(socket)
  else
    send_body_string(socket)
  end
end
    
    
~~~

上述所有的 `send_*`方法最终都会调用 `_write_data`, 往 `socket`中写入数据

~~~ruby
From: **/lib/ruby/2.4.0/webrick/httpresponse.rb @ line 464:
Owner: WEBrick::HTTPResponse
Visibility: private
Number of lines: 3

def _write_data(socket, data)
  socket << data
end
~~~



至此, 我们的 `Web Server`经过以下几步完成一个客户端请求的处理

* 解析`HTTP请求`

* 调用`Rack应用程序` 

* 构造`Response`

* 向 `Socket`写入数据

  ​



## 拓展知识



### IO.select

> 连接复用是指同时处理多个活动套接字. 这里并不是指并行处理, 也和多线程无关.

我们可以使用`IO.select`来处理多个`TCP`连接:

~~~ruby
connections = [<TCPSocket>, <TCPSocket>, <TCPSocket>]

loop do
  ready = IO.select(connections)
  readable_connections = ready[0]
  readable_connections.each do |conn|
    data = conn.readpartial(4096)
    process(data)
  end
end
~~~

`IO.select`的作用就是接受若干个`IO`对象, 然后告知哪一个可以进行读写, 这样我们就不必一直`retry`.



`IO.select`是一个同步方法调用. 按照它的设计来使用就会造成阻塞, 直到传入的`IO`对象状态发生变化, 此时它会立刻返回.  如果多个对象状态发生变化, 那么全部都通过嵌套数组立刻返回.



来看一下 `IO.slect`的参数:

~~~ruby
IO.select(read_array[, write_array[, error_array[, timeout]]] )
~~~

* read_array: 希望从中读取的`IO` 对象数组
* write_array:  希望进行写入的`IO`对象数组
* error_array: 在异常条件下使用的`IO`对象数组
* timeout: 超时时间(秒). 它可以避免`IO.select`永久地阻塞下去

`IO.select`返回一个三元数组:

* 可以进行无拥塞读取的`IO`对象数组
* 可以进行无拥塞写入的`IO`对象数组
* 适用异常条件的对象数组



`IO.select`来自`Ruby`的核心代码库. 它是`Ruby`中进行连接复用的唯一手段. 大多数现代操作系统都支持多种复用方法, `select`几乎总是这些方法最古老, 也是使用最少的那个.



`IO.select`在少数情况下表现还不错, 但是其性能同它所监视的连接数呈线性关系. 监视的连接数越多, 性能就越差. 而且`select(2)`系统受到`FD_SETSIZE`的限制. `select`无法对编号大于`FD_SETSIZE`的文件描述符进行监视. 



`Linux`的`epoll`以及`BSD`的`kqueue`的系统调用比`select`效果会更好, 功能更先进. 像`EventMachine`这种高性能联网工具在可能的情况下更倾向于使用`epoll`或者`kqueue`.



### Ruby Thread

> 每个正在系统上运行的程序都是一个进程.
>
> 每个进程包含一到多个线程.

线程是程序中一个单一的顺序控制流程, 在单个程序同时运行时运行多个线程完成不同的工作, 称为多线程.

`Ruby`中我们可以通过`Thread`类来创建多线程, `Ruby`的多线程是一个轻量级的, 可以以高效的方式来实现并行.



#### 创建多线程

~~~ruby
# 主线程 1 
# 创建子线程
Thread.new {
  # 子线程的执行代码
}

# 主线程1 执行代码
~~~

#### 线程的生命周期

1. 线程的创建可以使用`Thread.new`、 `Thread.start` 、 `Thread.fork` 三个方法
2. 创建线程后无需启动, 线程会自动执行
3. `Thread`类定义了一些方法来操纵线程, 线程执行`Thread.new`中的代码块
4. 线程代码块中最后一个语句是线程的值, 可以通过线程的方法来调用. 如果线程执行完毕, 则返回线程值, 否则不返回, 知道线程执行完毕
5. `Thread.current`方法返回当前线程对象, `Thread.main`返回主线程.
6. 通过`Thread.join`方法来执行线程, 这个方法就会挂起主线程, 直到当前子线程执行完毕

线程的五种状态

| 线程状态                  | 返回值    |
| ------------------------- | --------- |
| Runnable                  | run       |
| Sleeping                  | Sleeeping |
| Aborting                  | aborting  |
| Terminated normally       | false     |
| Terminated with exception | nil       |
|                           |           |

#### 线程的同步控制

* 通过`Metex`类实现线程同步
* 监管数据交交接的`Queue`类实现线程同步
* 使用`ConditionVariable`实现同步控制

1. 通过`Metex`类实现线程同步

   如果多个线程时钟同时需要访问一个程序变量, 我们可以使用`lock`锁定此变量

2. 监管数据交接的`Queue`类实现线程同步

   `Queue`类就是表示一个支持线程的队列, 能够同步对队列末尾进行访问. 不同的线程可以使用同一个队列, 而不用担心这个队列中的数据是否能够同步.

3. 使用`ConditionablVariable`实现同步控制

   这样可以在一些致命的资源竞争部分挂起线程直至油可用的资源为止

   ~~~ruby
   #encoding:gbk
   require "thread"
   puts "thread synchronize by ConditionVariable"

   mutex = Mutex.new
   resource = ConditionVariable.new

   a = Thread.new {
     mutex.synchronize {
       # 这个线程目前需要resource这个资源
       resource.wait(mutex) 
       puts "get resource"
     }
   }

   b = Thread.new {
     mutex.synchronize {
       #线程b完成对resourece资源的使用并释放resource
       resource.signal
     }
   }

   a.join
   puts "complete"
   ~~~

   `mutex`是声明的一个资源, 然后通过`ConditionVariable`来控制申请和释放资源.

   `b`线程完成了某些工作之后释放资源`resource.signal`, 这样`a`线程就可以获得一个`mutex`资源然后执行




#### 线程常用方法

##### 类方法

| Thread.abort_on_exception     | 如果设置为`true`, 一旦某线程因异常而终止时, 整个解释器就会被中断 |
| ----------------------------- | ------------------------------------------------------------ |
| Thread.current                | 返回当前运行中的线程                                         |
| Thread.new {\|args\| balabal} | 生成新线程时携带传入的参数                                   |
| Thread.pass                   | 将线程的运行权交给其他线程, 不会改变运行中的线程状态, 而是将控制权交给其他可运行的线程 |
| Thread.stop                   | 将当前线程挂起, 直到其他线程使用 run 再次唤醒当前线程        |
|                               |                                                              |

##### 线程实例方法

| thread[name]= | 设置线程内 `name`对应的固有数据的值                          |
| ------------- | ------------------------------------------------------------ |
| thread.run    | 重新启动被挂起的线程,与`wakeup`不同的是, 它将立即进行线程的切换 |
| thread.wakeup | 将被挂起(stop)的线程的状态改为可执行(run)状态                |
| thread.join   | 挂起当前线程(一般在主线程中调用, 子线程均正常运行结束后主线程再重新启动) |
|               |                                                              |
|               |                                                              |





## IO 模型

通过解读 `WEBrick`源码, 我们已经熟悉了整个 `Web Server`的工作原理.

当我们启动一个 `Web Server`服务时只会启动一个进程, 该进程会在指定的 `ip`和 `port`上使用 `IO.select`监听来自用户的所有 `HTTP请求`.



![WEB SERVER ]()



当`IO.select`接收到来自用户的请求时, 会为每一个请求创建一个新的线程 `Thread.new` 并在新的线程中对 `HTTP`请求进行处理.



由于 `WEBrick`在运行时只会启动一个进程, 没有其他的守护进程, 所以它不够健壮, 无法在发送问题时重启持续对外界提供服务. 



虽然 `WEBrick`有一些性能问题, 但是作为 `Ruby`自带的`Web Server`, 无论是开发还是学习都是值得研究的.

## 总结

`WEBrick`是`Ruby`内置的`Web Server`, 目前主要使用在`开发`环境下, 在生产环境下开发者往往选择性能更好, 更健壮的 `Unicorn`和 `Puma`. 现在研究`WEBrick`的源码和实现可以帮助我们熟悉`Ruby Web Server`具备的基本功能以及`Web Server`处理请求的基本流程. 在这之后, 我们就可以继续深入分析更复杂的`Web Server`, 更复杂的`IO`模型了.



## Reference

