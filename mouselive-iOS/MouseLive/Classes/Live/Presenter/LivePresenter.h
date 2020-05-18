//
//  LivePresenter.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/17.
//  Copyright © 2020 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveProtocol.h"
#import "LiveDefaultConfig.h"
#import "RoomOwnerModel.h"
#import "LiveUserInfoList.h"

@protocol LivePresenterDelegate <NSObject>

- (void)audienceJoinChatRoom:(id)data;
//公聊区 主播创建聊天室
- (void)successChatRoom:(id)data withType:(LiveType)type;

- (void)liveViewRoomInfo:(LiveRoomInfoModel*)roomInfo UserListDataSource:(NSArray <LiveUserModel *>*)data;
- (void)liveViewAnchorListDataSource:(NSArray <LiveAnchorModel *>*)data;

- (void)liveUserData:(LiveUserModel *)user;
//创建房间失败
- (void)createRoomError:(NSString *)errorMessage;

- (void)createRoomSucess:(id)data;

//更新开播config信息
- (void)resetLiveConfig:(LiveDefaultConfig * _Nullable)config;

//刷新页面
- (void)refreshLiveStatusWithLinkUid:(NSString * _Nullable)uid;

//请求出错
- (void)requestError:(NSString *_Nullable)errorMessage;
//主播已经停播
- (void)liveStatusIsStop;

@end


NS_ASSUME_NONNULL_BEGIN

@interface LivePresenter : NSObject

@property (nonatomic, weak) id<LivePresenterDelegate> delegate;

@property (nonatomic, readonly, assign) BOOL isRunningMirc; // 正在连麦

@property (nonatomic, readonly, assign) BOOL isOwner; // 房主

@property (nonatomic, readonly, assign) BOOL isWheat; // 连麦者

@property (nonatomic, strong) NSDictionary *params;

+ (LivePresenter *)shareInstance;
/// 获取切回前台的直播配置信息
/// @param completionHandler 处理回调，返回 最新的配置信息
//- (void)fetchRoomInfoWithCompletionHandler:(SYFetchRoomInfoCompletionHandler)completionHandler;

/** 用户列表 */
- (void)fetchRoomInfoWithType:(LiveType)type config:(LiveDefaultConfig *)config success:(SYNetServiceSuccessBlock)success failure:(SYNetServiceFailBlock)failure;
/**主播pk列表*/
- (void)fetchAnchorListWithType:(LiveType)type config:(LiveDefaultConfig *)config success:(SYNetServiceSuccessBlock)success failure:(SYNetServiceFailBlock)failure;
//请求用户信息
- (void)fetchUserDataWithUid:(NSString *)uid  success:(SYNetServiceSuccessBlock)success failure:(SYNetServiceFailBlock)failure;

- (void)fetchChatRoomWithType:(LiveType)type params:(NSDictionary *)params;

- (void)fetchSetchatIdWithParams:(NSDictionary *)params;
- (void)fetchGetchatIdWithParams:(NSDictionary *)params;

- (void)destory;
@end

NS_ASSUME_NONNULL_END
