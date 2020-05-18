//
//  SYCrashreportSetup.m
//  SCloudAudio
//
//  Created by iPhuan on 2019/12/13.
//  Copyright © 2019 SY. All rights reserved.
//

#import "SYCrashreportSetup.h"
#import <UIKit/UIKit.h>
#import "crashreport.h"
#import "SYUtils.h"

static NSString * const kSYCrashreportAppId = @"MouseLive-ios"; // 对接崩溃系统AppID


@interface SYCrashreportSetup ()

@end

@implementation SYCrashreportSetup

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self p_setupCrashreport];
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [[CrashReport sharedObject] unInit];
    }];
}


+ (void)p_setupCrashreport {
    [[CrashReport sharedObject] initWithAppid:kSYCrashreportAppId appVersion:[SYUtils appVersion] market:@"dev"];

    [[CrashReport sharedObject] setApplicationStateGetterBlock:^NSInteger {
        return [UIApplication sharedApplication].applicationState;
    }];
    
    // ANR检测 TODO: app set custom ANR threshold
    [[CrashReport sharedObject] enableANRDetection:5];
    
}

@end
