---
layout: post
toc: true
permalink: /javascript-bind
title: JavaScript bind 原理和实现 
tags: JavaScript bind
desc: JavaScript中的函数绑定(Function binding)很可能是开发者在使用JavaScript时最少关注的一点. 但是当我们意识到需要一个解决方案来解决如何在另外一个函数中保持this上下文的时候, 我们真正需要的就是 Function.prototype.bind(). 本篇文章就从bind原理开始, 阐述 bind 的存在价值以及手动实现 bind
---

## bind 原理

bind是 ECMAScript 新增的方法, 这个方法的主要作用就是将函数绑定到某个对象.

当在函数 func()上调用 bind()方法并传入一个对象比如 bobo 作为参数, 返回一个新的函数.
返回的函数运行时以传入的第一个对象作为 this. 当这个新的函数以函数调用的方式调用时, 就会把this 指向之前绑定的对象上, 也就相当于对象 bobo 将 func()函数当做自己的方法来调用.

bind 方法不仅仅是将函数绑定到一个对象上, 还可以将传入的除对象之外的参数包裹起来, 返回函数调用的时候使用.比如下面的第二个参数23.

```javascript
function func(age, job) {
  console.log(this.name);
  console.log(age);
  console.log(job);
}

var bobo = {name: "bobo"};
var bindFunc = func.bind(bobo, 23);
bindFunc("coder"); // bobo 23 coder

```

## bind 实现
如果想要对 bind 函数更深层次的理解, 最好可以自己实现原生的 bind 函数.
bind 是 Function.prototype 上定义的方法, 因此每个函数作为 Function 的实例对象, 通过原型继承的方式都能够调用 bind 方法.
我可以在 Function.prototype 上实现自定义的 bind 方法.

### 基础版本

```javascript

Function.prototype.myBind = function(context) {
  //!!这个 this 其实就是我们被绑定的函数. 因为被绑定的函数实际上就是 Function 的一个实例
  // 实例通过原型继承拥有 bind 方法, 因此 func.bind()运行时, this指向的就是 func.
  // 这里将 this 保存下来, 因为返回一个闭包时外层的 this 将不会得到保存.
  var self = this;
  return function() {
    self.apply(context);//apply可以将函数func 运行时的 this 绑定到传入的第一个参数上
  }
}

var obj = {
  name: 'bobo',
  age: 23
}

function func() {
  console.log(this.name + " " + this.age);
}

var bindFunc = func.myBind(obj);
bindFunc(); //bobo 23

```

### 可以实现柯里化
我们可以在 bind 时传入一部分参数, 在调用返回的绑定函数时,将剩余的参数传入.
这个技术是一种常见的函数式编程, 被称为"柯里化"

``` javascript

Function.prototype.myBind = function(context) {
  var self = this;
  //将除了第一个 context 参数保存到 args 变量中
  var args = Array.prototype.slice.call(arguments, 1); //返回值是一个数组

  return function() {
    var bindArgs = Array.prototype.slice.call(arguments); //返回值同样是一个数组
    self.apply(context, args.concat(bindArgs) )
  }
}

var bobo = {
  name: 'bobo',
}

function func(age, job) {
  console.log(this.name);
  console.log(age);
  console.log(job);
}

var bindFunc = func.myBind(bobo, 23);
bindFunc("coder");
// bobo
// 23
// coder

```

### 绑定的函数可以作为构造函数使用

ECMAScript5定义的 bind 方法,可以使用 new操作符来创建新对象: 这种行为就是把原函数当成构造器.
我们提供的上下文对象被忽略, 但是剩下的参数还是可以提供给绑定函数使用的.
==>当 bind 返回的函数作为构造函数使用时, bind 时指定的 this 就会失效, 此时的 this 应该是执行new绑定规则.

下面的代码最难理解的就是this的指向问题.

```javascript
//this的指向是在函数调用时确定的, 一共有四种形式的绑定: 默认绑定, 隐式绑定, 显式绑定, new绑定.
//第一行的目的就是保存外部函数的this, 如果不保存的话,我们就无法在闭包中使用外部函数绑定的this.
var self = this;

//这一行更难理解, 难点在于容易将this和self混淆.
//此时的self就是第一行保存的this,self指向原始函数func, 第一个参数就是func需要绑定的对象.
//当内部闭包的this是func的一个实例时, func的调用形式是构造函数new bindFunc, this指向的是新创建的一个对象
//当内部闭包的this不是指向func的一个实例时, 说明调用的bindFunc是普通的函数调用, 此时bindFunc就绑定到传入的第一个参数
self.apply(this instanceof self ? this : context, args.concat(bindArgs));

//这一行让bindFunc的原型继承自func的原型, 当采用构造函数的调用形式调用binfFunc时,创建的新对象就会继承func.prototype上的方法
//当以普通形式调用bindFunc时,这一行代码自动忽略
bindFunc.prototype = this.prototype;

```

```javascript

Function.prototype.myBind = function(context) {
  // self指向的就是我们被绑定的函数, eg: func.bind(obj). self指向的是 func
  // bindFunc 为闭包,因为必须先把 self 保存下来作为一个变量传入 闭包.
  var self = this;
  var args = [].slice.call(arguments, 1);

  var bindFunc = function() {
    //闭包中的this取决于bindFunc运行时的情况

    var bindArgs = [].slice.call(arguments);
    //当通过new 构造出一个实例的时候, 会将 this 指向构造出的新对象.
    // 虽然我们最后构造对象时是采用new bindFunc的形式. 但是构造函数实际上是我们的被绑定函数 func
    // 构造函数调用四部曲
    // 1. 创建一个新的对象
    // 2. 新的对象的原型继承自构造函数的原型
    // 3. 构造函数中 this 执行这个新对象.!!!!此时就相当于新对象将构造函数当做自己的方法调用, 所以才会有 this.name = name 这种操作
    // 4. 构造函数返回值这个心对象

    // (this instanceof self) === true时, this 就是运行 new bindFunc 时 this 的指向对象, 它指向的就是新创建的实例对象
    // (this instanceof self) === false时,调用bindFunc的形式是直接调用, 此时让 this 指向我们传入的第一个参数
    self.apply(this instanceof self ? this : context, args.concat(bindArgs));
  }


  //绑定函数的 prototype 指向 this.prototype,也就是 func.prototype
  //在使用 new bindFunc 创建出的实例就可以继承构造函数原型中的值.
  // 这里的this和第一行var self = this;是一样的, 都是指向我们的原始函数func
  // 这里并不是上面的bindFunc作用域中!!!!
  bindFunc.prototype = this.prototype;

  return bindFunc;
}


var bobo = {
  name: 'bobo'
};

function func(age, job) {
  this.hobbit = "programming";
  console.log(this.name);
  this.age = age;
  this.job = job;
}
func.prototype.friend = "Mac";
func.prototype.sayHi = function() {
  console.log("Hi, " + this.friend);
};


var Func = func.myBind(bobo, 23);

//采用直接调用的形式调用Func, func中的this是指向的bobo对象
var hehe = Func("coder"); //打印bobo.name属性 --> bobo
//以普通形式调用FUnc时, Func("coder")的返回值为undefined

//当我们采用 new 操作符调用 Func 时, 此时就创建了一个新的实例对象, 实例对象将构造函数作为自己的方法调用, 此时根据 this 的指向规则, this 指向调用方法的对象!!!!
var obj = new Func('coder');

console.log(obj.name);
console.log(obj.age);
console.log(obj.job);

console.log(obj.sayHi());

```
上面的自定义 bind 基本上可以完成我们的需求,但是有一个需要改进的地方就是返回的闭包函数的原型继承.
如果直接采用上述的方式:

```javascript
bindFunc.prototype = this.prototype;
```
根据之前继承的几种方式,这种情况下如果我们修改 bindFunc 的原型,就会影响被绑定函数的 prototype.
这个时候就需要一个空对象来作为继承链的中间对象过渡.


```javascript

Function.prototype.myBind = function(context) {
  // self指向的就是我们被绑定的函数, eg: func.bind(obj). self指向的是 func
  var self = this;
  var args = [].slice.call(arguments, 1);

  var Ctor = function() {}

  // bindFunc 为闭包,因为必须先把 self 保存下来作为一个变量传入 闭包.
  var bindFunc = function() {
    var bindArgs = [].slice.call(arguments);
    //当通过new 构造出一个实例的时候, 会将 this 执行构造出的新对象.
    // 虽然我们最后构造对象时是采用new bindFunc的形式. 但是构造函数实际上是我们的被绑定函数 func
    // 构造函数调用四部曲
    // 1. 创建一个新的对象
    // 2. 新的对象的原型继承自构造函数的原型
    // 3. 构造函数中 this 执行这个新对象.!!!!此时就相当于新对象将构造函数当做自己的方法调用, 所以才会有 this.name = name 这种操作
    // 4. 构造函数返回值这个心对象
    self.apply(this instanceof self ? this : context, args.concat(bindArgs));
  }

  //典型的原型链继承形式. <JavaScript 高级程序设计> P169
  Ctor.prototype = this.prototype
  bindFunc.prototype = new Ctor();

  return bindFunc;
}

var bobo = {
  name: 'bobo'
};

function func(age, job) {
  this.hobbit = "programming";
  console.log(this.name);
  this.age = age;
  this.job = job;
}
func.prototype.friend = "Mac";
func.prototype.sayHi = function() {
  console.log("Hi, " + this.friend);
};

var Func = func.myBind(bobo, 23);
//当我们采用 new 操作符调用 Func 时, 此时就创建了一个新的实例对象, 实例对象将构造函数作为自己的方法调用, 此时根据 this 的指向规则, this 指向调用方法的对象!!!!
var obj = new Func('coder');

console.log(obj.name);
console.log(obj.age);
console.log(obj.job);

console.log(obj.sayHi());

```

### 最终版本
1. 调用 bind 时调用者不是函数如何处理?
  直接报错

```javascript

if(typeof this != "function") {
  throw new Error("Function.prototype.bind--what is trying is not callable");
}

```

2. 版本兼容
  如果存在原生的 bind 方法就采用原生bind方法, 否则采用我们自己定义的 bind方法

```javascript

Function.prototype.bind = Function.prototype.bind || function() {
  ...
}
```

3. 最终版本

```javascript

Function.prototype.bind = function(context) {
  if(Function.prototype.bind) {
    return Function.prototype.bind;
  }

  if(typeof this != "function") {
    throw new Error("Function.prototype.bind--what is trying is not callable");
  }

  var self = this;
  var args = [].slice.call(arguments, 1);

  var Ctor = function() {}

  var bindFunc = function() {
    var bindArgs = [].slice.call(arguments);
    self.apply(this instanceof self ? this : context, args.concat(bindArgs));
  }

  //典型的原型链继承形式. <JavaScript 高级程序设计> P169
  Ctor.prototype = this.prototype
  bindFunc.prototype = new Ctor();

  return bindFunc;
}

```