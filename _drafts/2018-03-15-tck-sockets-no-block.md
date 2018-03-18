---
layout: post
toc: true
permalink: /tcp-scokets-no-block
title: TCP Socket 编程 -- 非阻塞式 IO
tags: TCP socket Ruby 
desc: 网络请求的瓶颈一般来自于 `IO`
---

## 非阻塞式 `IO`



### 网络请求瓶颈!!



### 非阻塞式读操作

还记得我们之前学过的`Socket#read`吗? `它会一直保持阻塞, 直到接收到`EOF`或者获得指定的最小字节数为止.

如果客户端没有发送`EOF`, 就可能会导致阻塞. 这种情况虽然可以通过`readpartial`暂时解决, `readpartial`会立刻返回所有的可用数据. 但是如果没有数据可用, 那么`readpartial`也会陷入阻塞状态.



我们可以使用`read_nonblock`来实现非阻塞式读操作.



和`readpartial` 非常类似, `read_nonblock`需要一个整数的参数, 指定需要读取的最大字节数. 如果可用的数据小于最大字节数, 那就只返回可用数据. 

~~~ruby
require 'socket'

Socket.tcp_server_loop(4481) do |conn|
  loop do
    begin
      puts conn.read_nonblock(1024 * 4)
    rescue Errno::EAGAIN
      puts "no data, just retry"
      sleep 1
      retry
    rescue EOFError
      break
    end
  end

  conn.close
end

~~~

运行我们之前的客户端命令:

~~~shell
$ tail -f /var/log/system.log | nc localhost 4481
~~~

即使没有向服务器发送数据, `read_nonblock`调用仍然会立即返回. 事实上它产生了一个`Errno::EAGAIN`异常.

> Errno::EAGAIN: 文件被标记用于非阻塞式`IO`, 表示无数据可读

原来如此, 这样 `read_nonblock`就不同于`readpartial`了, 后者在这种情况下就会阻塞.

如果你碰到这种情况如何应对? 上面的例子中, 我们进入下一个循环并不断重试`retry`. 这只是为了演示, 并非正确的做法.

对被阻塞的读操作进行重试的正确方式应该采用`IO.select`:

~~~ruby
loop do
  begin puts conn.read_nonblock(1024 * 4)
  rescue Errno::EAGAIN
    puts "===== not data, just wait IO.select return readable sockets"
    IO.select([conn])
    retry
  rescue EOFError
    break
  end
end
~~~

使用套接字数组作为`IO.select`调用的第一个参数将会造成阻塞, 直到某个套接字变得可读为止. 所以应该仅当某个套接字变得可读时才去重试, 否则就是浪费系统资源.

> IO.select 实际上也是阻塞式操作, 直到有可读/可写的套接字返回, 否则它就一直阻塞.

在本例种, 我们使用了非阻塞方法重新实现了阻塞式的`read`方法, 这本身并没有什么用处, 但是`IO.select`给我们提供了很多灵活性, 我们在进行其他工作的同时监控多个套接字或者定期检查它们的可读性.

在后文中会着重分析`IO.select`



### 非阻塞式写操作



非阻塞式写操作和我们之前调用的`write`有所不同. 最明显的一处就是: `write_nonblock`可能会返回部分写入的结果, 而`write`调用总是将我发送给它的数据全部写入.

这是因为`write_nonblock`碰到了某种使它出现阻塞的情况, 因此也就没发进行写入, 所有返回了整数值, 告诉我们写入了多少数据. 我们还要将剩下没有写入的数据继续写入.

~~~ruby

~~~

* 如果一次调用没发写入所有的请求的数据, 就应该试着继续写入没有写完的部分
* 如果底层的`write`处于阻塞状态, 就应该捕获`Errno::EAGAIN`异常, 并调用`IO.select`, 它可以告诉我们何时某个套接字可写.




#### 什么情况下写操作会阻塞

1. `TCP`连接的接收端还没有确认接收到对方的数据, 而发送端已经发送了所运行发送的数据量. `TCP`使用拥塞控制算法确保网络不会被分组所淹没. 如果数据花费了很长时间才到达`TCP`连接的接收端, 那么就不要发送超出网络处理能力的数据以免网络过载.
2. `TCP`连接的接收端无力处理更多的数据. 即使是另一端已经确认接收到了数据, 它仍清空自己的数据窗口, 以便重新接入其他数据.如果接收端没有处理它接收的数据, 那么拥塞控制算法就会强制发送端阻塞, 直到客户端可以接收更多的数据为止.





## 连接复用

> 连接复用是指同时处理多个活动套接字, 这不是指并行处理, 也和多线程无关.



想象一下如何编写一个需要随时处理多条`TCP`连接中的可用数据服务器. 我们可以使用刚刚学会的有关非阻塞式`IO`的知识来避免在特定的套接字上陷入停滞.

~~~ruby
# 创建一个连接数组
connections = [<TCPSocket>, <TCPSocket>, <TCPSocket>

loop do
  # 处理每个连接
  connections.each do |conn|
    begin
      # 采用非阻塞的方式从每个连接中进行读取
      # 处理接收到的数据
      data = conn.read_nonblock(4096)
      process(data)
      # 不然就进行下一次的尝试
    resuce Errno::EAGAIN
    end
  end
end
~~~

虽然上述代码行得通, 但是需要频繁地执行尝试循环.



每一次调用`read_nonblock`都要使用至少一个系统调用, 如果没有数据可读, 服务器就会浪费大量处理的周期. 

如前所述, `read_nonblock`会调用底层的`select`.

现在我们可以使用`Ruby`的一个包装器, 让我们按照自己的意图直接调用底层的`select`.



~~~ruby
# 创建一个连接数组
connections = [<TCPSocket>, <TCPSocket>, <TCPSocket>

loop do
  loop do
    # 调用底层的 `select` 查询 `socket` 连接的读写状态 
    ready = IO.slect(connections)

    #得到可进行读操作的 socket 连接
    readable_conns = ready[0]
    writable_conns = ready[1]

    readable_conns.each do |conn|
      data = conn.readpartial(4096)
      process(data)
    end
  end
end

~~~

我们使用`IO.select`可极大降低处理多个连接的开销. 

`IO.select`的作用就是接收若干`IO`对象, 然后告知哪一个可以进行读写, 这样我们就不必像刚才那样一直重试了.



让我们来深入研究一下`IO.select`.

**`IO.select`可以告诉我们文件描述符何时可以读写.它会阻塞. **



**`IO.select`是一个同步方法*. 按照目前的方式来使用它会造成阻塞, 直到传入的某个`IO` 对象状态发生变化, 这时候它就会立刻返回. 如果有多个对象状态发生变化, 那么它们就会通过嵌套数组返回*

`IO.select`可以接收四个参数:

* 希望从中进行读取的`IO`对象数组
* 希望从中进行写入的`IO`对象数组
* 超时的`IO`对象数组
* 超时时间(单位 秒). 它可以避免 `IO.selct`永远地阻塞下去. 如果在 `IO`状态发生变化之前就已经超时, 那么 `IO.select`就会返回 `nil`.

~~~ruby
ready = IO.select(for_reading, for_writing, for_writing)
~~~



它返回一个三个数组:

* 可以进行无拥塞读取的`IO`对象数组
* 可以进行无拥塞写入的`IO`对象数组
* 适用于异常条件的`IO`对象数组






#### 高性能复用

`IO.select`来自`Ruby`的核心代码库. 它是在`Ruby`中进行复用的唯一手段. 大多数现代操作系统支持多种复用方法.  `select`几乎总是最古老的, 也是用的最少的那个.



## 超时



超时其实就是忍耐. 你愿意在套接字连接上等待多长时间呢?套接字读取呢? 套接字写入呢?

所有这些答案都视你的忍耐力而定. 高性能网络程序通常都不愿意等待那些没完没了的操作.



 `Ruby`有自己自带的`timeout`库, 它提供了一种通用的超时机制, 但是操作系统也有一套针对套接字的超时机制, 效果更好而且更直观.

虽然操作系统提供了自带的套接字超时处理机制, 可以通过套接字选项`SNDTIMEO`以及`RCVTIMO`进行设置. 不过自`Ruby1.9`之后, 这个特性就不能再使用了. 由于`Ruby`在有线程存在时对于阻塞式`IO`所采用的处理方式. 它将`poll`相关的套接字进行了包装, 这样操作系统自带的套接字超时就没有优势了. 



还是请我们的老朋友`IO.select`出场. 之前我们知道了如何使用`IO.select`, 现在来看一下最后一个参数的使用:

~~~ruby
require 'socket'
require 'timeout'

# 超时时间设置为 5 秒
timeout = 5

Socket.tcp_server_loop(4481) do |conn|
  begin
    # 发起一个初始化 read 
    # 因为要求套接字上有被请求的数据, 有数据可读时可以避免使用 select
    conn.read_nonblock(1024 * 4)
  rescue Errno::EAGAIN
    # 监视是否可读
    if IO.select([conn], nil, nil, timeout)
      # IO.select 会将套接字返回, 我们可以打印出来看一下, 不返回 nil 就意味着套接字可读
      puts conn.read_nonblock(1024 * 4)
      retry
    else
      # 否则就会 raise 一个 Timeout::Error 
      raise Timeout::Error
    end
  end

  conn.close
end

~~~



运行我们之前使用的指令:

~~~shell
tail -f /var/log/system.log | nc localhost 4481		
~~~

如果系统日志没有, 并且套接字等待的时间超过我们设定的`timeout`, 程序就会`raise`一个`Timeout::Error`.

~~~ruby
read_timeout.rb:15:in `rescue in block in <main>': Timeout::Error (Timeout::Error)
	from read_timeout.rb:8:in `block in <main>'
~~~



这些基于超时的`IO.select`机制使用广泛, 甚至在`Ruby`的标准库中也能看到, 它们比操作系统自带的套接字超时处理机制的稳定性更高.



