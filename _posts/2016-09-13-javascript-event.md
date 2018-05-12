---
layout: post
toc: true
permalink: /javascript-event
title: JavaScript 与 事件 
tags: JavaScript event 
desc: 与浏览器进行交互时浏览器会触发各种事件, 我们可以通过编写 JavaScript来监听事件.JavaScript是一套频繁使用事件机制的动态语言, 熟悉并掌握时间机制对于Web开发者开始至关重要.
---

## 事件机制
与浏览器进行交互的时候浏览器就会触发各种事件。比如当我们打开某一个网页的时候，浏览器加载完成了这个网页，就会触发一个 load 事件；当我们点击页面中的某一个“地方”，浏览器就会在那个“地方”触发一个 click 事件。

这样，我们就可以编写 JavaScript，通过监听某一个事件，来实现某些功能扩展。例如监听 load 事件，显示欢迎信息，那么当浏览器加载完一个网页之后，就会显示欢迎信息。

JavaScript 与 HTML 之间的交互式通过事件实现的.

事件: 就是文档或者浏览器窗口中发生的一些特定的交互瞬间.简而言之,事件就是 Web 浏览器通知应用程序发生了什么事情.

JavaScript通过浏览器提供的事件 API和用户交互,接受用户的输入.用于用户的行为是无法预知的,也就是说不知道用户什么时候点击了按钮,什么时候滚动页面等操作.因此JavaScript 不可能一直等待用户操作完毕之后才去执行后面的代码.
下面的 NodeJS 代码中,接受用户的输入的方法是在' readable'事件中调用的.后面的代码不会被阻塞.

```javascript
'use strict';

process.stdin.on('readable', () => {
    var chunk = process.stdin.read();
    if (chunk !== null) {
        process.stdout.write(`Async output data: ${chunk}`);
    }
});

process.stdin.on('end', () => {
    process.stdout.write('end');
});

console.log('Will not be blocked');
```

可以使用处理程序来预订事件,当事件发生时就会执行相应的代码.这种在传统软件工程中被称之为观察者模型.

事件驱动程序模型基本的实现原理基本上都是使用 事件循环（Event Loop），这部分内容涉及浏览器事件模型、回调原理，https://www.youtube.com/watch?v=8aGhZQkoFbQ

## 事件流

**事件流描述的是从页面中接受事件的顺序**

### 事件冒泡
IE 的事件流成为事件冒泡, 即事件开始时由最具体的元素接收,然后逐级向上传播到不具体的节点(文档).
IE9,FireFox,Chrome,Safari 将事件一直冒泡到 window对象.

### 事件捕获
Netscape 团队提出的另一种事件流叫做事件捕获.事件捕获的思想就是不太具体的节点应该更早接收到事件, 而最具体的节点应该最后接收到事件.
事件捕获的用意在事件到达预订目标前就捕获它.

尽管 "DOM2级事件"规范要求事件应该从 document 对象开始传播,但是基本上所有的浏览器都是从 window 对象开始捕获事件的.

### DOM 事件流

![event stream](/Users/bobo/Fight_FrontEnd/javascript_core/Event/images/event_stream.jpg)

"DOM2级事件"规定的事件流包括三个阶段:事件捕获阶段, 处于目标阶段, 事件冒泡阶段.

在 DOM 事件流中,实际的目标在捕获阶段不会接收到事件.这意味着在捕获阶段, 事件从 document 到 具体元素的父元素就停止了.
==> 从 window 对象到目标元素的父元素这一过程就是"捕获阶段"

下一阶段是"处于目标"阶段,于是事件在<target>元素上发生,并在事件处理中被看做冒泡阶段的一部分.
==> 捕获阶段结束时,事件到达了目标元素的父节点,最终达到目标节点,并在目标节点上触发这个事件,这就是"处于目标阶段"

最后冒泡阶段发生, 事件又传播到文档.
==>当事件到达目标节点之后,就会原路返回,这个过程类似水泡从水底浮出水面的过程,所以此过程被称之为"冒泡阶段"


多数支持 DOM 事件流的浏览器都实现了一种特定的行为: 即使" DOM2级事件"规范明确要求捕获阶段不会涉及事件目标,但是很多浏览器仍然会在捕获阶段出发事件对象上的事件. 结果就是两个机会在目标对象上操作事件.


## 事件处理程序
事件就是用户或者浏览器自身执行的某种动作. 诸如 click, load 和 mouseover 都是事件的名字.
响应某个事件的函数就是事件处理程序(事件侦听器).事件处理程序的名字都是以"on"开头. 为事件指定事件处理程序方式有一下几种方式:

### HTML内联属性
某个元素支持的每种事件,都可以使用一个与相应事件处理程序同名的 HTML 特性来指定. 这个特性的值应该是能够执行的 JavaScript 代码.

```html
<input type="button" name="" value="Click me" onclick = "alert('clicked!')" />
```
当单击这个按钮时,就会显示一个警示窗.由于这个值是 JavaScript,因此不能在其中使用未经过转义的 HTML 语法字符, & "" < >


### DOM 属性绑定
将一个函数赋值给一个事件处理程序属性.也就是直接设置某个 DOM节点的属性来指定事件和事件处理程序.
每个元素(包括 window 对象和 document对象)都有自己的事件处理程序属性, 这些属性通常为小写, 例如 onclick. 将这个属性的值设置为一个函数, 就可以指定事件处理程序.

```javascript
var button = document.getElementById("myBtn");
button.onclick = function() {
  alert("Clicked");
  alert(this.id);//myBtn
}

```
我们通过文档对象取得了一个按钮的引用,然后为它指定了 onclick 事件处理程序.

使用 DOM0级方法指定的事件处理程序被认为是元素的方法.因此这时候的事件处理程序是在元素的作用域中运行,程序的 this 就是指向当前元素.
**以这种形式添加的事件处理程序会在事件流的冒泡阶段被处理.**

### DOM2级事件处理程序(事件监听函数)
"DOM2级事件"定义了两个方法,用于处理指定和删除事件处理程序的操作: addEventListener()和 removeEventListener().
所有的 DOM 节点都包含这两个参数,它们都接收三个参数: 要处理的事件名, 作为事件处理程序的函数, 一个布尔值.
布尔值为 true 时表示在捕获阶段调用事件处理程序;为 false 时表示在冒泡阶段调用事件处理程序

```javascript
var button = document.getElementById("myBtn");
var handler = function() {
  alert('Clicked');
  alert(this.id);
};
button.addEventListener('click', handler, false);

button.removeEventListener('click', handler, false);

```
上面的代码就是为一个按钮添加了 onclick事件处理程序,而且该事件会在冒泡阶段被触发(最后一个参数为 false).
可以使用 addEventListener()为一个元素添加多个处理程序.
通过 addEventListener()添加的事件处理程序只能使用 removeEventListener()来移除,移除时传入的参数与添加处理程序时使用的参数相同. 这意味着通过 addEventListener()添加的匿名函数无法被移除.

### IE事件处理程序
IE 采用的是 attachEvent()函数和 detachEvent()函数.
这两个方法接受相同的两个参数:事件处理程序名称和事件处理程序函数.
由于 IE8及更早的版本只支持事件冒泡,因此通过 attachEvent()添加的事件处理程序都会被添加到冒泡阶段.

```javascript

var button = document.getElementById('myBtn');
var handler = function() {
  alert('Clicked');
  //IE 的 attachEvent 方法下, 事件处理会在全局作用域中运行,此时 this 就是 window
  alert(this === window);
};

button.attachEvent('onclick', handler); //注意第一个参数是on 开头的事件名称
button.detachEvent('onclick', handler); //删除事件处理程序

```

### 跨浏览器的事件处理程序
见文件 eventUtil.js


## 事件对象
在触发 DOM 上的某个事件时,会产生一个事件对象 event,这个对象包含着所有与事件有关的信息. 包括导致事件的元素, 事件的类型, 以及其他特定事件相关的信息.
例如,鼠标操作导致的事件对象中, 会包含鼠标的位置信息;键盘操作导致的事件对象中, 会包含与按下的键有关的信息.

所有的浏览器都支持 event 对象,但是支持方式有所区别.

### DOM 中的事件对象
兼容 DOM 的浏览器会将一个 event 对象传入到事件处理程序中. 无论指定事件处理程序时使用什么方法, 都会传入 event 对象.
我自己的理解:当事件被触发时,浏览器就会调用之前绑定的事件监听函数, 调用的时候给这个事件监听函数传入一个参数 event,如果定义事件监听函数时没有参数, event 就不会传入;如果定义事件监听函数时有一个参数, 那么就将 event 对象赋值给这个参数, 这个参数的名称并不重要.

```javascript

var button = document.getElementById('myBtn');
var handler = function(event) {
  alert(event.type);
};

button.addEventListener('click', handler, false);
```
在通过 HTML 属性指定事件处理程序时,变量 event 保存着 event 对象

```html
<input type="button" name="" value="Click me" onclick = "alert(event.type)" />
```
**event 对象包含与创建它的特定事件有关的属性和方法**

  bubble |事件是否冒泡
  cancelable| 是否可以取消事件的默认行为,如果为 true, 则可以调用 preventDefault()函数
  currentTarget| 事件处理程序当前正在处理的元素,也就是事件通过捕获或者冒泡的过程中所途径的元素节点
  defaultPrevented|
  detail|
  eventPhase| 调用事件处理程序的阶段
  preventDefault()| 取消事件的默认行为
  stopImmediatePropagation() | 取消事件的进一步捕获或者冒泡. 同时阻止任何事件处理程序被调用
  stopPropogation() |只是取消了事件的进一步的捕获或者冒泡
  target| **事件的目标,也就是事件触发时的元素**
  trusted|
  type| 被触发事件的类型
  view|


**只有在事件处理程序执行期间, event 对象才存在;一旦事件处理程序执行完成, event 对象就会被销毁**


### IE 中的事件对象

cancelBubble | 取消事件冒泡
returnValue | 默认值为 true,将其设置为 false 就可以取消事件的默认行为(与 preventDefault()方法的作用相同)
 srcElement | 事件的目标(与 DOM 中的 target 属性相同)


### 跨浏览器的事件对象
见 eventUtil 文件2

## 事件类型

* UI(User Interaface, 用户界面)事件, 当用户与页面上的元素交互时触发
* 焦点事件, 当元素获得或者失去焦点时触发
* 鼠标事件
* 滚轮事件
* 文本事件: 当在文档中输入文本时触发
* 键盘事件:
* 合成事件: 当为 IME( 输入法编辑器)输入字符时触发
* 变动事件: 当底层 DOM结构发生变化时触发

**具体事件的用法需要进一步强化, 等看完基础知识的时候, 就需要多写页面来熟悉每个事件的使用**

## 内存和性能

事件委托: 利用了事件冒泡,只指定一个事件处理程序, 就可以管理某一类型的所有事件.



## 模拟事件

createEvent()
可以在 document 对象上使用 createEvent()方法来创建 event 对象. 这个方法接收一个参数, 即表示要创建的事件类型的字符串.
在创建 event 对象之后, 还需要使用与事件有关的信息对其进行初始化.

```javascript
var button = document.getElementById('myBtn');

//创建事件对象
var event = document.createEvent('MouseEvents');

//初始化事件对象
event.initMouseEvent("click", ****);

button.dispatchEvent(event); //触发事件

```

## 自定义事件

```javascript
var div = document.getElementById('myDiv');
var event;

EventUtil.addHandler(div, 'myevent', function() {
  alert('Div');
}, false);

EventUtil.addHandler(document, 'myevent',function() {
  alert("document");
}, false;)

if(document.implementaton.hasFeature("CustomEvents", "3.0")) {
  event = document.createEvent("myevent");
  event.document.initCustomEvent('myevent', true, false, "刹那芳华");
  div.dispatchEvent(event);
}
```


### 事件调用顺序
1. 通过设置对象属性或者 HTML 属性注册的处理程序优先调用.
2. 使用 addEventListener()注册的处理程序按照它们注册的顺序调用
3. 使用 attachEvent()注册的处理程序可能按照任意顺序调用, 所以代码不应该依赖于调用顺序.





## 通用的事件处理库



通过以上的分析, 我们完全可以完成一个简略版的隔离浏览器差异的 JavaScript 事件处理库.



~~~javascript
//EventUtil 库就是隔离浏览器差异的 JavaScript 事件处理库.

var EventUtil = {
  addHandler: function(element, type, handler) {
    if(element.addEventListener) {
      element.addEventListener(type, handler, false);
    } else if(element.attachEvent) {
      element.attachEvent('on' + type, function(event) {
        //把处理程序作为事件目标的方法调用传递给事件对象
        return handler.call(target, event);
      });
    } else {
      element['on' + type] = handler;
    }
  },

  getEvent: function(event) {
    return event ? event : window.event;
  },

  getTarget: function(event) {
    return event.target || event.srcElement;
  },

  preventDefault: function(event) {
    if(event.preventDefault) {
      event.preventDefault();
    } else {
      event.returnValue = false;
    }
  },



  removeHandler: function(element, type, handler) {
    if(element.removeEventListener) {
      element.removeEventListener(type, handler, false);
    } else if(element.detachEvent) {
      element.detachEvent('on' + type, handler);
    } else {
      element['on' + type] = null;
    }
  },

  stopPropogation: function() {
    if(event.stopPropogation) {
      event.stopPropogation();
    } else {
      event.cancelBubble = true;
    }
  }


}



// use EventUtil to add and remove event handler

var button = document.getElementById('myBtn');
var handler = function() {
  alert('Clicked');
}

EventUtil.addHandler(button, handler, false);

// balabala
EventUtil.removeHandler(button, handler, false);

//getEvent()方法: 它返回对 event对象的引用.在使用这个方法时,我们必须假定有一个事件对象传入到事件处理程序中, 而且要把该变量的值传给这个方法.


button.onclick = function(event) {
  event = EventUtil.getEvent(event);
}
//在兼容DOM的浏览器中, event 变量只是简单的传入和返回.在 IE 中, event 的参数未定义(undefined),因此就会返回 window.event.



//EventUtil 暂时还未考虑到所有浏览器问题, 譬如 IE 作用域的问题,后续优化.

~~~

