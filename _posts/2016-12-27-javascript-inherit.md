---
layout: post
toc: true
permalink: /javascript-inherit
title: JavaScript 继承模式
tags: JavaScript inherit
desc: 上一篇文章我们对JavaScript的原型有了深入的了解, 本篇文章继续阐述 JavaScript中的继承模式.
---

## 继承

### 原型链
**利用原型让一个引用类型继承另一个引用类型的属性和方法**

#### 阐述原型继承连

JavaScript中的每个对象，都有一个内置的_proto_属性,它实际上是对另一个对象或者null的引用。

当一个对象需要引用一个属性时，JavaScript引擎首先会从这个对象自身的属性表中寻找这个属性标识，如果找到则进行相应读写操作，若没有在自身的属性表中找到，则在_proto_属性引用的对象的属性表中查找，如此往复，直到找到这个属性或者_proto_属性指向null为止。

这个_proto_的引用链，被称作原型链。



```javascript

function SuperType() {
  this.property = true;
}

SuperType.prototype.getSuperValue = function() {
  return this.property;
}

function SubType() {
  this.subproperty = false;
}

//SubType 继承了 SuperType
//实现的本质是重写了 SubType.prototype 原型对象
//但是有个问题是现在 SubType.prototype.constructor指向的是 SuperType,在 javascript 对象章节已经阐述过原因
//var obj =  new SuperType() 实例对象
// obj.__proto__.constructor == SuperType
//所以 SubType.prototype.constructor == SuperType
SubType.prototype = new SuperType();

SubType.prototype.getSubValue = function() {
  return this.subproperty;
}

var instance = new SubType();
console.log(instance.getSuperValue());//true
console.log(instance.getSubValue());//false

```

如果需要添加方法,需谨慎

```javascript

function SuperType() {
  this.property = true;
}

SuperType.prototype.getSuperValue = function() {
  return this.property;
}

function SubType() {
  this.subproperty = false;
}

SubType.prototype = new SuperType();

//添加新方法
SubType.prototype.getSubValue = function() {
  return this.subproperty;
}

//重写超类型中的方法
SubType.prototype.getSuperValue = function() {
  return false;
}

//子类重写了超类的 getSuperValue
var instance = new SubType();
instance.getSuperValue();//false

//SuperType的实例还是调用原来的 getSuperValue 方法
var superInstance = new SuperType();
superInstance.getSuperValue();// true

```

#### 原型链继承的问题
1. 包含引用类型值得原型, 原型属性会被所有实例共享
2. 在创建子类实例时,无法向超类的构造函数中传递参数.

### 借助构造函数实现继承(经典继承)
**在子类型构造函数的内部调用超类型的构造函数**,函数只不过是在特定环境下执行代码的对象,因此可以通过 call 或者 apply 方法可以在(将来)新创建的对象上执行构造函数
```javascript

function SuperType() {
  this.colors = ["red", "blue", "green"];

  function SubType() {
    //继承了 SuperType
    //通过 call 或者 apply,在(未来将要)创建的 SubType 实例的环境下调用 SuperType 构造函数
    //这样一来,我们在新的 SubType对象上执行 SuperType()函数中定义的所有对象初始化代码.
    SuperType.call(this);
  }

  var instance = new SubType();
  instance.colors.push("black");
  alert(instance.colors); // red, blue, green, black

  var instance2 = new SubType();
  alert(instance.colors); // red, blue, green
}


```

1. 可以传递参数

在子类型构造函数中向超类构造函数传递参数.

```javascript

function SuperType(name) {
  this.name = name;
}
function SubType(name) {
  //继承了 SuperType
  SuperType.call(this, name);
}

var instance = new SubType("bobo");
alert(instance.name); // rbobo

}


```


### 组合继承(原型链+构造函数)
使用原型链实现对原型属性和方法的继承,通过借助构造函数实现实例属性的继承.

```javascript

function SuperType(name) {
  this.name = name;
  this.colors = ["red", "blue", "green"];
}

SuperType.prototype.sayName = function() {
  console.log(this.name);
}


function SubType(name, age) {
  SuperType.call(this, name);
  this.age = age;
}


SubType.prototype = new SuperType();

SubType.prototype.constructor = SubType;

SubType.prototype.sayAge = function() {
  console.log(this.age);
}

var instance = new SubType("bobo", 27);
instance.colors.push("black");
console.log(instance.colors);
console.log(instance.sayName());
console.log(instance.sayAge());


var instance2 = new SuperType("yanzi");
console.log(instance2.colors);
console.log(instance2.sayName());

```