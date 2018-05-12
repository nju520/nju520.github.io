---
layout: post
toc: true
permalink: /javascript-prototype
title: JavaScript 深入理解 prototype 
tags: JavaScript prototype OOP
desc: 如果你之前只接触过传统的OOP继承模式的话, 就会对 JavaScript 原型模型感到困惑, 但这正是JavaScript原型继承的优势所在. 实现传统的继承模型很简单, 但是实现JavaScript中的原型继承则要困难的多. 本篇文章就围绕 prototype深入探讨一下 原型继承.
---

## 原型对象
[[Prototype]]
 在面向对象语言中,类可以被复制(也就是实例化)多次,就像用模具制作东西一样.之所以会这样是因为实例化一个类就意味着"把类的行为复制到对象中",对于每一个实例来说都会重复这个过程.

 但是在 javascript 中,并没有类似的复制机制. 我只能创建多个对象,然后让他们的[[Prototype]]对象关联到同一个对象. 但是在默认情况下并不会进行复制,因此这些对象之间并不会完全失去联系, 他们是互相关联的.

 ```javascript

 function Person() {
   this.name = "hehe";
 }

 var xiaoming = new Person();
 ```

javascript 中采用 new Person()这种形式创建一个新对象,新对象的内部链接[[Prototype]]关联的是 Person.prototype对象.

**我们并没有初始化一个类,实际上我们并没有从"类"中复制任何行为到一个对象中,只是让两个对象互相关联**


==> 我们可以采用 Object.create()方法直接实现一个对象关联到另外一个对象上,这样我们就可以充分发挥[[Prototype]]的威力(委托机制)并且避免不必要的麻烦(比如使用 new 的构造函数调用会生成.prototype 和.constructor引用)

```javascript

//create 方法的简易实现形式
if(!Object.create) {
  Object.create = function(obj) {
    function F();
    F.prototype = obj;
    return new F();
  };
}
```

这段 polyfill 代码使用了一个一次性函数 F,我们通过改写它的.prototype 属性使其指向想要关联的对象, 然后再使用 new F()来构造一个新对象关联.



==> ES6可以采用 Object.setPrototypeOf(...)来直接修改对象的原型
```javascript

//ES6之前需要抛弃默认的 Bar.prototype
Bar.prototype = Object.create(Foo.prototype);

//ES6开始可以直接修改现有的 Bar.prototype
Object.setPrototypeOf(Bar.prototype, Foo.prototype)

```

### 内省(检查"类"的身份)

 \__proto__属性大致实现过程如下

 ```javascript

 Object.defineProperty(Object.prototype, "__proto__", {
   get: function() {
     return Object.getPrototypeOf(this);
   },

   set: function(obj) {
     Object.setPrototypeOf(this, obj);
     return obj;
   }
 });

 ```


## 对象的创建方式之原型模式

```javascript
function Person(name, age, job) {
  this.name = name;
  this.age = age;
  this.job = job;
}

Person.prototype.description = function() {
  console.log(this.name + this.age + this.job);
}

使用原型对象的好处就是让所有对象实例都共享它所包含的属性和方法

### 理解原型对象

**无论什么时候,只要创建了一个函数,就会根据一组特定的规则为该函数创建一个 prototype 属性,这个属性指向函数的原型对象.**
**在默认情况下,函数的原型对象都有一个 constructor 属性,这个 constructor 属性指向函数**

​```javascript

//测试一个属性是否属于原型属性
function hasPrototypeProperty(object, name) {
  return !object.hasOwnProperty(name) &&(name in object);
}
```

### 更简单的原型语法以及需要注意的一点

```javascript

function Person() {

}

Person.prototype = {
  name: "bobo",
  age: 22,
  job: "programmer",
  description: function() {
    console.log(this.name + this.age + this.job);
  }
};

var friend = new Person();
alert(friend instanceof Object);//true
alert(friend instanceof Person);//true

alert(friend.constructor == Person);//false
alert(friend.constructor == Object);//true

```
上面的代码中我们将 Person.prototype 设置为等于一个以字面量形式创建的对象,最终结果与上面的一样,但是有一个例外:
**constructor属性不再指向 Person 了,而是指向 Object**
原因: 当每创建一个函数时,系统就会同时创建它的 prototype 对象,这个对象也会自动获取 construcotr 属性,指向这个函数.也就是说,每一个原型对象都有一个 constructor 属性.
```javascript
var obj = new Person();
obj.__proto__.constructor == Person;
Person.prototype.constructor == Person;
```
现在我们Person.prototype = {...}的形式,相当于重写了默认的原型对象,这个原型对象是Object对象实例的原型对象,因此这个原型对象的 constructor 属性指向的是Object函数,不再指向原来的构造函数 Person.
尽管 instanceof 能够返回正确的结果,但是 constructor 已经无法确认对象的类型了
```javascript

var obj = new Object();//等价于 var obj = {}
obj.__proto__.constructor == Object

```

可以显式地设定原型的 constructor 属性,这样就确保通过 constructor 属性访问到正确的构造函数.
```javascript


function Person() {

}

Person.prototype = {
  constructor: Person,
  name: "bobo",
  age: 22,
  job: "programmer",
  description: function() {
    console.log(this.name + this.age + this.job);
  }
};


```
显式定义的 constructor 属性会导致它的[[Enumerable]]特性被设置为 true.默认情况下,原生的 constructor 属性是不可枚举的,因此如果想让 Enumerable 为默认的 false, 可以使用 Object.defineProperty

```javascript



function Person() {

}

Person.prototype = {
  name: "bobo",
  age: 22,
  job: "programmer",
  description: function() {
    console.log(this.name + this.age + this.job);
  }
};

Object.defineProperty(Person.prototype, "constructor", {
  enumerable: false,
  value: Person
})
```

### 原型的动态性
由于在原型上查找值的过程是一次搜索,因此我们对原型对象所做的任何修改都能够立即从实例中体现-即使是先创建了实例然后修改原型也是如此
```javascript

var friend = new Person();

Person.prototype.sayHi = function() {
  alert("Hi");
}

friend.sayHi();//Hi

```
尽管可以随时为原型添加属性和方法,并且修改能够立即在所有的实例中反映出来,但是如果是**重写整个原型对象**,那么情况就不一样.
调用构造函数时为实例添加一个指向最初原型的[[prototype]]指针,如果把原型对象修改为另外一个对象就切断了构造函数和最初原型之间的关系.
**实例中的__ proto__指针仅仅指向原型,而不是指向构造函数**

```javascript


function Person() {

}

var friend = new Person();


Person.prototype = {
  name: "bobo",
  age: 22,
  job: "programmer",
  description: function() {
    console.log(this.name + this.age + this.job);
  }
};

var myself = new Person();

myself.description();//正常显示结果  bobo22programmer

friend.description();//error
//friend 指向的最初的原型,最初的原型并没有添加任何属性和方法
//之后我们手动修改了 Person.prototype
//但是实例对象并不指向这个最新的原型对象
```