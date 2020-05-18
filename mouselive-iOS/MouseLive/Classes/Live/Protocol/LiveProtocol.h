//
//  LiveProtocol.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/17.
//  Copyright © 2020 sy. All rights reserved.
//
#import "LiveUserModel.h"
#import "LiveAnchorModel.h"
#import "LiveRoomInfoModel.h"
#import "LiveDefaultConfig.h"

typedef NS_ENUM(NSInteger,LiveType) {
  LiveTypeVideo = 1,
  LiveTypeAudio,
};

NS_ASSUME_NONNULL_BEGIN

@protocol LiveProtocol <NSObject>

@optional
- (void)audienceJoinChatRoom:(id)data;
//公聊区 主播创建聊天室
- (void)successChatRoom:(id)data withType:(LiveType)type;

- (void)liveViewRoomInfo:(LiveRoomInfoModel*)roomInfo UserListDataSource:(NSArray <LiveUserModel *>*)data;
- (void)liveViewAnchorListDataSource:(NSArray <LiveAnchorModel *>*)data;

- (void)liveUserData:(LiveUserModel *)user;
//创建房间失败
- (void)createRoomError:(NSString *)errorMessage;

- (void)createRoomSucess:(id)data;

@end

NS_ASSUME_NONNULL_END


