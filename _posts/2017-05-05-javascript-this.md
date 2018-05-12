---
layout: post
toc: true
permalink: /javascript-this
title: JavaScript 深入理解 this 
tags: JavaScript this OOP
desc: JavaScript支持函数式编程, 闭包, 原型继承等高级特性. 由于其运行期绑定的特性, JavaScript中的this具有丰富的含义. 它可以支持全局对象, 当前对象, 或者任意对象, 这完全取决于函数的调用方式. 本文采撷一些例子来说明this在不同调用方式下的不同含义.
---



### 什么是this
1. this: 顾名思义就是这个对象，this到底指向哪个对象呢?
  this的指向取决于函数执行上下文.
  当一个函数被调用时, 会创建一个执行上下文. 这个记录会包含函数在哪里被调用, 传入的参数, 函数内部的声明, 以及this的指向.

2. 要明确一点就是this只存在函数调用中，无法在对象中直接使用this.

3. 如果函数作为对象的方法调用，其this就执行这个对象；如果作为嵌套函数调用，其this值要么是全局对象(非严格模式)，要么是undefined(严格模式)。如果想访问外部函数的this值，需要将this值保存在一个变量中

4. this是一个关键字， 不是变量， 也不是属性名。 JavaScript不允许给this赋值！！

### 为什么需要this?

```javascript
function identify() {
  return this.name.toUpperCase();
}

function speak() {
  var greeting = "Hello, I'm " + identify.call(this);
  console.log(greeting);
}

var me = {
  name: "bobo"
};

var her = {
  name: "yanzi"
};

identify.call(me); //BOBO
identify.call(her);//YANZI

speak.call(me); // Hello, I'm BOBO
speak.call(her);// Hello, I'm YANZI
```
speak.call(me);为例: 通过调用call方法，可以将this绑定到传入的对象中，也就是执行函数speak时，this绑定的对象是me.speak函数里面identify.call(this)其中的this也是绑定的me对象。
这段代码可以在不同的上下文对象(me和her)中重复使用函数identify()和speak(),不需要针对每个对象编写不同版本的函数。

如果不使用this，就需要给identify()和speak()函数显式传入一个上下文对象

```javascript
function identify(context) {
  return context.name.toUpperCase();
}

function speak(context) {
  var greeting = "Hello, I'm " + identify(context);
  console.log(greeting);
}

var me = {
  name: "bobo"
};

var her = {
  name: "yanzi"
};

identify(me); //BOBO
identify(her);//YANZI

speak(me); // Hello, I'm BOBO
speak(her);// Hello, I'm YANZI
```
上面的代码是未采用this,必须得传入一个具体的上下文对象，然后才能操作对象的属性。

通过上面的对比可以看出，this提供了一种优雅的方式来隐式“传递”一个对象引用， 可以将API设计地更加简介且已用(这个暂时还未阅读过一些开源项目的API，还不清楚)。

### 常见错误

#### 指向自身
虽然函数在JavaScript中也是一种对象，但是this并不是指向函数本身。

#### this指向函数的作用域
这个错误是最容易犯的了。我有时候也会想当然的this就会指向函数的作用域对象， 然后通过this.XX去获取一些属性。
1. this在任何情况下都不指向函数的词法作用域。在JavaScript内部，作用域(是不是就是我之前说的执行上下文对象)和对象比较相似，可见的标识符都是它的属性。但是作用域对象无法通过JavaScript代码访问，它存在与JavaScript引擎内部，供引擎访问。

一个错误的例子:
```javascript
function foo() {
  var a = 2;
  this.bar();
}

function bar() {
  console.log(this.a);
}

foo();//error: a is not defined

```

这个代码的错误不止一处。
* 首先，这堵代码试图通过this.bar()来引用bar函数，这样调用成功纯属意外。因为此时this执行的是全局对象，在全局环境定义的函数都是全局对象的属性。一般情况下，i调用bar()函数最直接的就是省略前面的this.
* 开发者试图采用this联通foo()和bar()de的词法作用域，从而让 bar()可以访问foo()作用域的变量a.这是不可能实现的，使用this无法在词法作用域查到信息。


2. this到底是什么？

this是在函数运行时绑定的，并不是在编写时绑定，它的上下文取决于函数调用时的各种条件。

this的绑定和函数声明的位置没有关系， 只取决于函数的调用方式。

当一个函数被调用时，会创建一个活动记录(也就是执行上下文)。这个记录会包含函数在哪里调用(调用栈)，函数的调用方式，传入的参数等现象， this就是这个记录的一个属性， 它绑定一个对象，会在函数执行的过程中用到。this究竟绑定到那个对象，在下面的"如何使用this"会有详细说明.

**记住一点:this是在函数调用时发生的绑定，它指向什么完全取决于函数在哪里被调用**

### 如何使用this

#### 函数的调用位置
理解this的绑定过程之前，首先要理解函数的调用位置，调用位置就是函数在代码中被调用的位置。

最重要的就是分析调用栈(就是为了到达当前执行位置所调用的所有函数)。我们关心的
**调用位置(函数在哪里调用)**
就是在当前正在执行的函数的前一个调用中。
```javascript

function baz() {
  //当前调用栈是baz
  // 因此当前调用位置是上一个调用，全局作用域中
  console.log("baz");
  bar(); //<---- bar的调用位置(就是在函数baz中)
}

function bar() {
  //当前调用栈是baz- --->bar
  //因此当前的调用位置在baz中
  console.log("bar");
  foo(); //<---- foo的调用位置
}

function foo() {
  //当前调用栈是baz ----> bar ----> foo
  //因此当前的调用位置在bar中
  debugger;
  console.log("foo");
}

baz(); //<---- baz的调用位置

```

#### 绑定的规则

##### 1. 默认绑定
首先是最常见的函数调用方式: 独立函数调用。
```javascript

function foo() {
  console.log(this.a);
}

var a = 2;

foo();//2

```
PS:声明在全局作用域的变量a就是全局对象的一个同名属性。

当我们调用foo()函数时，this.a被解析成全局变量a.为什么？因为在本例中，函数调用时调用位置是在全局作用域中，应用了this的默认绑定，因此this执行全局对象。

如何判断这里应用了默认绑定呢？分析调用位置来看foo()是如何调用的。foo()是直接使用不带任何修饰的函数引用进行的调用，因此只能使用默认绑定， 无法应用其他规则。

如果使用严格模式，则无法将全局对象应用于默认绑定，因此this会绑定到undefined

##### 2. 隐式绑定
调用位置是否有上下文对象，或者说是否被某个对象拥有或包含。

```javascript

function foo() {
  debugger;
  console.log(this.a);
}

var obj = {
  a: 2,
  foo: foo
}

obj.foo();
//当采用obj.foo()调用函数时，一个新的执行上下文被创建出来，通过之前的分析我们知道，创建一个执行上下文分为两个过程，一个是建立阶段，一个是代码执行阶段。this的绑定就发生在建立阶段。由于foo()函数的调用是通过obj.foo()实现的，所以此时this是绑定到obj对象上的。

//通过chrome代码调试工具我们也可以看到，只有进入了函数foo()内部，local Scope中的this才会变为obj对象，这也验证了我们之前的总结。
//

```
需要注意的是foo()函数的声明方式，以及之后是如何被当作引用属性添加到obj对象中的。
无论是直接在obj中定义还是先定义然后再为obj对象添加引用属性，这个foo函数严格意义上说都不属于obj对象。
然而调用位置会使用obj上下文来引用函数，因为我们可以认为函数被调用时obj对象"拥有"或者"包含"它。

当foo被调用时，它的前面确实加上了对obj的引用。当函数引用有上下文对象时，隐式绑定规则会把函数调用的this绑定到这个上下文对象。

**隐式丢失**
常见的this绑定问题就是被隐式绑定的函数会丢失绑定对象，也就是说此函数会应用默认绑定，从而把this绑定到全局对象或者undefined上去。
```javascript
function foo() {
  console.log(this.a);''
}

var obj = {
  a: 2,
  foo: foo
}

var bar = obj.foo;

var a = "oops, global";

bar(); // oops, global

```
虽然bar是obj.foo的一个引用，但是实际上 bar引用的是foo函数本身，因此此时的bar()其实是一个不带任何修饰的函数调用，因此应用了默认绑定。


**嵌套函数this绑定**
```javascript

var name = "clever coder";
var person = {
    name : "foocoder",
    hello : function(sth){
        var sayhello = function(sth) {
            console.log(this.name + " says " + sth);
        };
    }
}
person.hello("hello world");
//clever coder says hello world

```

在内部函数中，this没有按预想的绑定到外层函数对象上，而是绑定到了全局对象。这里普遍被认为是JavaScript语言的设计错误，因为没有人想让内部函数中的this指向全局对象。一般的处理方式是将this作为变量保存下来，一般约定为that或者self：

```javascript

var name = "clever coder";
var person = {
    name : "foocoder",
    hello : function(sth){
        var that = this; // 将外部函数绑定的this保存下来，然后在内部函数sayhello中使用
        var sayhello = function(sth) {
            console.log(that.name + " says " + sth);
        };
        sayhello(sth);
    }
}
person.hello("hello world");
//foocoder says hello world
```

**回调函数丢失this绑定也是非常常见的**

```javascript

function foo() {
  console.log(this.a);
}

function doFoo(fn) {
  //fn其实引用的是foo

  fn();//<---- 调用位置！
}

var obj = {
  a: 2,
  foo: foo
};

var a = "oops, global";

doFoo(obj.foo); // oops, global


```
将obj.foo作为参数传递给doFoo，实际上就相当于var  bar = obj.foo, doFoo(bar).参数传递其实就是一种隐式赋值， 实际传递的就是一个没有任何修饰的函数，所以最后的绑定方式为默认绑定.

可以通过bind绑定来修正上述问题。
```javascript
//prototype.js源码中bind的实现：可以参考一下
Function.prototype.bind = function(){
  var fn = this；//因为bind函数调用者为一个函数fn,函数实际上都是通过new Function得到的一个函数对象，这里的this其实就是指向函数fn本身。
  var args = Array.prototype.slice.call(arguments);
  var object = args.shift();

  return function(){
    return fn.apply(object,
      args.concat(Array.prototype.slice.call(arguments)));
  };
};

var person = {
    name : "foocoder",
    hello : function(sth){
        var sayhello = function(sth) {
            console.log(this.name + " says " + sth);
        };
    }
}

$("#some-ele").click(person.hello.bind(person));
//相应元素被点击时，输出foocoder says hello world

```

##### 3. 显式绑定(call apply bind)

在分析隐式绑定时，我们必须在一个对象的内部包含一个指向函数的属性，通过这个属性间接引用函数，从而把this间接绑定到这个对象上。
如果我们不想在对象内部包含h函数引用，而想在某个对象上强制调用函数，此时就需要用到apply()函数或者call()函数了。

它们的第一个参数是一个对象，在调用函数时，将其绑定到this上。
```javascript

function foo() {
  console.log(this.a);
}

var obj = {
  a: 2
};

foo.call(obj); // 2

```
通过foo.call(obj)我们可以在调用foo时强制把它的this绑定到obj上。

可以使用bind实现硬绑定
```javascript
function bind(fn, obj) {
  return function() {
    return fn.apply(obj, arguments);
  }
}

// bind具体使用以后补充
```


##### 4. new绑定
在JavaScript中，构造函数只是一些使用new操作符时被调用的函数。它们不属于某个类，也不会实例化一个类。使用new函数来调用函数，会自动执行下面的操作:

1. 创建一个全新的对象
2. 这个新对象会被执行[[Prototype]]连接
3. 这个新对象会绑定到函数调用的this
4. 如果函数没有返回其他对象，那么new表达式中的函数调用就会自动返回这个新对象。

```javascript

function Person(name, age) {
  this.name = name;
  this.age = age;
}

var bobo = new Person("Hanwenbo", 26);
console.log(bobo.name);

```

#### 优先级

new绑定 > 显式绑定 > 隐式绑定 > 默认绑定


### 总结
1. 当函数作为单独函数调用时，this指向全局对象（严格模式时，为undefined）

2. 当函数作为对象的方法调用时，this指向该对象。

3. 构造函数中的this指向新创建的对象

4. 嵌套函数中的this不会继承上层函数的this，如果需要，可以用一个变量保存上层函数的this。

5. 再总结的简单点，如果在函数中使用了this，只有在该函数直接被某对象调用时，该this才指向该对象。

6. 多看开源项目代码,就会熟悉 this 的使用,现在只是一些简单的使用方法,没有形成很深刻的印象.