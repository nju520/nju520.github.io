---
layout: post
toc: true
title: Shell 编程初探
date: 2015-05-16 21:03:05.000000000 +08:00
permalink: /:title
---


从开始系统的学习编程到现在已经快有两年了, 我也逐渐从使用 GUI 完成大部分任务转换到使用命令行.

## 书籍选择

学习一种技术对于我来说还是一件很有意思的事情, 而选择书籍就成为学习技术前所必须的准备工作. 而对于 shell 编程, 书籍的选择其实并不多.

### Advanced Bash Scripting

而使用命令行之后, shell 是绕不过的语言, 我在一个月之前看过几章的 Advanced Bash Scripting, 不过这本书在我看来并不像很多人说的那样是 shell 编程中的圣经, 尤其不适合 shell 初学者. 书中对于 shell 中介绍可以说是非常的详细甚至啰嗦了.

### Linux Command Line and Shell Scripting Bible

而在最近的学习中, 我的选择是 Linux Command Line and Shell Scripting Bible, 中译本是 [Linux 命令行与 shell 脚本编程大全](http://www.amazon.cn/Linux%E5%91%BD%E4%BB%A4%E8%A1%8C%E4%B8%8Eshell%E8%84%9A%E6%9C%AC%E7%BC%96%E7%A8%8B%E5%A4%A7%E5%85%A8-Richard-Blum/dp/B0096EXMS8/ref=sr_1_1?ie=UTF8&qid=1431706028&sr=8-1&keywords=linux+%E5%91%BD%E4%BB%A4%E8%A1%8C%E4%B8%8E+shell). 这本书相对于 ABS 来说我觉的更加适合新手.

## Shell 基础

Shell 是什么? 在 GUI 出现之前, 和 Unix 系统唯一的交互方式就是通过 shell 提供的文本命令行界面(CLI, Command Line Interface).

Shell 有很多种, bash shell, zsh shell 等等, 我平时学习和工作时使用的是 zsh, 而在这里所介绍的是 bash shell. 也就是在大多数 Linux 发行版和 Unix 系统上的默认 Shell.

## #!

在我们写 shell 脚本的时候需要在文件的 `#!`, 你经常会在 `.sh` 文件中看到的

~~~
#!/bin/sh
~~~

> 这种文件会在执行时实际调用 `/bin/sh` 程序来执行, 这也就是 shell 脚本的标准起始行.

而在这里的代码通常是使用 Bourne shell 或者兼容的 shell: bash, dash 来执行.

## echo

`echo` 就像是 Objective-C 中的 NSLog, 它会将一系列的参数打印到终端中.

~~~
$ echo "Hello World"
Hello World
~~~

这个命令还是很简单并且常用的. 在这里就不对这个命令进行详细地讲解了.

## 环境变量

长时间使用 Unix 或者 Linux 操作系统时, 你会对 `$PATH` 特别熟悉, 因为在终端下输入命令时, 会把 `$PATH` 当做默认的目录, 会从其中的目录中寻找你要执行的二进制文件.

你可以在终端中输入 `printenv` 查看所有的全局变量.

而如果你想查看单独的全局变量时, 必须在变量名前加上 `$` 符号.

~~~
$ echo $HOME
/Users/apple
~~~

这是我在 OS X 系统上输出的结果.

## alias

`alias` 是我非常常用的命令,  **命令别名允许为通用命令创建一个别名**. 我是用这个命令尽可能的减少我在命令行中的输入次数.

因为使用的是 zsh, 所以我在 zshrc 中添加了如下的代码来简化输入.

~~~
# Alias
alias ga='git add .'
alias gam='git add -A && git commit'
alias gamm='git add -A && git commit -m'
autoPush() {
    git add -A
    git commit -m $1
    git push
}
alias g=autoPush
alias gp='git push && git push --tags'
alias gs='git status '
alias gf='git fetch '
alias gm='git merge '
alias gmm='git merge origin/master'
alias dc="cd /Users/apple/Desktop"
alias ..='cd ..'
alias ...='cd ../..'
alias ....=' cd ../../..'
alias vim='/Applications/MacVim.app/Contents/MacOS/Vim '
alias v='vim'
alias v.='vim .'
~~~

这些重命名能够对于我来说用起来还是很爽的. 每次输入 `g "Commit"`, 然后就会自动完成 `git add` `git commit` `git push` 三个命令.

## 总结

对于 shell 命令暂时只说到这里了. 因为我目前对 shell 编程的了解并不是很多. 我会在之后的 post 中继续写一些我对 shell 的学习.
