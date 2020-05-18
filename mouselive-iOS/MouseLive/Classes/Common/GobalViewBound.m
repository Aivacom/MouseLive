//
//  DeviceInfo.m
//  MouseLive
//
//  Created by 张建平 on 2020/2/28.
//  Copyright © 2020 sy. All rights reserved.
//

#import "GobalViewBound.h"
#import <UIKit/UIKit.h>

@interface GobalViewBound()

@property (nonatomic, readwrite, assign) int navBarHeight;
@property (nonatomic, readwrite, assign) int statusBarHeight;
@property (nonatomic, readwrite, assign) int tarBarHeight;
@property (nonatomic, readwrite, assign) int navContentBarHeight;
@property (nonatomic, readwrite, assign) int screenWidth;
@property (nonatomic, readwrite, assign) int screenHeight;
@property (nonatomic, readwrite, assign) int dataViewTitleHeight;
@property (nonatomic, readwrite, assign) int bannerCellHeight;

@end

@implementation GobalViewBound

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.navBarHeight = k_Height_NavBar;
        self.statusBarHeight = k_Height_StatusBar;
        self.tarBarHeight = k_Height_TabBar;
        self.navContentBarHeight = k_Height_NavContentBar;
        self.screenWidth = [UIScreen mainScreen].bounds.size.width;
        self.screenHeight = [UIScreen mainScreen].bounds.size.height;
        
#define TitleHeight(x) MIN(MAX(x, 40), 50)
        
        self.dataViewTitleHeight = TitleHeight(51);
        self.bannerCellHeight = 160;
    }
    return self;
}


@end
