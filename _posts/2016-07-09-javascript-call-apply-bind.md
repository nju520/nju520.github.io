---
layout: post
toc: true
permalink: /javascript-call-apply-bind
title: 妙用JavaScript中的apply/call/bind
tags: JavaScript apply call bind
desc: JavaScript中, call和apply主要用途是为了扩充函数赖以生存的作用域. 通俗讲, 就是为了动态改变函数体内部的this指向. bind方法虽然用法和call和apply有差异, 但是作用也是改变函数体内的this指向.
---

## apply/call
**call和apply都是为了改变某个函数运行时的上下文(context)而存在的.换句话说, 就是为了改变函数体内部的this指向.**

>  JavaScript的一大特点就是, 函数存在 定义时上下文/运行时上下文/上下文可以动态改变 这样的概念 --

```javascript
function Fruits() {}
// Fruits.prototype = {
//   color: 'red',
//   sayColor: function() {
//   console.log('My color is ' + this.color);
//   }
// }
Fruits.prototype.color = 'red'
Fruits.prototype.sayColor = function() {
  console.log('My color is ' + this.color);
}
var apple = new Fruits();
apple.sayColor();// My color is red
```
但是如果我们与一个对象 banana = {color: 'yellow'}, 我并不想重新为它定义sayColor方法,那么我就可以使用call或者apply来调用apple的sayColor方法
```javascript
var banana = {color: 'yellow'}
apple.sayColor.apply(banana);// My color is yellow
apple.sayColor.call(banana); // My color is yellow

```
从上面的示例可以看出, call或者apply是为了动态改变this而出现的,当一个object没有某个方法, 但是其他对象已经定义了实现某个功能的方法, 我就可以借助call或apply让此object调用指定对象的方法.

## call与apply的区别
唯一区别就是接收的参数形式不太一样.
call  需要把参数按照顺序传递进去
apply 把参数放到一个数组(也包括类数组)中传入  array apply !!
```javascript
var func = function(arg1, arg2) {

};
func.call(this, arg1, arg2);
func.apply(this, [arg1, arg2]);

```
其中this是我想要指定的上下文, 它可以是任何一个javascript对象

- 使用情景:
  - JavaScript中, 如果某个函数的参数数量是不固定的, 所以当我的参数是明确的, 就使用call, 而不确定参数数量的话 就使用apply, 然后把参数push进数组中
  - 当参数数量不确定时, 函数内部也可以通过arguments这个类数组对象来遍历所有的参数.




## 更多示例

1. 数组之间追加
```javascript
var array1 = [12 , "foo" , {name "Joe"} , -2458];
var array2 = ["Doe" , 555 , 100];
// array1.push("Doe", 555, 100); // 正常调用
Array.prototype.push.apply(array1, array2);
/* array1 值为  [12 , "foo" , {name "Joe"} , -2458 , "Doe" , 555 , 100] */
```
2. 获取数组中的最大值和最小值
```javascript
var  numbers = [5, 458 , 120 , -215 ];
var max = Math.max.apply(Math, numbers);//458
// var max = Math.max(5,458,120,-215);//正常调用
var min = Math.min.apply(Math, numbers);//-215
// var min = Math.min(5,458,120,-215);//正常调用
//数组numbers本身没有max方法, 我可以借助apply使用Math中的max方法
```
3. 验证对象是否是数组(前提是toString方法没有被重写)
```javascript
function isArray(obj) {
  return Object.prototype.toString.call(obj) === '[object Array]'
}
```

4 类数组使用数组方法(比较常见的就是函数参数对象arguments)
Javascript中存在一种名为伪数组的对象结构。比较特别的是 arguments 对象，还有像调用 getElementsByTagName , document.childNodes 之类的，它们返回NodeList对象都属于伪数组, 不能应用 Array下的push, pop等方法。
但是我们能通过 Array.prototype.slice.call 转换为真正的数组的带有length属性的对象，这样domNodes就可以应用Array下的所有方法了。
```javascript
var domNodes = Array.prototype.slice.call(document.getElementsByTagName('*'));
var domNodes = [].slice.call(document.getElementsByTagName('*'));

// 我还可以通过bind进行简化
var unboundSlice = Array.prototype.slice;
var slice = Function.prototype.call.bind(unboundSlice);
//这里function原型中的call方法绑定unboundSlice对象, 调用返回的函数就等价于 绑定对象unboundSlice调用Function下面的call方法
// 这与调用 [].slice.call(arguments) 是一样的.
// call方法是Function.prototype中的一个方法
var domNodes = slice(document.getElementsByTagName('*'));

```
5.一道面试题
定义一个log方法,让它可以代理console.log方法
```javascript
function log(msg) {
  console.log(msg);
};
log(1);//1
log(1,2,3,);//1
```
当传入多个参数给上面的log方法时, 就要考虑使用apply或者call方法了, 注意这里传入的参数是不确定的,所以最好的选择是apply
```javascript
function log() {
  console.log.apply(console, arguments);
}
log(1);//1
log(1,2,3);//1,2,3
```
接下来的要求是给每一个log消息添加一个(app)的前缀, 比如
```javascript
log('hello world'); //(app)hello world
```
该怎么做才比较优雅呢?
函数参数对象arguments是类数组, 我可以通过上面的类数组转换为数组的方法, 再使用数组的方法unshift在数组的头部添加'(app)'
```javascript
function log() {
  // var args = [].slice.apply(arguments); //arguments是类数组,所以这里也可以使用apply
  var args = [].slice.call(arguments);
  args.unshift('(app)');
  console.log.apply(console, args);
}
```

## bind
bind()方法与apply和call类似, 也是可以改变函数体内的this的指向.
MDN的解释:
**bind()方法会创建一个新函数,称为绑定函数, 当调用这个绑定函数时,
绑定函数会以创建它时传入的bind()方法第一个参数作为this,
传入bind()方法第二个以及以后的参数+绑定函数运行时传入的参数,按照顺序作为原函数的参数来调用原函数**
示例:
1. 在常见的单体模式下, 我们通常会使用self等保存this, 这样我们可以在改变了上下文之后继续引用到它
```javascript
var foo = {
  bar: 1,
  eventBind: function() {
    var self = this;
    $('.calss').on('click', function(event) {
      //Act on the event
      console.log(self.bar);//1
    });
  }
}
```
由于 Javascript特有的机制，上下文环境在 eventBind:function(){ } 过渡到$('.class').on('click', function(event) {})发生了改变，上述使用变量保存this这些方式都是有用的，也没有什么问题。当然使用 bind() 可以更加优雅的解决这个问题：

```javascript
var foo = {
  bar: 1,
  eventBind: function() {
    $('.class').on('click', function(event) {
      console.log(this.bar).bind(this);//匿名函数的绑定
    })
  }
}
```
上述代码中, bind()创建了一个函数,当这个click事件绑定在被调用的时候, 它的this关键词会被设置成传入的值, 因此这样我传入了想要的上下文this(其实就是foo)到bind方法中. 当回调函数被执行的时候, this便指向foo对象

2. 分离函数（Partial Functions）
  bind()的另一个最简单的用法是使一个函数拥有预设的初始参数。这些参数（如果有的话）作为bind()的第二个参数跟在this（或其他对象）后面，之后它们会被插入到目标函数的参数列表的开始位置，传递给绑定函数的参数会跟在它们的后面。
```javascript
function list() {
  return Array.prototype.slice.call(arguments);
}

var list1 = list(1, 2, 3); // [1, 2, 3]
// Create a function with a preset leading argument
var leadingThirtysevenList = list.bind(undefined, 37);
var list2 = leadingThirtysevenList(); // [37]
var list3 = leadingThirtysevenList(1, 2, 3); // [37, 1, 2, 3]
```
有个有趣的问题，如果连续 bind() 两次，亦或者是连续 bind() 三次那么输出的值是什么呢？
```javascript
var bar = function(){
    console.log(this.x);
}
var foo = {
    x:3
}
var sed = {
    x:4
}
var func = bar.bind(foo).bind(sed);
func(); //?

var fiv = {
    x:5
}
var func = bar.bind(foo).bind(sed).bind(fiv);
func(); //?
```
答案是两次输出都是3.
原因是在javascript中多次绑定bind是无效的.更深层的原因是, bind()方法的实现, 相当于使用函数内部包了一个call/apply, 此时的this已经确定了.第二次bind()相当于再包住第一次的bind(), 所以第二次的之后的bind()是无效的

3. 实现currying
  除了第一个实参外，传入bind()的实参也会绑定到 this,这个应用就是一种常见的编程技术，柯里化
```javascript
function curry(fn) {
  var args = Array.prototype.slice.call(arguments, 1); //获取第一个参数之后的所有参数!!!
  return function() {
    var innerArgs = Array.prototype.slice.call(arguments);
    var finalArgs = args.concat(innerArgs); // 内部函数中innerArgs保存了传入的参数
    return fn.apply(null, finalArgs);
  }
}

function add(num1, num2) {
  return num1 + num2;
}
var curriedAdd = curry(add, 5);
curriedAdd(3); //8

```

```javascript
var sum = function(y, z) {return this.x + y + z }
var obj = {x:100}
var g = sum.bind(obj, 2)
g(3);//=>6 this.x 绑定到100， y绑定到2， z绑定到3
```
4. 手动实现bind方法
```javascript
if(!Function.prototype.bind) {
  Function.prototype.bind = function(obj) {
    var self = this;//self就是要绑定指定对象的函数
    var boundArgs = arguments;
    return function() {
      var args = [];
      var i;
      // for(i = 1; i < boundArgs.length; i++) args.push(boundArgs[i]);
      // for(i = 0; i < arguments.length; i++) args.push(boundArgs[i]);
      //将self作为obj的方法来调用， 传入整合之后的实参
      // return self.apply(obj, args);

      var outArgs = Array.prototype.slice.call(arguments, 1);
      F = function() {};
      functionToBind = this;
      fBound = functionToBind.apply(this, outArgs.concat(Array.prototype.slice.call(arguments)))
      F.prototype = this.prototype;
      functionToBind.prototype = new F();
      return functionToBind;
    }
  }
}
```
## apply call bind 的比较
```javascript
var obj = {
    x: 81,
};

var foo = {
    getX: function() {
        return this.x;
    }
}

console.log(foo.getX.bind(obj)());  //81
console.log(foo.getX.call(obj));    //81
console.log(foo.getX.apply(obj));   //81
```
三个输出的都是81，但是注意看使用 bind() 方法的，他后面多了对括号。
也就是说，区别是，当你希望改变上下文环境之后并非立即执行，而是回调执行的时候，使用 bind() 方法。
而 apply/call 则会立即执行函数。

---
- 再次总结一下:
  - apply call bind 三者都是用来改变函数的this对象的指向的
  - apply call bind 三者的第一个参数都是this要指向的对象, 也就是想要指定的上下文
  - apply call bind 三者都可以利用后续参数传参
  - bind 返回的是一个函数, 便于稍后调用; apply call 则是立即调用