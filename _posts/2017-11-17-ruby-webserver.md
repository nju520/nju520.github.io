---
layout: post
title: Ruby Web 服务器的并发模型与性能
toc: true
permalink: /ruby-webserver
tags: Rack系列 rack ruby webserver server
desc: 这是整个 Rack 系列文章的最后一篇了，在之前其实也尝试写过很多系列文章，但是到最后都因为各种原因放弃了，最近由于自己对 Ruby 的 webserver 非常感兴趣，所以看了下社区中常见 webserver 的实现原理，包括 WEBrick、Thin、Unicorn 和 Puma，虽然在 Ruby 社区中也有一些其他的 webserver 有着比较优异的性能，但是在这有限的文章中也没有办法全都介绍一遍。
---

+ [谈谈 Rack 协议与实现](http://hwbnju.com/rack)
+ [浅谈 WEBrick 的多线程模型](http://hwbnju.com/rack-webrick)
+ [浅谈 Thin 的事件驱动模型](http://hwbnju.com/rack-thin)
+ [浅谈 Unicorn 的多进程模型](http://hwbnju.com/rack-unicorn)
+ [浅谈 Puma 的并发模型与实现](http://hwbnju.com/rack-puma)
+ [Ruby Web 服务器的并发模型与性能](http://hwbnju.com/ruby-webserver)

这是整个 Rack 系列文章的最后一篇了，在之前其实也尝试写过很多系列文章，但是到最后都因为各种原因放弃了，最近由于自己对 Ruby 的 webserver 非常感兴趣，所以看了下社区中常见 webserver 的实现原理，包括 WEBrick、Thin、Unicorn 和 Puma，虽然在 Ruby 社区中也有一些其他的 webserver 有着比较优异的性能，但是在这有限的文章中也没有办法全都介绍一遍。

![webservers](https://img.nju520.me/2017-11-17-webservers.png)

在这篇文章中，作者想对 Ruby 社区中不同 webserver 的实现原理和并发模型进行简单的介绍，总结一下前面几篇文章中的内容。

> 文中所有的压力测试都是在内存 16GB、8 CPU、2.6 GHz Intel Core i7 的 macOS 上运行的，如果你想要复现这里的测试可能不会得到完全相同的结果。

## WEBrick

WEBrick 是 Ruby 社区中非常古老的 Web 服务器，从 2000 年到现在已经有了将近 20 年的历史了，虽然 WEBrick 有着非常多的问题，但是迄今为止 WEBrick 也是开发环境中最常用的 Ruby 服务器；它使用了最为简单、直接的并发模型，运行一个 WEBrick 服务器只会在后台启动一个进程，默认监听来自 9292 端口的请求。

![webrick-concurrency-model](https://img.nju520.me/2017-11-17-webrick-concurrency-model.png)

当 WEBrick 通过 `.select` 方法监听到来自客户端的请求之后，会为每一个请求创建一个单独 `Thread` 并在新的线程中处理 HTTP 请求。

```ruby
run Proc.new { |env| ['200', {'Content-Type' => 'text/plain'}, ['get rack\'d']] }
```
如果我们如果创建一个最简单的 Rack 应用，直接返回所有的 HTTP 响应，那么使用下面的命令对 WEBrick 的服务器进行测试会得到如下的结果：

```shell
Concurrency Level:      100
Time taken for tests:   22.519 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      2160000 bytes
HTML transferred:       200000 bytes
Requests per second:    444.07 [#/sec] (mean)
Time per request:       225.189 [ms] (mean)
Time per request:       2.252 [ms] (mean, across all concurrent requests)
Transfer rate:          93.67 [Kbytes/sec] received
```

在处理 ApacheBench 发出的 10000 个 HTTP 请求时，WEBrick 对于每个请求平均消耗了 225.189ms，每秒处理了 444.07 个请求；除此之外，在处理请求的过程中 WEBrick 进程的 CPU 占用率很快达到了 100%，通过这个测试我们就可以看出为什么不应该在生产环境中使用 WEBrick 作为 Ruby 的应用服务器，在业务逻辑和代码更加复杂的情况下，WEBrick 的性能想必也不会达到期望。

## Thin

在 2006 和 2007 两年，Ruby 社区中发布了两个至今都非常重要的开源项目，其中一个是 Mongrel，它提供了标准的 HTTP 接口，同时多语言的支持也使得 Mongrel 在当时非常流行，另一个项目就是 Rack 了，它在 Web 应用和 Web 服务器之间建立了一套统一的 [标准](https://www.google.com/search?client=safari&rls=en&q=rack+spec&ie=UTF-8&oe=UTF-8)，规定了两者的协作方式，所有的应用只要遵循 Rack 协议就能够随时替换底层的应用服务器。

![rack-protoco](https://img.nju520.me/2017-11-17-rack-protocol.png)

随后，在 2009 年出现的 Thin 就站在了巨人的肩膀上，同时遵循了 Rack 协议并使用了 Mongrel 中的解析器，而它也是 Ruby 社区中第一个使用 Reactor 模型的 Web 服务器。

![thin-concurrency-model](https://img.nju520.me/2017-11-17-thin-concurrency-model.png)

Thin 使用 Reactor 模型处理客户端的 HTTP 请求，每一个请求都会交由 EventMachine，通过内部对事件的分发，最终执行相应的回调，这种事件驱动的 IO 模型与 node.js 非常相似，使用单进程单线程的并发模型却能够快速处理 HTTP 请求；在这里，我们仍然使用 ApacheBench 以及同样的负载对 Thin 的性能进行简单的测试。

```shell
Concurrency Level:      100
Time taken for tests:   4.221 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      880000 bytes
HTML transferred:       100000 bytes
Requests per second:    2368.90 [#/sec] (mean)
Time per request:       42.214 [ms] (mean)
Time per request:       0.422 [ms] (mean, across all concurrent requests)
Transfer rate:          203.58 [Kbytes/sec] received
```

对于一个相同的 HTTP 请求，Thin 的吞吐量大约是 WEBrick 的四倍，每秒能够处理 2368.90 个请求，同时处理的速度也大幅降低到了 42.214ms；在压力测试的过程中虽然 CPU 占用率有所上升但是在处理的过程中完全没有超过 90%，可以说 Thin 的性能碾压了 WEBrick，这可能也是开发者都不会在生产环境中使用 WEBrick 的最重要原因。

但是同样作为单进程运行的 Thin，由于没有 master 进程的存在，哪怕当前进程由于各种各样奇怪的原因被操作系统杀掉，我们也不会收到任何的通知，只能手动重启应用服务器。

## Unicorn

与 Thin 同年发布的 Unicorn 虽然也是 Mongrel 项目的一个 fork，但是使用了完全不同的并发模型，每Unicorn 内部通过多次 `fork` 创建多个 worker 进程，所有的 worker 进程也都由一个 master 进程管理和控制：

![unicorn-master-workers](https://img.nju520.me/2017-11-17-unicorn-master-workers.png)

由于 master 进程的存在，当 worker 进程被意外杀掉后会被 master 进程重启，能够保证持续对外界提供服务，多个进程的 worker 也能够很好地压榨多核 CPU 的性能，尽可能地提高请求的处理速度。

![unicorn-concurrency-model](https://img.nju520.me/2017-11-17-unicorn-concurrency-model.png)

一组由 master 管理的 Unicorn worker 会监听绑定的两个 Socket，所有来自客户端的请求都会通过操作系统内部的负载均衡进行调度，将请求分配到不同的 worker 进程上进行处理。

不过由于 Unicorn 虽然使用了多进程的并发模型，但是每个 worker 进程在处理请求时都是用了阻塞 I/O 的方式，所以如果客户端非常慢就会大大影响 Unicorn 的性能，不过这个问题就可以通过反向代理来 nginx 解决。

![unicorn-multi-processes](https://img.nju520.me/2017-11-17-unicorn-multi-processes.png)

在配置 Unicorn 的 worker 数时，为了最大化的利用 CPU 资源，往往会将进程数设置为 CPU 的数量，同样我们使用 ApacheBench 以及相同的负载测试一个使用 8 核 CPU 的 Unicorn 服务的处理效率：

```shell
Concurrency Level:      100
Time taken for tests:   2.401 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      1110000 bytes
HTML transferred:       100000 bytes
Requests per second:    4164.31 [#/sec] (mean)
Time per request:       24.014 [ms] (mean)
Time per request:       0.240 [ms] (mean, across all concurrent requests)
Transfer rate:          451.41 [Kbytes/sec] received
```

经过简单的压力测试，当前的一组 Unicorn 服务每秒能够处理 4000 多个请求，每个请求也只消耗了 24ms 的时间，比起使用单进程的 Thin 确实有着比较多的提升，但是并没有数量级的差距。

除此之外，Unicorn 由于其多进程的实现方式会占用大量的内存，在并行的处理大量请求时你可以看到内存的使用量有比较明显的上升。

## Puma

距离 Ruby 社区的第一个 webserver WEBrick 发布的 11 年之后的 2011 年，Puma 正式发布了，它与 Thin 和 Unicorn 一样都从 Mongrel 中继承了 HTTP 协议的解析器，不仅如此它还基于 Rack 协议重新对底层进行了实现。

![puma-cluster-mode](https://img.nju520.me/2017-11-17-puma-cluster-mode.png)

与 Unicorn 不同的是，Puma 是用了多进程加多线程模型，它可以同时在 fork 出来的多个 worker 中创建多个线程来处理请求；不仅如此 Puma 还实现了用于提高并发速度的 Reactor 模块和线程池能够在提升吞吐量的同时，降低内存的消耗。

![puma-concurrency-mode](https://img.nju520.me/2017-11-17-puma-concurrency-model.png)

但是由于 MRI 的存在，往往都需要使用 JRuby 才能最大化 Puma 服务器的性能，但是即便如此，使用 MRI 的 Puma 的吞吐量也能够轻松达到 Unicorn 的两倍。

```shell
Concurrency Level:      100
Time taken for tests:   1.057 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      750000 bytes
HTML transferred:       100000 bytes
Requests per second:    9458.08 [#/sec] (mean)
Time per request:       10.573 [ms] (mean)
Time per request:       0.106 [ms] (mean, across all concurrent requests)
Transfer rate:          692.73 [Kbytes/sec] received
```

在这里我们创建了 8 个 Puma 的 worker，每个 worker 中都包含 16~32 个用于处理用户请求的线程，每秒中处理的请求数接近 10000，处理时间也仅为 10.573ms，多进程、多线程以及 Reactor 模式的协作确实能够非常明显的增加 Web 服务器的工作性能和吞吐量。

在 Puma 的 [官方网站](http://puma.io) 中，有一张不同 Web 服务器内存消耗的对比图：

![memory-usage-comparision](https://img.nju520.me/2017-11-17-memory-usage-comparision.png)

我们可以看到，与 Unicorn 相比 Puma 的内存使用量几乎可以忽略不计，它明显解决了多个 worker 占用大量内存的问题；不过使用了多线程模型的 Puma 需要开发者在应用中保证不同的线程不会出现竞争条件的问题，Unicorn 的多进程模型就不需要开发者思考这样的事情。

## 对比

上述四种不同的 Web 服务器其实有着比较明显的性能差异，在使用同一个最简单的 Web 应用时，不同的服务器表现出了差异巨大的吞吐量：

![ruby-webservers](https://img.nju520.me/2017-11-17-ruby-webservers.jpeg)

Puma 和 Unicorn 两者之间可能还没有明显的数量级差距，1 倍的吞吐量差距也可能很容易被环境因素抹平了，但是 WEBrick 可以说是绝对无法与其他三者匹敌的。

上述的不同服务器其实有着截然不同的 I/O 并发模型，因为 MRI 中 GIL 的存在我们很难利用多核 CPU 的计算资源，所以大多数多线程模型在 MRI 上的性能可能只比单线程略好，达不到完全碾压的效果，但是 JRuby 或者 Rubinius 的使用确实能够利用多核 CPU 的计算资源，从而增加多线程模型的并发效率。

![jruby](https://img.nju520.me/2017-11-17-jruby.png)

传统的 I/O 模型就是在每次接收到客户端的请求时 fork 出一个新的进程来处理当前的请求或者在服务器启动时就启动多个进程，每一个进程在同一时间只能处理一个请求，所以这种并发模型的吞吐量有限，在今天已经几乎看不到使用 **accept & fork** 这种方式处理请求的服务器了。

目前最为流行的方式还是混合多种 I/O 模型，同时使用多进程和多线程压榨 CPU 计算资源，例如 Phusion Passenger 或者 Puma 都支持在单进程和多进程、单线程和多线程之前来回切换，配置的不同会创建不同的并发模型，可以说是 Web 服务器中最好的选择了。

最后要说的 Thin 其实使用了非常不同的 I/O 模型，也就是事件驱动模型，这种模型在 Ruby 社区其实并没有那么热门，主要是因为 Rails 框架以及 Ruby 社区中的大部分项目并没有按照 Reactor 模型的方式进行设计，默认的文件 I/O 也都是阻塞的，而 Ruby 本身也可以利用多进程和多线程的计算资源，没有必要使用事件驱动的方式最大化并发量。

![nodejs-logo](https://img.nju520.me/2017-11-17-nodejs-logo.jpg)

Node.js 就完全不同了。Javascript 作为一个所有操作都会阻塞主线程的语言，更加需要事件驱动模型让主线程只负责接受 HTTP 请求，其余的脏活累活都交给线程池来做了，结果的返回都通过回调的形式通知主线程，这样才能提高吞吐量。

## 总结

在这个系列的文章中，我们先后介绍了 Rack 的实现原理以及 Rack 协议，还有四种 webserver 包括 WEBrick、Thin、Unicorn 和 Puma 的实现，除了这四种应用服务器之外，Ruby 社区中还有其他的应用服务器，例如：Rainbows 和 Phusion Passenger，它们都有各自的实现以及优缺点。

从当前的情况来看，还是更推荐开发者使用 Puma 或者 Phusion Passenger 作为应用的服务器，这样能获得最佳的效果。

## Reference

+ [Ruby Web 服务器：这十五年](https://read01.com/zh-hk/zm5B.html#.Wf0oLduB0sk)
+ [Ruby 服务器对比](https://ruby-china.org/topics/25276)
+ [Ruby 的多线程应用服务器介绍](https://ruby-china.org/topics/10832)
+ [Ruby on Rails Server options](https://stackoverflow.com/questions/4113299/ruby-on-rails-server-options)


