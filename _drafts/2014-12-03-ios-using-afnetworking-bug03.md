---
layout: post
title: iOS Using AFNetworking <Bug03>
date: 2014-12-03 08:56:49.000000000 +08:00
permalink: /:title
---


During these days development, when I connect our iOS App to Python `back-end` using `AFNetworking`, I met an error. It is my first time to use the `AFNetworking` framework, I am used to use `MKNetworking` instead, but with some reasons. I planned to use `AFNetworking` instead. And then, as you see, I met a few problems. 
	
	Error: Error Domain=NSCocoaErrorDomain Code=3840 "The operation couldn’t be completed. (Cocoa error 3840.)" (JSON text did not start with array or object and option to allow fragments not set.) UserInfo=0x17697430 {NSDebugDescription=JSON text did not start with array or object and option to allow fragments not set., NSUnderlyingError=0x176f9ec0 
	
	
At first, I do not know, what it's mean, but I ask my partner, he tells me, in order to beautify the `JSON` he use some method, to make them like this, I do not know exactly what he did, but `JSON` looks like this.

~~~
{
  "message": "success", 
  "posts": [], 
  "status": 0
}
~~~

It is not like the `JSON` I used to deal with before, I think they should be this shape:

~~~
{ "message": "success", "posts": [],  "status": 0 }
~~~
	
But it's not, at that time, he explains that if I could not deal with this, he could modify them back. For he can not change this immediately, so I tried to fix this problem.

And then, I find this problem is cuz but my mistakes, I add one more `/` in the `URL`. After I fix this. I confidently run my App, and there is also an different error:

	NSUnderlyingError=0x156a3e80 "Request failed: unacceptable content-type: text/html"
	
I search this on google and stackoverflow, someone says add a `acceptableContentType` to `responseSerialzer`, someone says to `initialize` a `responseSerailize` and change it option to `AllowFragment`. When I tries them, I find the first solution is right.

I add a `acceptableContentType` to the `responseSerializer`, and I fix this. But I think this quiet messy, everytime I use this framework, I had to add an `acceptableContentType`. I am too naive to realize this as a mistake. So I open an `issue` on `AFNetworking` and add this `type` `text/html` to the source code.

~~~
   self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", nil];
~~~

And soon, the author of `AFNetworking` reply me as follows:

	The solution is already built into the design of the framework. Patching it is unnecessary.
	
A little disappointed, but I add this type to my source code, in order to not add this everytime initialize the `manager`.

Hope this helps. 
