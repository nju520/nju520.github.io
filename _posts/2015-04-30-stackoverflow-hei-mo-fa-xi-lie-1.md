---
layout: post
toc: true
title: StackOverflow 黑魔法系列 <1>
date: 2015-04-30 21:52:25.000000000 +08:00
permalink: /:title
tags: iOS
---


最近看到了很多关于 iOS 开发的黑魔法, 发现最终的链接都是来自与 [stackoverflow](http://stackoverflow.com/), 我感觉需要在 stackoverflow 上这个社区逛一逛, 找一些比较~~屌~~神奇的黑魔法来分享一下, 也能够~~多两篇水文~~提高一下自己的水平, 当然我会在每一条"咒语"的后面加上原文的链接.

## 原子(atomic)和非原子(nonatomic)的区别是什么?

~~~objectivec
@property(nonatomic, retain) UITextField *userName;
@property(atomic, retain) UITextField *userName;
@property(retain) UITextField *userName;
~~~

这三行代码中的后两行是相同的, 因为 `atomic` 是默认的行为. 在现在的 LLVM 的版本中, 使用 `atomic` 和 `nonatomic` 声明的属性在自动生成 `getter/setter` 方法时有所不同.

如果你是用了 `atomic`, 那么自动合成的 `getter/setter` 方法会确保值会正确从 `getter` 中返回, 或者能够正确的被 `setter` 所设置, 也就是加锁. 同一时间只能访问(包含 `getter/setter`)这个属性一次.

在 `nonatomic` 中, 就不会保证同一时间只有一个操作能够访问该属性了, 这也会加快属性的访问速度, 使得 `nonatomic` 比 `atomic` 快的多.

然而 `atomic` 并不能保证线程的安全, 如果在 `线程 A` 中调用 getter, 与此同时在 `线程 B` 和 `线程 C` 中调用 `setter`, 那么 `线程 A` 中可能获得 B/C 中某一个属性的值. 但是我们并不知道结果. 所以, `atomic` 虽然能在一定程度上确保 `getter/setter` 方法的正确调用但是并不能 100% 的确保线程的安全.

而确保线程安全和数据完整, 也是我们在使用多线程编程中的主要挑战, 它可以通过别的方法来解决.

链接: [What's the difference between the atomic and nonatomic attributes?](http://stackoverflow.com/questions/588866/whats-the-difference-between-the-atomic-and-nonatomic-attributes)

----

## 如何使用 iPhone SDK 检查当前网络的状态?

检查当前网络的状态还是有多种方法的.

提问的人首先提了一个非常取巧也非常聪明的办法, 它直接使用了 `stringWithContentsOfURL:` 这个方法来访问 Google, 然后查看是否有 response 来判断网络的状态.

~~~objectivec
- (BOOL) connectedToInternet {
  NSString *URLString = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://www.google.com"]];
  return ( URLString != NULL ) ? YES : NO;
}
~~~

但是这段代码在天朝还是行不通啊, 我们并没有 Google 这个网站, 当然可以把 Google 改成随便什么别的网站来解决这个问题, 但是我们还是需要一种更加"靠谱"的解决方案.

第二种方法是使用第三方开源框架 [Reachability](https://github.com/tonymillion/Reachability)

在实现文件的中添加如下代码, 然后填写你想要测试连通性的 host:

~~~objectivec
// Checks if we have an internet connection or not
    - (void)testInternetConnection {   
    // Allocate a reachability object
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.google.com"];

    // Set the blocks
    reach.reachableBlock = ^(Reachability*reach) {
    // keep in mind this is called on a background thread
    // and if you are updating the UI it needs to happen
    // on the main thread, like this:

        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"REACHABLE!");
        });
    };

    reach.unreachableBlock = ^(Reachability*reach) {
        NSLog(@"UNREACHABLE!");
    };

    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
}
~~~

链接: [How to check for an active Internet Connection on iPhone SDK?](http://stackoverflow.com/questions/1083701/how-to-check-for-an-active-internet-connection-on-iphone-sdk)

----

## 在 Objective-C 的字符串中如何查询是否含有子字符串?

在 iOS8 以前, 我们需要使用 `rangeOfString:` 方法来判断是否含有子字符串:

~~~objectivec
NSString *string = @"hello bla bla";
if ([string rangeOfString:@"bla"].location == NSNotFound) {
   NSLog(@"string does not contain bla");
} else {
   NSLog(@"string contains bla!");
}
~~~

其中最关键的地方是 `rangeOfString:` 会返回一个 `NSRange` 的结构体, `{NSNotFound, 0}`, 所以我们要获取结构体中的 `location` 来判断是否存在该字符串, 详见[文档](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/index.html#//apple_ref/occ/instm/NSString/rangeOfString:).

而在 iOS8 之后, 苹果~~大发慈悲地~~为我们提供了更加友善的解决办法, 也就是 `containString:` 方法直接解决了这个问题.

~~~objectivec
NSString *string = @"hello bla blah";
if ([string containsString:@"bla"]) {
   NSLog(@"string contains bla!");
} else {
   NSLog(@"string does not contain bla");
}
~~~

链接: [How do I check if a string contains another string in Objective-C?](http://stackoverflow.com/questions/2753956/how-do-i-check-if-a-string-contains-another-string-in-objective-c)

## 当键盘出现时, 如何使 `UITextField` 向上移动?

在 iOS 开发中, 我们经常会遇到这样的问题, 键盘的出现会遮挡已有的文本框使得用户无法看到自己的输入. 这其实是一个比较麻烦的问题, 并不是一两行代码能够解决的. 在这个问题中, 需要注意两点:

* 如果你所要显示的内容并没有全部在 iPhone 屏幕中, 那么就需要添加一个 `UIScrollView`, 也就是说, 如果仅仅为了使得 `UITextField` 上移, 添加 `UIScrollView` 是得不偿失并且浪费的.
* 解决这个问题最标准的办法就是, 在键盘出现的时候上移 `UITextField`, 在键盘消失的时候下移 `UITextField`.

在这里我们要使用通知来解决这个问题, 首先我们要在 `viewWillAppear:` 和 `viewWillDisapear:` 中分别注册和移除通知.

~~~objectivec
- (void)viewWillAppear:(BOOL)animated {
   [super viewWillAppear:animated];
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:UIKeyboardWillShowNotification object:nil];
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
   [super viewWillDisappear:animated];
   [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
   [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}
~~~

然后我们需要实现一个 `UITextField` 的代理方法 `textFieldDidBeginEditing:` 当 `UITextField` 开始编辑键盘准备响应的时候, 让 `UITextField` 向上弹出.

~~~objectivec
- (void)textFieldDidBeginEditing:(UITextField *)sender {
   //move the main view, so that the keyboard does not hide it.
   if  (self.view.frame.origin.y >= 0) {
       [self setViewMovedUp:YES];
   }
}
~~~

接下来实现当键盘弹出或隐藏发出通知所响应的两个方法, `keyboardWillShow` 和 `keyboardWillHide`.

~~~objectivec
- (void)keyboardWillShow {
   // Animate the current view out of the way
   if (self.view.frame.origin.y >= 0) {
       [self setViewMovedUp:YES];
   } else if (self.view.frame.origin.y < 0) {
       [self setViewMovedUp:NO];
   }
}

- (void)keyboardWillHide {
   if (self.view.frame.origin.y >= 0) {
       [self setViewMovedUp:YES];
   } else if (self.view.frame.origin.y < 0) {
       [self setViewMovedUp:NO];
   }
}
~~~

在最后, 就来实现使 `UITextField` 移动的方法 `setViewMovedUp:` 了.

~~~objectivec
#define kOFFSET_FOR_KEYBOARD 80.0

- (void)setViewMovedUp:(BOOL)movedUp {
   [UIView beginAnimations:nil context:NULL];
   [UIView setAnimationDuration:0.3]; // if you want to slide up the view

   CGRect rect = self.view.frame;
   if (movedUp) {
       // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
       // 2. increase the size of the view so that the area behind the keyboard is covered up.
       rect.origin.y -= kOFFSET_FOR_KEYBOARD;
       rect.size.height += kOFFSET_FOR_KEYBOARD;
   } else {
       // revert back to the normal state.
       rect.origin.y += kOFFSET_FOR_KEYBOARD;
       rect.size.height -= kOFFSET_FOR_KEYBOARD;
   }
   self.view.frame = rect;

   [UIView commitAnimations];
}
~~~

这种重要的问题在苹果的[官方文档](https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html#//apple_ref/doc/uid/TP40009542-CH5-SW7)中也对应的实现方法.

链接: [How to make a UITextField move up when keyboard is present](http://stackoverflow.com/questions/1126726/how-to-make-a-uitextfield-move-up-when-keyboard-is-present)

----

## 如何在 `UITableView` 中禁止选择的高亮?

~~~objectivec
tableView.allowsSelection = NO;
~~~

链接: [How can I disable the UITableView selection highlighting?](http://stackoverflow.com/questions/190908/how-can-i-disable-the-uitableview-selection-highlighting)
