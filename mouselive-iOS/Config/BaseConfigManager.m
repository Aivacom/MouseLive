//
//  BaseConfigManager.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/13.
//  Copyright © 2020 sy. All rights reserved.
//

#import "BaseConfigManager.h"

@implementation BaseConfigManager
+ (instancetype)sy_sharedInstance
{
    static BaseConfigManager *global = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        global = [[self alloc] init];
        global.bgLogEnable = NO;
        
    });
    return global;
}

+ (void)sy_logWithFormat:(NSString *)format, ...
{
#ifdef DEBUG
    BaseConfigManager *global = [BaseConfigManager sy_sharedInstance];
    if (global.bgLogEnable && format) {
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        NSLog(@"%@",message);
    }
#endif
}

@end
