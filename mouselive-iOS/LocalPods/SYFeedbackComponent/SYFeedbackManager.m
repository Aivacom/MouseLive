//
//  SYFeedbackManager.m
//  SYFeedbackComponent
//
//  Created by iPhuan on 2019/8/20.
//  Copyright © 2019 SY. All rights reserved.
//


#import "SYFeedbackManager.h"

static NSString * const kSYFeedbackRequestUrl = @"https://isoda-inforeceiver.yy.com/userFeedback"; // 反馈接口URL


@interface SYFeedbackManager ()

@end

@implementation SYFeedbackManager

+ (instancetype)sharedManager {
    static SYFeedbackManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupDefaultValue];
    }
    return self;
}

- (void)setupDefaultValue {
    self.requestUrl = kSYFeedbackRequestUrl;
    self.marketChannel = @"Demo";
    self.submitButtonNormalHexColor = @"#6485F9";
    self.submitButtonhighlightedHexColor = @"#3A61ED";
}



@end
