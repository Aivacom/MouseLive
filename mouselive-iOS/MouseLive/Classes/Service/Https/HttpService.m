//
//  HttpService.m
//  MouseLive
//
//  Created by 张建平 on 2020/3/3.
//  Copyright © 2020 sy. All rights reserved.
//

#import "HttpService.h"
#import "AFNetworking.h"
#import "SYAppInfo.h"
#import "TaskQueue.h"

#define SYConfigDictionary(method,url) [HttpService  requestInfoDictionaryWithMethod:method urlPath:url]
#define Method @"Method"
#define Url @"Url"
//测试网络是否正常
#define TestUrl  @"http://funapi.sunclouds.com"
/**请求路径*************************/
/**
 登录
 "Uid":  // 必须：(int64)：首次为0，服务器反回，记录本地，后基于这个登陆，10001～(100*10000*10000)的随机数
 "DevName": // 必须：(string)：设备名称：android：例如：XiaoMi8
 "DevUUID": // 必须：(string)：设备UUID：android：例如：9774d56d682e549c
 */
#define Login @"api/v1/login"
/**
 首页列表
 "Uid":0     // 必须：(int) or 121297
 "RType":    // 必须：(int):房间类型, 1:语音房间, 2:直播房间
 "Offset":0  // 必须：(int) 0,21,
 "Limit":20  // 必须：(int) 20,20,
 */
#define GetRoomList @"api/v1/getRoomList"
/**
 获取主播列表（PK使用）
 "Uid":0, or 121297
 "RType": 1,
 */
#define GetAnchorList @"api/v1/getAnchorList"
/**
 获取直播房间观众列表
 "Uid": 121297,
 "RoomId": "15000",
 */
#define GetRoomInfo   @"api/v1/getRoomInfo"
/**
 创建聊天室
 "Uid":      // 必须：(int64)：用户Id
 "RoomId":      // (int64)：房间ID
 "RChatId":  // (int64)：聊天室ID
 "RType": 1, // 必须 (int)房间类型
 "RLevel": 1,
 "RName": "room-new-new",
 "RNotice": "房间公告"
 "RCover": "http://image.biaobaiju.com/uploads/20180802/03/1533152912-BmPIzdDxuT.jpg"
 */
#define CreateRoom    @"api/v1/createRoom"
#define SetChatId     @"api/v1/setChatId"
#define GetChatId     @"api/v1/getChatId"
#define GetUserInfo   @"api/v1/getUserInfo"

/*
 {
     "RoomId": 66205018,      // 必须：(int64)房间ID
     "RType": 2,           // 必须：(int)  房间类型（视频直播，语音房，KTV等）
     "RMicEnable": false   // 必须：(bool)全局开麦：true，全局禁麦：false
 }
 */
#define SetRoomMic   @"api/v1/setRoomMic"

/*
{
    "SvrVer":"v0.1.0"
    "AppId": 18181818
    "ValidTime": 36000
    "Uid":20205018
}
*/
#define GetToken     @"api/v1/getToken"

/*
获取特效数据
*/
#define GetBeauty   @"api/v1/getBeauty"

/*

/fun/api/v1/setStatus
方法    post
Head    token：Basic authorization，生成方法请参考 HTTP Basic身份认证
请求
type TSetStatus struct {
    SvrVer     string `bson:"SvrVer"`     // 必须：服务器版本号0.1.0
    AppId      int32  `bson:"AppId"`      // 必须：该项目的AppId
    Uid        int64  `bson:"Uid"`        // 必须：用户ID
    UStatus    int32  `bson:"UStatus"`    // 必须：用户当前状态，参考：用户状态UserStatus
}
{
    "SvrVer": "v0.1.0",
    "AppId": 18251900,
    "Uid": 27905814,
    "UStatus": 11
}
 */
#define SetStatus   @"api/v1/setStatus"

static NSString * const kSYSvrVer = @"v0.1.0";
static NSString * const kHttpSuccessBlock = @"kHttpSuccessBlock";
static NSString * const kHttpFailedBlock = @"kHttpFailedBlock";
static NSString * const kHttpIsSuccessFlag = @"kHttpIsSuccessFlag";
static NSString * const kHttpResponse = @"kHttpResponse";
static NSString * const kHttpErrorCode = @"kHttpErrorCode";
static NSString * const kHttpErrorMessage = @"kHttpErrorMessage";
static NSString * const kHttpTaskId = @"kHttpTaskId";

#define USE_RecursiveLock 0

/****************************/

@interface HttpService() <TaskQueueDelegate>

@property (nonatomic, strong) NSMutableDictionary *requestDict;
@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, assign) int taskCount;  // task 数目递增
@property (nonatomic, strong) NSMutableDictionary *taskDictionary; // task 数组
@property (nonatomic, strong) TaskQueue *taskQueue; // 任务的同步线程

#if USE_RecursiveLock
@property (nonatomic, strong) NSRecursiveLock* lock; // 递归锁
#else
@property (nonatomic, strong) NSLock* lock; // 递归锁
#endif


@end

@implementation HttpService

static HttpService * _instance;
//单例模式
+ (HttpService *)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[HttpService alloc] init];
    });
    return _instance;
}

- (void)checkNetworking
{
 // 开始监测
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    // 网络状态改变的回调
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
                NSLog(@"蜂窝网络");
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"WIFI");
                break;
            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"没有网络");
                break;
            case AFNetworkReachabilityStatusUnknown:
                NSLog(@"未知");
                break;
            default:
                break;
        }
    }];
    
}

//网络类初始化
- (instancetype)init
{
    if (self = [super init]) {
//        开始网络检测
        [self checkNetworking];
        self.taskCount = 0;
        self.taskDictionary = [[NSMutableDictionary alloc] init];
        self.manager = [HttpService sy_createHTTPSessionManager];
        self.taskQueue = [[TaskQueue alloc] initWithName:@"HttpService"];
#if USE_RecursiveLock
        self.lock = [[NSRecursiveLock alloc] init];
#else
        self.lock = [[NSLock alloc] init];
#endif
        [self.taskQueue start];
    }
    return self;
}

- (void)dealloc
{
    [self.lock lock];
    [self.taskDictionary removeAllObjects];
    [self.taskQueue stop];
    [self.lock unlock];
}

+ (NSDictionary *)requestInfoDictionaryWithMethod:(NSString *)method urlPath:(NSString *)urlPath
{
    return [NSDictionary dictionaryWithObjectsAndKeys:method,Method,urlPath,Url, nil];
}

- (NSMutableDictionary *)requestDict
{
    if (!_requestDict) {
        _requestDict = [[NSMutableDictionary alloc]init];
        [_requestDict setValue:SYConfigDictionary(SYHttpMethodTypePOST, Login) forKey:SYHttpRequestKeyType_Login];
        [_requestDict setValue:SYConfigDictionary(SYHttpMethodTypePOST, GetRoomList) forKey:SYHttpRequestKeyType_RoomList];
        [_requestDict setValue:SYConfigDictionary(SYHttpMethodTypePOST, GetAnchorList) forKey:SYHttpRequestKeyType_AnchorList];
        [_requestDict setValue:SYConfigDictionary(SYHttpMethodTypePOST, GetRoomInfo) forKey:SYHttpRequestKeyType_RoomInfo];
        [_requestDict setValue:SYConfigDictionary(SYHttpMethodTypePOST, CreateRoom) forKey:SYHttpRequestKeyType_CreateRoom];
        [_requestDict setValue:SYConfigDictionary(SYHttpMethodTypePOST, SetChatId) forKey:SYHttpRequestKeyType_SetChatId];
        [_requestDict setValue:SYConfigDictionary(SYHttpMethodTypePOST, GetUserInfo) forKey:SYHttpRequestKeyType_GetUserInfo];
        [_requestDict setValue:SYConfigDictionary(SYHttpMethodTypePOST, GetChatId) forKey:SYHttpRequestKeyType_GetChatId];
        [_requestDict setValue:SYConfigDictionary(SYHttpMethodTypePOST, SetRoomMic) forKey:SYHttpRequestKeyType_SetRoomMic];
        [_requestDict setValue:SYConfigDictionary(SYHttpMethodTypePOST, GetToken) forKey:SYHttpRequestKeyType_GetToken];
        [_requestDict setValue:SYConfigDictionary(SYHttpMethodTypePOST, TestUrl) forKey:SYHttpRequestKeyType_Test];
        [_requestDict setValue:SYConfigDictionary(SYHttpMethodTypePOST, GetBeauty) forKey:SYHttpRequestKeyType_GetBeauty];
        [_requestDict setValue:SYConfigDictionary(SYHttpMethodTypePOST, SetStatus) forKey:SYHttpRequestKeyType_SetStatus];
    }
    return _requestDict;
}

#pragma mark -- 添加 / 移除
- (int)getNextTaskId
{
    int taskId = 0;
    [self.lock lock];
    {
        taskId = self.taskCount++;
    }
    [self.lock unlock];
    return taskId;
}

- (void)addTask:(int)taskId
{
    [self.lock lock];
    {
        NSNumber *taskQueueId = [self.taskQueue getNextTaskId];
        [self.taskDictionary setObject:taskQueueId forKey:@(taskId)];
    }
    [self.lock unlock];
}

- (void)readdTask:(int)taskId param:(NSDictionary *)param
{
    YYLogDebug(@"[MouseLive-Http] readdTask, entry, taskId:%d", taskId);
    [self.lock lock];
    {
        NSNumber *taskQueueId = [self.taskDictionary objectForKey:@(taskId)];
        if (taskQueueId) {
            YYLogDebug(@"[MouseLive-Http] readdTask, addTaskWithTaskId, taskQueueId:%@, taskId:%d", taskQueueId, taskId);
            [self.taskQueue addTaskWithTaskId:taskQueueId object:param delegate:self];
        }
    }
    [self.lock unlock];
    YYLogDebug(@"[MouseLive-Http] readdTask, exit");
}

- (void)removeTask:(NSArray<NSNumber *> *)taskArray
{
    YYLogDebug(@"[MouseLive-Http] removeTask, entry, taskArray:%@", taskArray);
    [self.lock lock];
    YYLogDebug(@"[MouseLive-Http] removeTask, self.taskDictionary:%@", self.taskDictionary);
    {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (NSNumber* taskId in taskArray) {
            NSNumber *t = [self.taskDictionary objectForKey:taskId];
            if (t) {
                [array addObject:t];
                [self.taskDictionary removeObjectForKey:taskId];
            }
        }
        [self.taskQueue cancelTask:[array copy]];
    }
    YYLogDebug(@"[MouseLive-Http] removeTask, after remove, self.taskDictionary:%@", self.taskDictionary);
    [self.lock unlock];
}

#pragma mark -- TaskQueueDelegate
- (void)sendToOuterWithTaskId:(int)taskId data:(NSDictionary *)data
{
    YYLogDebug(@"[MouseLive-Http] executeWithReq, entry, taskId:%d", taskId);
    BOOL isSuccess = [[data objectForKey:kHttpIsSuccessFlag] boolValue];
    if (isSuccess) {
        SYNetServiceSuccessBlock success = [data objectForKey:kHttpSuccessBlock];
        if (success) {
            id response = [data objectForKey:kHttpResponse];
            YYLogDebug(@"[MouseLive-Http] executeWithReq, success, taskId:%d", taskId);
            success(taskId, response);
        }
    }
    else {
        SYNetServiceFailBlock failure = [data objectForKey:kHttpFailedBlock];
        if (failure) {
            id response = [data objectForKey:kHttpResponse];
            NSString *errorCode = [data objectForKey:kHttpErrorCode];
            NSString *errorMessage = [data objectForKey:kHttpErrorMessage];
            YYLogDebug(@"[MouseLive-Http] executeWithReq, failure, taskId:%d", taskId);
            failure(taskId, response, errorCode, errorMessage);
        }
    }
    YYLogDebug(@"[MouseLive-Http] executeWithReq, exit");
}

- (void)executeWithReq:(NSNumber *)req object:(id)object
{
#if USE_RecursiveLock
    [self.lock lock];
    {
        __block NSNumber *taskId = nil;
        [self.taskDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([req intValue] == [obj intValue]) {
                *stop = YES;
                taskId = key;
            }
        }];
        
        if (taskId) {
            [self sendToOuterWithTaskId:[taskId intValue] data:(NSDictionary *)object];
            
            [self.taskDictionary removeObjectForKey:taskId];
        }
    }
    [self.lock unlock];
#else
    __block NSNumber *taskId = nil;
    [self.lock lock];
    {
        [self.taskDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([req intValue] == [obj intValue]) {
                *stop = YES;
                taskId = key;
            }
        }];
        
        if (!taskId) {
            [self.lock unlock];
            return;
        }
        
        [self.taskDictionary removeObjectForKey:taskId];
    }
    [self.lock unlock];
    [self sendToOuterWithTaskId:[taskId intValue] data:(NSDictionary *)object];
    YYLogDebug(@"[MouseLive-Http] executeWithReq, after sendToOuterWithTaskId, self.taskDictionary:%@", self.taskDictionary);
#endif
}

#pragma mark -- http 请求
+ (int)sy_httpRequestWithType:(SYHttpRequestKeyType)type params:(NSDictionary *)params success:(SYNetServiceSuccessBlock)success failure:(SYNetServiceFailBlock)failure
{
    if (success == nil) {
        YYLogDebug(@"[MouseLive-Http] sy_httpRequestWithType, success is nil!");
        return -1;
    }
    
    NSDictionary *requestDict = [[HttpService shareInstance].requestDict objectForKey:type];
    NSString *requestMethod = [requestDict objectForKey:Method];
    NSString *requestUrl = [requestDict objectForKey:Url];
    
    // 1. 先获取 task id
    // 2. 发送 http 请求
    // 3. 保存格式如下 block suc + block failed + bool isSuc + response id + errorCode NSString* + errorMsg NSString*
    // 4. 在 http 请求的 block 中，保存传入的 success + failed，并加入到执行队列中
    
    int taskId = [[HttpService shareInstance] getNextTaskId];
    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
    [[HttpService shareInstance] addTask:taskId];
    
    NSMutableDictionary *tmpParam = [NSMutableDictionary dictionaryWithDictionary:params];
    [tmpParam setValue:kSYSvrVer forKey:kSvrVer];
    [tmpParam setObject:@([SYAppInfo sharedInstance].appId.longLongValue) forKey:kAppId];
    
    __block BOOL isSuccess = YES;
    [response setObject:@(taskId) forKey:kHttpTaskId];
    [response setObject:success forKey:kHttpSuccessBlock];
    [response setObject:failure forKey:kHttpFailedBlock];
    [response setObject:@"" forKey:kHttpErrorCode];
    [response setObject:@"" forKey:kHttpErrorMessage];
    [response setObject:@(isSuccess) forKey:kHttpIsSuccessFlag];

    if ([requestMethod isEqualToString:SYHttpMethodTypeGET]) {
        [HttpService sy_httpGetWithPath:requestUrl parameters:[tmpParam copy] success:^(int t, id  _Nullable respObjc) {
            [response setObject:respObjc forKey:kHttpResponse];
            [[HttpService shareInstance] readdTask:taskId param:[response copy]];
        } failure:^(int t, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
            isSuccess = NO;
            [response setObject:@(isSuccess) forKey:kHttpIsSuccessFlag];
            if (respObjc) {
                [response setObject:respObjc forKey:kHttpResponse];
            }
            [response setObject:errorCode forKey:kHttpErrorCode];
            [response setObject:errorMsg forKey:kHttpErrorMessage];
            [[HttpService shareInstance] readdTask:taskId param:[response copy]];
        }];
    } else if ([requestMethod isEqualToString:SYHttpMethodTypePOST]) {
        [HttpService sy_httpPostWithPath:requestUrl parameters:[tmpParam copy] success:^(int t, id  _Nullable respObjc) {
            [response setObject:respObjc forKey:kHttpResponse];
            [[HttpService shareInstance] readdTask:taskId param:[response copy]];
        } failure:^(int t, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
            isSuccess = NO;
            [response setObject:@(isSuccess) forKey:kHttpIsSuccessFlag];
            if (respObjc) {
                [response setObject:respObjc forKey:kHttpResponse];
            }
            [response setObject:errorCode forKey:kHttpErrorCode];
            [response setObject:errorMsg forKey:kHttpErrorMessage];
            [[HttpService shareInstance] readdTask:taskId param:[response copy]];
        }];
    }
    
    YYLogDebug(@"[MouseLive-Http] sy_httpRequestWithType, exit, taskid:%d", taskId);
    return taskId;
}

#pragma mark -- 取消 http 请求
+ (void)sy_httpRequestCancelWithArray:(NSArray<NSNumber *> *)taskArray
{
    [[HttpService shareInstance] removeTask:taskArray];
}

#pragma mark - GET请求
+ (void)sy_httpGetWithPath:(NSString *)URLString
                parameters:(id)parameters
                   success:(SYNetServiceSuccessBlock)success
                   failure:(SYNetServiceFailBlock)failure
{
    NSString *urlString = URLString;
    if (![URLString isEqualToString:TestUrl]) {
        urlString = [kYYBaseUrl stringByAppendingString:URLString];
    }
    if (![urlString hasPrefix:@"http://"] && ![urlString hasPrefix:@"https://"]) {
        YYLogDebug(@"[MouseLive-Http] sy_httpGetWithPath 请检查请求URL：%@",urlString);
        return;
    }
    NSString *realURL = urlString;
    
    [[HttpService shareInstance].manager GET:realURL parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        responseObject = [self sy_customResponseSerializationData:responseObject];
        YYLogDebug(@"[MouseLive-Http] sy_httpGetWithPath \n\n***************  Start  ***************\nGET:\nURL:%@\nParams:%@\nResponse:%@\n***************   End   ***************\n\n.",realURL, parameters, responseObject);
        if (success && responseObject) {
            // task id 没有使用
            success(0, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        YYLogDebug(@"[MouseLive-Http] sy_httpGetWithPath  \n\n***************  Start  ***************\nGET:\nURL:%@\nParams:%@\nError:%@\n***************   End   ***************\n\n.",realURL, parameters, error);
        if (failure) {
            // task id 没有使用
            failure(0, nil, [NSString stringWithFormat:@"%ld", (long)error.code], [NSString stringWithFormat:@"%@", error]);
        }
    }];
    
}

#pragma mark - POST请求

+ (void)sy_httpPostWithPath:(NSString *)URLString
                 parameters:(id)parameters
                    success:(SYNetServiceSuccessBlock)success
                    failure:(SYNetServiceFailBlock)failure
{
      NSString *urlString = URLString;
       if (![URLString isEqualToString:TestUrl]) {
           urlString = [kYYBaseUrl stringByAppendingString:URLString];
       }
    
    if (!([urlString hasPrefix:@"http://"] && ![urlString hasPrefix:@"https://"])) {
        YYLogDebug(@"[MouseLive-Http] sy_httpPostWithPath 请检查请求URL：%@",URLString);
        return;
    }
    NSString *realURL = urlString;
    
    //HTTPS SSL的验证，在此处调用上面的代码，给这个证书验证；
    [[HttpService shareInstance].manager setSecurityPolicy:[HttpService customSecurityPolicy]];
    
    [[HttpService shareInstance].manager POST:realURL parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        responseObject = [self sy_customResponseSerializationData:responseObject];
        YYLogDebug(@"[MouseLive-Http] sy_httpPostWithPath \n\n***************  Start  ***************\nPOST:\nURL:%@\nParams:%@\nResponse:%@\n***************   End   ***************\n\n.",realURL, parameters, responseObject);
        if (success && responseObject) {
            // task id 没有使用
            success(0, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        YYLogDebug(@"[MouseLive-Http] sy_httpPostWithPath \n\n***************  Start  ***************\nPOST:\nURL:%@\nParams:%@\nError:%@\n***************   End   ***************\n\n.",realURL, parameters, error);
        if (failure) {
            // task id 没有使用
            failure(0, nil, [NSString stringWithFormat:@"%ld", (long)error.code], [NSString stringWithFormat:@"%@", error]);
        }
    }];
  
}

#pragma mark - 初始化 AFHTTPSessionManager
+ (AFHTTPSessionManager *)sy_createHTTPSessionManager
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.requestSerializer.timeoutInterval = HttpTimeoutInterval;
    manager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"image/jpeg",@"text/plain", nil];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    return manager;
}

#pragma mark - 初始化一个AFSecurityPolicy
+ (AFSecurityPolicy *)customSecurityPolicy
{
    //先导入证书，找到证书的路径
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"client" ofType:@"cer"];
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    
    //AFSSLPinningModeCertificate 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    
    //allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    //如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    
    //validatesDomainName 是否需要验证域名，默认为YES；
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    securityPolicy.validatesDomainName = NO;
    NSSet *set = [[NSSet alloc] initWithObjects:certData, nil];
    securityPolicy.pinnedCertificates = set;
    
    return securityPolicy;
}

+ (id)sy_customResponseSerializationData:(id)responseObject
{
    if (responseObject && [responseObject isKindOfClass:[NSData class]]) {
        responseObject = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];;
    }
    return responseObject;
}

- (void)cancelRequest
{
    //    [[HttpService shareInstance].manager.operationQueue.currentQueue ]
    //    if ([[HttpService shareInstance].manager.tasks count] > 0) {
    //        NSLog(@"返回时取消网络请求");
    
    [[HttpService shareInstance].manager.operationQueue  cancelAllOperations];
//    [[HttpService shareInstance].manager.tasks makeObjectsPerformSelector:@selector(cancel)];
    //    }
}

+ (NSDictionary *)sy_SyncHttpRequestWithType:(SYHttpRequestKeyType)type params:(NSDictionary *)params
{
    NSDictionary *requestDict = [[HttpService shareInstance].requestDict objectForKey:type];
    NSString *requestMethod = [requestDict objectForKey:Method];
    NSString *requestUrl = [requestDict objectForKey:Url];
    
    NSMutableDictionary *tmpParam = [NSMutableDictionary dictionaryWithDictionary:params];
    [tmpParam setValue:kSYSvrVer forKey:kSvrVer];
    [tmpParam setObject:@([SYAppInfo sharedInstance].appId.longLongValue) forKey:kAppId];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    __block NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:ksuccessCode forKey:kCode];
    [dict setValue:@"" forKey:kMsg];
    
    // 此函数是同步的，不使用 task id
    if ([requestMethod isEqualToString:SYHttpMethodTypeGET]) {
        [HttpService sy_httpGetWithPath:requestUrl parameters:[tmpParam copy] success:^(int t, id  _Nullable respObjc) {
            [dict setObject:respObjc forKey:kResponse];
            dispatch_semaphore_signal(semaphore);
        } failure:^(int t, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
            [dict setObject:respObjc forKey:kResponse];
            [dict setObject:errorCode forKey:kCode];
            [dict setValue:errorMsg forKey:kMsg];
            dispatch_semaphore_signal(semaphore);
        }];
    } else if ([requestMethod isEqualToString:SYHttpMethodTypePOST]) {
        [HttpService sy_httpPostWithPath:requestUrl parameters:[tmpParam copy] success:^(int t, id  _Nullable respObjc) {
            [dict setObject:respObjc forKey:kResponse];
            dispatch_semaphore_signal(semaphore);
        } failure:^(int t, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
            [dict setObject:respObjc forKey:kResponse];
            [dict setObject:errorCode forKey:kCode];
            [dict setValue:errorMsg forKey:kMsg];
            dispatch_semaphore_signal(semaphore);
        }];
    }
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return [dict copy];
}

@end
