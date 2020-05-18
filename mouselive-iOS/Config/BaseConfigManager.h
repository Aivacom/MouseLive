//
//  BaseConfigManager.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/13.
//  Copyright © 2020 sy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseConfigManager : NSObject
@property(nonatomic,assign)BOOL bgLogEnable;//是否允许打印log,默认NO

//1.初始化单例
+ (instancetype)sy_sharedInstance;

+ (void)sy_logWithFormat:(NSString *)format, ...;
@end

NS_ASSUME_NONNULL_END
