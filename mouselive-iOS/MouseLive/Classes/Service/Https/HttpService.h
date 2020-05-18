//
//  HttpService.h
//  MouseLive
//
//  Created by 张建平 on 2020/3/3.
//  Copyright © 2020 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#define HttpTimeoutInterval 30

// TODO: zhangjianping
//iOS http 现在出现问题获取时间过长的话，可能出现 block view 可能已经被释放的问题，导致直接崩溃。
//解决方案，在 http 基础上使用单实例，注册的方式，做数据同步，操作在单线程中进行数据同步

/**网络请求类型*/
typedef NSString *SYHttpMethodType NS_STRING_ENUM;
static SYHttpMethodType const _Nonnull SYHttpMethodTypeGET = @"GET";
static SYHttpMethodType const _Nonnull  SYHttpMethodTypePOST = @"POST";
static SYHttpMethodType const _Nonnull  SYHttpMethodTypePUT = @"PUT";
static SYHttpMethodType const _Nonnull  SYHttpMethodTypePATCH = @"PATCH";
static SYHttpMethodType const _Nonnull  SYHttpMethodTypeDELETE = @"DELETE";


/**请求url 对应的key值*/

typedef NSString *SYHttpRequestKeyType NS_STRING_ENUM;
static SYHttpRequestKeyType const _Nonnull SYHttpRequestKeyType_Test = @"SYHttpRequestKeyType_Test";
static SYHttpRequestKeyType const _Nonnull SYHttpRequestKeyType_Login = @"SYHttpRequestKeyType_Login";
static SYHttpRequestKeyType const _Nonnull SYHttpRequestKeyType_RoomList = @"SYHttpRequestKeyType_RoomList";
static SYHttpRequestKeyType const _Nonnull SYHttpRequestKeyType_AnchorList = @"SYHttpRequestKeyType_AnchorList";
static SYHttpRequestKeyType const _Nonnull SYHttpRequestKeyType_RoomInfo = @"SYHttpRequestKeyType_RoomInfo";
static SYHttpRequestKeyType const _Nonnull SYHttpRequestKeyType_CreateRoom = @"SYHttpRequestKeyType_CreateRoom";
static SYHttpRequestKeyType const _Nonnull SYHttpRequestKeyType_GetUserInfo = @"SYHttpRequestKeyType_GetUserInfo";
static SYHttpRequestKeyType const _Nonnull SYHttpRequestKeyType_SetChatId = @"SYHttpRequestKeyType_SetChatId";
static SYHttpRequestKeyType const _Nonnull SYHttpRequestKeyType_GetChatId = @"SYHttpRequestKeyType_GetChatId";
static SYHttpRequestKeyType const _Nonnull SYHttpRequestKeyType_SetRoomMic = @"SYHttpRequestKeyType_SetRoomMic";
static SYHttpRequestKeyType const _Nonnull SYHttpRequestKeyType_GetToken = @"SYHttpRequestKeyType_GetToken";
static SYHttpRequestKeyType const _Nonnull SYHttpRequestKeyType_GetBeauty = @"SYHttpRequestKeyType_GetBeauty";
static SYHttpRequestKeyType const _Nonnull SYHttpRequestKeyType_SetStatus = @"SYHttpRequestKeyType_SetStatus";

/** 成功返回值*/
typedef void(^SYNetServiceSuccessBlock) (int taskId, id _Nullable respObjc);

/**失败返回值*/
typedef void (^SYNetServiceFailBlock)(int taskId, id _Nullable respObjc,NSString * _Nullable errorCode,NSString * _Nullable errorMsg);

NS_ASSUME_NONNULL_BEGIN

@interface HttpService : NSObject

+ (HttpService *)shareInstance;

/// 异步获取 http request
/// @param type SYHttpRequestKeyType
/// @param params 参数
/// @param success 成功 block --, 在主线程返回
/// @param failure 失败 blockk --, 在主线程返回
/// @return 返回 taskid
+ (int)sy_httpRequestWithType:(SYHttpRequestKeyType)type params:(NSDictionary *)params success:(SYNetServiceSuccessBlock)success failure:(SYNetServiceFailBlock)failure;

/// 取消 http request 任务
/// @param taskArray 要取消的任务 id 队列
+ (void)sy_httpRequestCancelWithArray:(NSArray<NSNumber*>*)taskArray;

/// 同步获取 http request
/// @param type SYHttpRequestKeyType
/// @param params 参数
+ (NSDictionary*)sy_SyncHttpRequestWithType:(SYHttpRequestKeyType)type params:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
