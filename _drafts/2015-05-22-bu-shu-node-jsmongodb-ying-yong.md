---
layout: post
toc: true
title: 部署 Node.js+MongoDB App
date: 2015-05-22 17:55:22.000000000 +08:00
permalink: /:title
tags: Node.js MongoDB
---


因为最近在为 SportJoin 写 Web API, 由于对大部分的工作已经完成, 所以开始尝试将 Node 代码部署到服务器上.

我在部署的过程中遇到了很多的问题, 在网上找了很多的教程都完全不详细, 并不能直接解决我的问题, 不过所幸经过自己的尝试和摸索最后还是解决了.

我在开发 SportJoin Web API 的时候使用的是 Restify + Mongodb, 所以部署的时候要解决两个问题, 一个是 Mongodb 的安装, 另一个是代码的部署.

## DigitalOcean

因为在一两个月之前, 我曾经注册过 DigitalOcean 的账号,  而且体验也是蛮不错的. 所以在这次我会把我的代码部署到 DigitalOcean 上.

首先会创建一个 droplet, 然后选择 Ubuntu, 并在 Applications 中选择 Node 环境.

![](/content/images/2015/05/18BCAAB6-D88F-4820-9B88-28567A22CB5A.png)

如果你没有使用 DigitalOcean, 而是使用其他的云服务器, 那么唯一的区别就是. **你需要手动安装 Node 环境.**

## 安装 Mongodb

安装 Mongodb 还是很简单的, 你可以看[这篇教程](http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/). 当然在 mongodb 的官网上也有在其他 linux 发行版的安装方法.

你只需要远程登录到你的服务器

~~~
ssh root@url.com
~~~

然后依次输入下面的命令就好了

~~~
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
~~~

它们会自动的安装最新版本的 mongodb.

mongodb 就已经安装完成了. 然后你需要在 mongodb 中创建与你的 Web 应用相同名字的 document(与本地开发环境中创建的相同).

~~~
mongo

> use sportjoin
~~~


## git clone

我从 bitbucket 上使用 git clone 命令, 将我的 Node 代码抓去下来, 然后先安装所 App 所需要的依赖.

~~~
git clone <repo.git>
cd <folder>
npm install
~~~

## pm2

在这里的部署中, 我没有使用 forever 和 nginx, 而是使用了 [pm2](https://github.com/Unitech/PM2) 这是另一个自动部署的工具, 它的使用炒鸡简单.

先在全局中安装 pm2

~~~
npm install -g pm2
~~~

然后在工程的根目录下运行 Web 应用

~~~
cd <folder>
pm2 start <app.js>
~~~

到目前为止部署就完成了, 对于更加详细的配置, 可以看 pm2 github 的文档找到更多的资料.

## 总结

总体来说部署还是很容易的, 在之后的更新中只需要在本地 push 代码, 然后在服务器上 pull 下来就可以了. 不需要 nginx 和 forever.
