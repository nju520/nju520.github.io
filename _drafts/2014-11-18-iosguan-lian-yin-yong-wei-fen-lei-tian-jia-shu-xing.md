---
layout: post
title: iOS 关联引用为分类添加属性
date: 2014-11-18 08:00:00.000000000 +08:00
permalink: /:title
---



开发者可以使用关联引用为任何对象附着键值数据.

使用关联引用为分类添加属性, 首先, 我们新建一个`Person`类, `Person.h`的文件如下

~~~
//Person.h
#import <Foundation/Foundation.h>

@interface Person : NSObject

@property (copy, nonatomic) NSString *name;

@end

`Person`类的实现文件如下:

//Person.m
#import "Person.h"

@implementation Person

@end
~~~

现在, 我们在`Person`的分类中添加新的属性`emailAddress`, 现在头文件中使用`@property`声明这个属性.

~~~
//Person+EmailAddress.h	
#import "Person.h"

@interface Person (EmailAddress)

@property (copy, nonatomic) NSString *emailAddress;

@end
~~~

当我们只在分类的`.h`文件中加入属性的时候, 会产生如下的警告.

	Property 'emailAddress' requires method 'setEmailAddress:' to be defined - use @dynamic or provide a method implementation in this category.
	
这时, 我们使用`objc/Runtime`库中的动态方法为生成获取和设置属性的方法.

~~~
id objc_getAssociatedObject(id object, void *key)

void objc_setAssociatedObject(id object, void *key, id value, objc_AssociationPolicy policy)
~~~
	
`Person+emailAddress.m`方法的实现代码如下

~~~
#import "Person+EmailAddress.h"
#import <objc/runtime.h>

@implementation Person (EmailAddress)

static char emailAddressKey;

- (NSString *)emailAddress {
    return objc_getAssociatedObject(self, &emailAddressKey);
}

- (void)setEmailAddress:(NSString *)emailAddress {
    objc_setAssociatedObject(self, &emailAddressKey,
                             emailAddress, OBJC_ASSOCIATION_COPY);
}

@end
~~~

注意:

1. `emailAddressKey`的声明方法, 使用`static char`.
2. `emailAddressKey`这个名字并不重要, 它与我们实际使用的属性`emailAddress`的名字无关,这里加入后缀`Key`仅仅为了`code`的整洁
3. 我们使用`OBJC_ASSOCIATION_COPY`等参数作为语义管理,正确处理`copy`, `assign`, `retain`等语义.
