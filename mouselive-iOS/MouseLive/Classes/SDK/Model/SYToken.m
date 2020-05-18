//
//  SYToken.m
//  MouseLive
//
//  Created by 张建平 on 2020/4/23.
//  Copyright © 2020 sy. All rights reserved.
//

#import "SYToken.h"

@interface SYToken()

@property (nonatomic, assign, readwrite) int validTime;  // token 过期时间：单位秒：比如：3600：一小时
@property (nonatomic, assign) long long updateTime; // token 更新的时间

@end

@implementation SYToken

@synthesize thToken = _thToken;  // 使用 set / get 同时重写方法

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
    if (self = [super init]) {
        self.validTime = 24 * 3600; // 1 小时
        self.thToken = kTokenError;
    }
    return self;
}

- (long long)getNowForMillisecond
{
    // *1000 是精确到毫秒，不乘就是精确到秒
    return (long long)[[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
}

- (void)updateTokenWithComplete:(TokenComplete)complete
{
    YYLogDebug(@"[MouseLive-Token] updateToken entry");
    NSDictionary *params = @{
        kUid:@(self.localUid.longLongValue),
        kValidTime:@(self.validTime),
    };
    
    [HttpService sy_httpRequestWithType:SYHttpRequestKeyType_GetToken params:params success:^(int taskId, id  _Nullable respObjc) {
        NSNumber *code = [respObjc objectForKey:kCode];
        if (![code isEqualToNumber:[NSNumber numberWithInt:[ksuccessCode intValue]]]) {
            YYLogError(@"[MouseLive-Token] 1 updateToken GetError!!!");
            if (complete) {
                complete(self.thToken, [NSError errorWithDomain:@"Get token from http error" code:-1 userInfo:nil]);
            }
        }
        else {
            self.thToken = [(NSDictionary *)[respObjc objectForKey:kData] objectForKey:kToken];
            YYLogDebug(@"[MouseLive-Token] updateToken token:%@", self.thToken);
            if (complete) {
                complete(self.thToken, nil);
            }
        }
    } failure:^(int taskId, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
        YYLogDebug(@"[MouseLive-Token] updateToken, errorCode:%@, errorMsg:%@", errorCode, errorMsg);
        if (complete) {
            complete(self.thToken, [NSError errorWithDomain:errorMsg code:-1 userInfo:nil]);
        }
    }];
    YYLogDebug(@"[MouseLive-Token] updateToken exit");
}

@end
