---
layout: post
title: iOS Combine TabbarController and NavigationController<Bug02>
date: 2014-11-29 04:36:59.000000000 +08:00
permalink: /ios-combine-tabbarcontroller-and-navigationcontrollerbug02
---


##TabbarController and NavigationController

`UINavigationController` and `UITabBarController` are two kinds of container classes in Cocoa. The two controllers are tremendous important in iOS development, we deal with them every day. Even if you are not a developer, just an iOS device user. Almost every thing you see in an iOS App have some relationship with them.

Why are they so important, because of they are container classes, they handle many view controllers in an App. And `MVC` is the basic design patterns in `Cocoa` and `Cocoa touch`.

Personally, I prefer to initialize everything programmingly, not in a storyboard or a nib file. Because I think it is easy to deal with. Sometimes using storyboard or a nib is too simple, but they may cause undetectable crash.


##Use them Programatically

The first thing we start an App is set up the project, and I am used to delete the `Main.storyboard` file first. And add some code to configure the `AppDelegate`.

The common code you add may be this:

~~~
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] init];
    [self.window makeKeyAndVisible];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    return YES;
}
~~~	

Every project without a `storyboard` needs to initialize like this. How should we do then?

What should we do, if we want to set up with a `navigationController`:

~~~
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
       UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    return YES;
}
~~~

It's quiet simple and easy to understand, what about `tabBarController`:

~~~
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UIViewController *firstViewController = [[UIViewController alloc] init];
    UIViewController *secondViewController = [[UIViewController alloc] init];
    UIViewController *thirdViewController = [[UIViewController alloc] init];
    
       UITabBarController *tabBarController = [[UITabBarController alloc] init];        
       tabBarController.viewControllers = @[firstViewController, secondViewController, thirdViewController];
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    return YES;
}
~~~

Just set `tabBarController`'s property `viewControllers` to proper `viewController`.

##Why combine TabBarController and NavigationController

If you want to switch to another view from one of `tabBarController`, you can not do it with a single `tabBarController`. Because you need a stack to manage all of your controllers. If you not have one, the system do not know which view controller will display after this view pop from the window.

So we need to combine them, in my first project, I do this in this way:


~~~
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UIViewController *firstViewController = [[UIViewController alloc] init];
    UIViewController *secondViewController = [[UIViewController alloc] init];
    UIViewController *thirdViewController = [[UIViewController alloc] init];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];        
    tabBarController.viewControllers = @[firstViewController, secondViewController, thirdViewController];
    UINavigationController *navigationController = [[UINavigationControlle alloc] initWithRootViewController:tabBarController];
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    return YES;
}
~~~

When I did this, I do not consider about other thing, because the apple developer document use this approach: 
 
~~~
UIViewController *firstViewController = [[UIViewController alloc] init];
UIViewController *secondViewController = [[UIViewController alloc] init];
UIViewController *thirdViewController = [[UIViewController alloc] init];
UIViewController *rootViewController = [[UIViewController alloc] init];
UINavigationController* navController = [[UINavigationController alloc]                         initWithRootViewController:rootViewController];
 
NSArray* controllers = [NSArray arrayWithObjects:firstViewController, secondViewController, thirdViewController, navController, nil];

UITabBarController *tabBarController = [[UITabBarController alloc] init];
tabBarController.viewControllers = controllers;

self.window.rootViewController = tabBarController;
~~~

I just think this is a silly way. if I imitate this, **Do I need to initialize five navigation controllers each with a view controller?**

The answer is right. I need to do so. Why? After I imitate this approach, my previous approach has some side effects.

1. Sometimes you reference `navigationController` with `self`, you may get a null. Because the five viewController are bot pushed on the stack.
2. If you change `navigationBar` in one tab, as you swich to another, all the `navigationBar` are changed. Because they are just one `navigationController` and it just have only one `navigatonBar`.
3. If you `pushViewController` from one of `tabBarController`'s `viewControllers`, tab bar will disapper, you will not see it, because `tabBarController` is not the `rootViewController`, it just in the stack with its `tabBar`.

So the verbose but correct approach is this:

~~~
UIViewController *firstViewController = [[UIViewController alloc] init];
UIViewController *secondViewController = [[UIViewController alloc] init];
UIViewController *thirdViewController = [[UIViewController alloc] init];
UINavigationController *firstNavigationController = [[UINavigationController alloc]
                     initWithRootViewController:rootViewController];
UINavigationController *secondNavigationController = [[UINavigationController alloc]
                     initWithRootViewController:rootViewController];
UINavigationController *thirdNavigationController = [[UINavigationController alloc]
                     initWithRootViewController:rootViewController];

NSArray* controllers = [NSArray arrayWithObjects:firstNavigationController, secondNavigationController, thirdNavigationController, nil];

UITabBarController *tabBarController = [[UITabBarController alloc] init];
tabBarController.viewControllers = controllers;

self.window.rootViewController = tabBarController;
~~~

PS: `navigationBar` is damn difficult to use. Hope this help.








