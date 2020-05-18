//
//  SYAppInfo.h
//  LiveBroadcasting
//
//  Created by ashawn on 2019/5/24.
//  Copyright © 2019 Gocy. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SYAppInfo : NSObject

@property (nonatomic, readonly, copy) NSString *appId;          // 从尚云官网申请的Appid

@property (nonatomic, readonly, copy) NSString *appName;        // 应用名称
@property (nonatomic, readonly, copy) NSString *appVersion;     // 版本号
@property (nonatomic, readonly, copy) NSString *appBuild;       // 构建号
@property (nonatomic, readonly, copy) NSString *appBundleId;    // appid
@property (nonatomic, readonly, copy) NSString *compAppId;      // 应用标识
@property (nonatomic, readonly, copy) NSString *feedbackAppId;  // 反馈 appid
@property (nonatomic, readonly, copy) NSString *scheme;         // app 的scheme
@property (nonatomic, readonly) BOOL enableSCLog;         // 是否托管尚云日志
@property (nonatomic, readonly, copy) NSString *appArea;         // 地区
@property (nonatomic, readonly, copy) NSString *gitVersion; // git version
@property (nonatomic, readonly, copy) NSString *gitBranch; // git branch

@property (nonatomic, readwrite, copy) NSString *ofSerialNumber;  // 美颜 SDK 序列号(请联系技术同学申请)

+ (instancetype)sharedInstance;

@end
