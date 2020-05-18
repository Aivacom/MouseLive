//
//  LiveUserInfoList.h
//  MouseLive
//
//  Created by 张建平 on 2020/3/21.
//  Copyright © 2020 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveUserModel.h"
#import "LiveAnchorModel.h"
#import "LiveRoomInfoModel.h"
#import "LiveRoomModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^Complete)(LiveUserModel*);
typedef void(^CompleteUserList)(NSDictionary<NSString*, LiveUserModel*>*);
typedef void(^CompleteAnchorList)(NSDictionary<NSString*, LiveAnchorModel*>*);
typedef void(^CompleteRoomInfo)(LiveRoomInfoModel*, NSDictionary<NSString*, LiveUserModel*>*);

typedef enum : NSUInteger {
    LIVE_ROOM_TYPE_LIVE = 1,
    LIVE_ROOM_TYPE_CHAT,
    LIVE_ROOM_TYPE_KTV,
} LiveRoomType;

@interface LiveUserInfoList : NSObject

// 本房间 ID, 用户个人 ID ,主播 id
- (instancetype)initWithLiveType:(LiveRoomType)type roomid:(NSString*)roomid uid:(NSString*)uid anchorId:(NSString*)anchorId;

// 根据 uid 获取用户数据

/// 根据 uid 获取用户数据
/// @param uid uid
/// @param complete 主播列表获取完的回调
- (void)getUserInfoWithUid:(NSString*)uid complete:(Complete)complete;

/// 获取其他房间的用户信息
/// @param uid 要获取的 uid
/// @param complete 主播列表获取完的回调
- (void)getOtherRoomUserInfoWithUid:(NSString*)uid complete:(Complete)complete;

// 获取当前房间的用户表
- (void)getUserList:(CompleteUserList)complete;

// 进入房间后，首先调用获取房间信息，尽调用一次
- (void)getRoomInfo:(CompleteRoomInfo)complete;

/// 获取主播列表
/// @param complete 主播列表获取完的回调
- (void)getAnchorList:(CompleteAnchorList)complete;

// 有用户进入，uid
- (void)userJoin:(NSString*)uid;

// 用户推户，uid
- (void)userLeave:(NSString*)uid;

// 修改用户数据
- (void)setUserInfo:(LiveUserModel*)model;

//修改roominfo数据
- (void)setRoomInfo:(LiveRoomModel *)roomModel complete:(CompleteRoomInfo)complete;

//当前用户是否已经存在
- (BOOL)userAlreadyExistWithUid:(NSString *)uid;

- (void)destory;

@end

NS_ASSUME_NONNULL_END
