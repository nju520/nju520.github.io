---
layout: post
toc: true
title: 我只想安安静静地学 Node.js
date: 2015-04-19 11:26:20.000000000 +08:00
permalink: /:title
tags: Node.js
---

这几天没有什么别的事情, 接的几个项目也没有给我 UI 设计图. 最近听说Node.js 这么~~火~~优雅, 兴趣也很大, 就来尝试学习一下.

![](/content/images/2015/04/nodejs-01.png)

学习 Node.js 的路线图我是在知乎找到的, 请戳[这里](http://www.zhihu.com/question/21567720), 我目前学习 Node.js 的方式就是按照这个得票最高的答主的答案学习的.

现在由于对 Node.js 并不是很熟悉, 所以只来谈一谈这几天学习 Node.js 的感受吧.

## Node.js 入门

关于 [Node.js 入门](http://www.nodebeginner.org/index-zh-cn.html) 这本书写的还是非常好的. 不过读这本书之前或者说学习 Node.js 之前还是点亮 Javascript 这个前置技能比较好.

~~~javascript
console.log("Hello World");
~~~

## Node.js 权威指南

[Node.js 权威指南](http://www.amazon.cn/Node-js%E6%9D%83%E5%A8%81%E6%8C%87%E5%8D%97-%E9%99%86%E5%87%8C%E7%89%9B/dp/B00JQTOAEI/ref=sr_1_1?ie=UTF8&qid=1429414848&sr=8-1&keywords=Node.js+%E6%9D%83%E5%A8%81%E6%8C%87%E5%8D%97) 写的如何我并不能做出评论, 不过书中使用的 Express 框架, 也就是 Node.js 中用于搭建 Web 服务器的框架版本巨低, 很多代码根本无法运行, 所以我不是很推荐, 因为我在这本书的阅读过程(写书中的实例代码)中还是极其痛苦的, 完全无法快乐的玩耍 (/= _ =)/~┴┴, 而无法快乐的写代码与我的信仰是冲突的 (￣^￣), 我只能放弃了.

~~~javascript
var http = require('http');

var server = http.createServer(function (request, response) {
  response.writeHead(200, {"Content-Type": "text/plain"});
  response.end("Hello World\n");
});

server.listen(8888);

console.log("Server running at http://127.0.0.1:8888/");
~~~

## Node.js 并不是一门语言

对一种技术的尊重, 第一件事是要叫对它的名字, 总有人把 `Objective-C` 写成 `object c` 我真是受不了啊...就算不写这么长, 写 `OC` 好么... 对于我这种强迫症患者跟本无法忍受.

同理 Node.js 并不是一门语言, 而是一个平台:

> Node.js is a platform built on Chrome’s JavaScript runtime for easily building fast, scalable network applications.

这个从 [Node.js 官网](https://nodejs.org/) 上扒下来的话已经非常清楚地道明了, **这货是一个平台, 不是一门语言**. 我在这篇 post 中也会重视这一点, 时刻提醒自己与各位.

## Express

[Express](http://expressjs.com/) 是基于 Node.js 的 Web 框架, 其实各种脚本语言, Ruby, Python, Node.js(并不是语言) 的 Web 框架使用起来在大体上是差不多的.

Sinatra:

~~~ruby
get '/hi' do
  "Hello World!"
end
~~~

Flask:

~~~python
@app.route("/")
def hello():
    return "Hello World!"
~~~

Express:

~~~javascript
app.get('/', function(req, res) {
  res.send('hello world');
});
~~~

可以看到这三个框架在使用上或者说形式是相似的. 但是, 它们也有很多的不同.

其实只要你长时间做 Web 开发, "精通"这些框架中的一个, 其它不同"语言"的框架也是很容易掌握的. 关键之处在于理解它们的使用场景和细节上的不同之处.

比如说:

> Node.js 比较适合实现高并发 IO 系统, 而不适合高 CPU/内存消耗的计算.

总有人会许寻找适合所有领域的技术, 而这样的技术在目前来看是不存在的, 而什么时候会存在, 只有天知道了. =_=

## 事件驱动

接下来~~扯~~讲一下 Node.js 中的一个很重要的概念, 就是**事件驱动**.

> Node.js 是事件驱动的.

### 编程范式?

第一次听到事件驱动这个概念, 我的第一想法是这是一种**编程范式**么? 于是我又翻开了 [CTMCP](https://www.info.ucl.ac.be/~pvr/book), 看了一下这本书的目录, 并没有找到事件驱动这个编程范式.

于是我求助了 Google, [事件驱动程序设计](http://zh.wikipedia.org/wiki/%E4%BA%8B%E4%BB%B6%E9%A9%85%E5%8B%95%E7%A8%8B%E5%BC%8F%E8%A8%AD%E8%A8%88) 其实我并没有看懂 =\_=, 不过看到这里, 虽然 CTMCP 中没有提到, 不过这确实是一种编程范式.

### 回调函数

Node.js 的事件驱动是基于一个**回调函数**的. 当某个事件发生时, 这个回调函数才会被调用, 而不像传统的编程范式操作都是线性运行的: 如果需要用户的输入, 就会一直等待直到用户输入完成.

在 Node.js 中当发生了用户输入这个时间之后才回去调用回调函数完成之后的工作, 这也就是为什么

>  Node.js 比较适合实现高并发 IO 系统.

----

## 总结

学习 Node.js 的主要目的是为我的 iOS 应用搭建 Web api, 所以, 我并没有选择 Express 而是选择了 [restify](https://github.com/mcavage/node-restify), 这是一个专门用于搭建 Web api 的框架, 没有模板啊与 Web 前端相关的东西.

接下来我会继续学习 Node.js 尤其是 restify, "精通"这门优雅的"语言".
