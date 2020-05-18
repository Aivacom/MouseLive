//
//  BaseViewController.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/10.
//  Copyright © 2020 sy. All rights reserved.
//

#import "BaseViewController.h"
#import "MainViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.navigationController.interactivePopGestureRecognizer.delegate = (id)self;
        //这个可以放在需要侦听的页面
 }



//- (void)backToRootViewController
//{
//    WeakSelf
//       //刷新页面
//    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyRefreshNew object:@"1"];
//    UITabBarController *vc = [MainViewController instance];
//    if (vc.presentedViewController) {
//        [((UINavigationController *)vc.presentedViewController) popViewControllerAnimated:NO];
//        [vc.presentedViewController dismissViewControllerAnimated:NO completion:nil];
//    }else{
//        [weakSelf.navigationController popViewControllerAnimated:YES];
//    }
//}


@end
