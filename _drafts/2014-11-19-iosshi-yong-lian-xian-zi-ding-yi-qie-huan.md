---
layout: post
title: iOS 使用联线自定义切换
date: 2014-11-19 09:12:12.000000000 +08:00
permalink: /:title
---



通过添加`UIStoryboardSegure`的子类, 覆盖其`perform`方法, 来创建自定义切换.

~~~
- (void)perform {
    UIViewController *sourceVC = (UIViewController *)self.sourceViewController;
    UIViewController *destinationVC = (UIViewController *)self.destinationViewController;

    CGRect frame = sourceVC.view.frame;
    CGRect originalSourceRect = sourceVC.view.frame;
    frame.origin.y = frame.size.height;

    [UIView animateWithDuration:0.3
                     animations:^{
                         sourceVC.view.frame = frame;
                     } completion:^(BOOL finished) {
                         sourceVC.view.alpha = 0;
                         destinationVC.view.frame = frame;
                         destinationVC.view.alpha = 0;
                         [[sourceVC.view superview] addSubview:destinationVC.view];
                         [UIView animateWithDuration:0.3 animations:^{
                             destinationVC.view.frame = originalSourceRect;
                             destinationVC.view.alpha = 0;
                         } completion:^(BOOL finished) {
                             [destinationVC.view removeFromSuperview];
                             sourceVC.view.alpha = 1.0;
                             [sourceVC.navigationController pushViewController:destinationVC animated:YES];
                         }];
                     }];
}

~~~
