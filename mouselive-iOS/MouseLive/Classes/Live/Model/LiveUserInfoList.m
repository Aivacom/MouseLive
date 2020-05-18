//
//  LiveUserInfoList.m
//  MouseLive
//
//  Created by 张建平 on 2020/3/21.
//  Copyright © 2020 sy. All rights reserved.
//

#import "LiveUserInfoList.h"
#import "LiveRoomModel.h"
#import "SYHummerManager.h"
#import "LivePresenter.h"

typedef void(^CompleteUserInfo)(LiveUserModel *);

@interface LiveUserInfoList()

@property (nonatomic, strong) NSMutableDictionary* userDiction; // 本房间用户
@property (nonatomic, strong) NSMutableDictionary *anchorDiction; // 主播
@property (nonatomic, strong) NSMutableDictionary *otherUserDiction; // 其他用户
@property (nonatomic, strong) NSLock *userLock;
@property (nonatomic, copy) NSString *ownerRoomid;  // 本房间 ID
@property (nonatomic, copy) NSString *localUid;  // 用户个人 ID
@property (nonatomic, copy) NSString *anchorId;
@property (nonatomic) LiveRoomType roomType;
@property (nonatomic, strong) NSTimer *fetchTimer; // 重新刷新下 hummer
@property (nonatomic, strong) NSMutableArray *taskArray;

@end

@implementation LiveUserInfoList

- (instancetype)initWithLiveType:(LiveRoomType)type roomid:(NSString *)roomid uid:(NSString *)uid anchorId:(NSString *)anchorId
{
    if (self = [super init]) {
        self.userLock = [[NSLock alloc] init];
        self.localUid = uid;
        self.ownerRoomid = roomid;
        self.anchorId = anchorId;
        self.roomType = type;
        self.userDiction = [[NSMutableDictionary alloc] init];
        self.anchorDiction = [[NSMutableDictionary alloc] init];
        self.taskArray = [[NSMutableArray alloc] init];
        self.otherUserDiction = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)destory
{
    YYLogDebug(@"[MouseLive-App] LiveUserInfoList destory");
    [HttpService sy_httpRequestCancelWithArray:self.taskArray];
}

- (BOOL)userAlreadyExistWithUid:(NSString *)uid
{
    [self.userLock lock];
    LiveUserModel *user = [self.userDiction objectForKey:uid];
    [self.userLock unlock];
    if (user) {
        return YES;
    } else {
        return NO;
    }
    
}

- (void)getUserInfoWithUid:(NSString *)uid complete:(Complete)complete
{
    if (!uid) {
        return;
    }
    
    // 1. 从用户列表中获取
    [self.userLock lock];
    LiveUserModel *user = [self.userDiction objectForKey:uid];
    [self.userLock unlock];
    
    if (!user) {
        // 2. 没有就从其他用户中获取
        [self.userLock lock];
        user = [self.otherUserDiction objectForKey:uid];
        [self.userLock unlock];
        
        if (user) {
            complete(user);
        }
        else {
            // 3. 还没有就从 http
            [self fetchUserInfoWithUid:uid complete:^(LiveUserModel *u) {
                // 4. 如果没有就保存
                [self.userLock lock];
                if (u.Uid && ![u.Uid isEqualToString:@""]) {
                    // 如果 other 表中没有，就添加
                    if (![self.otherUserDiction objectForKey:uid]) {
                        [self.userDiction setObject:u forKey:u.Uid];
                    }
                }
                [self.userLock unlock];
                
                [[SYHummerManager sharedManager]fetchMembersWithCompletionHandler:^(NSArray<SYUser *> * _Nullable members, NSError * _Nullable error) {
                    if (!error) {
                        [members enumerateObjectsUsingBlock:^(SYUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if (obj.hummerUser.ID == u.Uid.longLongValue) {
                                *stop = YES;
                                u.isAdmin = obj.isAdmin;
                                u.isMuted = obj.isMuted;
                            }
                        }];
                        if (complete) {
                            complete(u);
                        }
                    }
                }];
            }];
        }
    } else {
        if (complete) {
            complete(user);
        }
    }
}

- (void)getOtherRoomUserInfoWithUid:(NSString *)uid complete:(Complete)complete
{
    if (!uid) {
        return;
    }
    
    // 1. 从用户列表中获取
    [self.userLock lock];
    LiveUserModel *user = [self.userDiction objectForKey:uid];
    [self.userLock unlock];
    
    if (!user) {
        // 2. 没有就从其他用户中获取
        [self.userLock lock];
        user = [self.otherUserDiction objectForKey:uid];
        [self.userLock unlock];
        
        if (user) {
            complete(user);
        }
        else {
            // 3. 还没有就从 http
            [self fetchUserInfoWithUid:uid complete:^(LiveUserModel *u) {
                // 4. 如果没有就保存
                [self.userLock lock];
                if (u.Uid && ![u.Uid isEqualToString:@""]) {
                    // 如果 user 表中有，就移除
                    if ([self.userDiction objectForKey:uid]) {
                        [self.userDiction removeObjectForKey:uid];
                    }
                    
                    [self.otherUserDiction setObject:u forKey:u.Uid];
                }
                [self.userLock unlock];
                
                if (complete) {
                    complete(u);
                }
            }];
        }
    }
    else {
        // 如果是从 userDiction 中找到的，需要转到 otherUserDiction 中
        [self.userLock lock];
        [self.userDiction removeObjectForKey:uid];
        [self.otherUserDiction setObject:user forKey:uid];
        [self.userLock unlock];
        if (complete) {
            complete(user);
        }
    }
}

- (void)getUserList:(CompleteUserList)complete
{
    [self.userLock lock];
    if (self.userDiction.count) {
        NSDictionary *c = [self.userDiction copy];
        [self.userLock unlock];
        if (complete) {
            complete(c);
        }
        return;
    }
    [self.userLock unlock];
    
    // 拉取用户列表
    [self fetchUserList:^(LiveRoomInfoModel * _Nonnull roomInfo, NSDictionary<NSString *,LiveUserModel *> * _Nonnull userList) {
        if (complete) {
            complete(userList);
        }
    }];
}

- (void)userJoin:(NSString *)uid
{
    [self fetchUserInfoWithUid:uid complete:^(LiveUserModel * _Nonnull model) {
        [self.userLock lock];
        if ([model.Uid isEqualToString:self.anchorId]) {
            model.isAnchor = YES;
        }
        
        if ([SYHummerManager sharedManager].isAllMuted) {
            if (!model.isAnchor) {
                model.isMuted = YES;
            }
        }
        
        model.roomId = self.ownerRoomid;
        [self.userDiction setObject:model forKey:model.Uid];
        [self.userLock unlock];
    }];
}

- (void)userLeave:(NSString *)uid
{
    [self.userLock lock];
    [self.userDiction removeObjectForKey:uid];
    [self.userLock unlock];
}

- (void)getRoomInfo:(CompleteRoomInfo)complete
{
    [self.userLock lock];
    [self.userDiction removeAllObjects];
    [self.userLock unlock];

    [self fetchUserList:complete];
}

- (void)setRoomInfo:(LiveRoomModel *)roomModel complete:(CompleteRoomInfo)complete
{
    [self.userLock lock];
    //人员置空
    [self.userDiction removeAllObjects];
    LiveRoomModel *model = roomModel;
    for (long i = 0, max = model.UserList.count; i < max; i++) {
        LiveUserModel *userModel = model.UserList[i];
        if ([userModel.Uid isEqualToString:self.anchorId]) {
            userModel.isAnchor = YES;
            
            // 设置全部禁言
            if ([SYHummerManager sharedManager].isAllMuted) {
                if (!userModel.isAnchor) {
                    userModel.isMuted = YES;
                }
            }
        }
        userModel.roomId = self.ownerRoomid;
        [self.userDiction setObject:userModel forKey:userModel.Uid];
    }
    NSDictionary *c = nil;
    if (self.userDiction.count) {
        c = [self.userDiction copy];
    }
    else {
        c = [[NSDictionary alloc] init];
    }
    [self.userLock unlock];
    
    if (complete) {
        complete(model.RoomInfo,c);
    }
    
}

- (void)setUserInfo:(LiveUserModel *)model
{
    [self.userLock lock];
    [self.userDiction setValue:model forKey:model.Uid];
    [self.userLock unlock];
}

////初始化心跳
//- (void)initFetchMember
//{
//    YYLogDebug(@"[MouseLive-LiveUserInfoList] initFetchMember entry");
//    [self destoryFetchMember];
//    dispatch_main_async_safe(^{
//        self.fetchTimer  = [NSTimer timerWithTimeInterval:0.001 target:self selector:@selector(fetchMemberFromHummer) userInfo:nil repeats:NO];
//        [[NSRunLoop currentRunLoop]addTimer:self.fetchTimer forMode:NSRunLoopCommonModes];
//    })
//    YYLogDebug(@"[MouseLive-LiveUserInfoList] initFetchMember exit");
//}

//取消心跳
- (void)destoryFetchMember
{
    YYLogDebug(@"[MouseLive-LiveUserInfoList] destoryFetchMember entry");
    __weak typeof (self) weakSelf = self;
    dispatch_main_async_safe(^{
        if (weakSelf.fetchTimer) {
            [weakSelf.fetchTimer invalidate];
            weakSelf.fetchTimer = nil;
        }
    });
    
    YYLogDebug(@"[MouseLive-LiveUserInfoList] destoryFetchMember exit");
}


- (void)fetchUserInfoWithUid:(NSString *)uid complete:(CompleteUserInfo)complete
{
    YYLogDebug(@"[MouseLive-LiveUserInfoList] fetchUserInfoWithUid entry");
    // @"api/v1/getUserInfo"
    // "Uid"
//    NSDictionary *params =  @{
//        kUid:@(uid.longLongValue)
//    };
    [[LivePresenter shareInstance] fetchUserDataWithUid:uid success:^(int taskId, id  _Nullable respObjc) {
        if (complete) {
            //respObjc 为model
            complete(respObjc);
        }
    } failure:^(int taskId, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
        
    }];

//    WeakSelf
//    int taskId = [HttpService sy_httpRequestWithType:SYHttpRequestKeyType_GetUserInfo params:params success:^(int taskId, id  _Nullable respObjc) {
//        [weakSelf.taskArray removeObject:@(taskId)];
//        NSString *code = [NSString stringWithFormat:@"%@",respObjc[kCode]];
//        if ([code isEqualToString:ksuccessCode]) {
//            LiveUserModel *model = [LiveUserModel mj_objectWithKeyValues:[respObjc objectForKey:kData]];
//            if (complete) {
//                complete(model);
//            }
//        }
//        else {
//            YYLogError(@"[MouseLive-LiveUserInfoList] fetchUserInfoWithUid failed， uid:%@, 错误信息:%@", params, [NSString stringWithFormat:@"%@",respObjc[kMsg]]);
//            if (complete) {
//                complete([[LiveUserModel alloc]init]);
//            }
//        }
//    } failure:^(int taskId, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
//        YYLogError(@"[MouseLive-LiveUserInfoList] fetchUserInfoWithUid http failed 失败");
//    }];
    
//    [self.taskArray addObject:@(taskId)];
    YYLogDebug(@"[MouseLive-LiveUserInfoList] fetchUserInfoWithUid exit");
}

- (void)fetchMemberFromHummerRoomInfo:roomInfo complete:(CompleteRoomInfo)complete
{
    YYLogDebug(@"[MouseLive-LiveUserInfoList] fetchMemberFromHummer entry");
    
    // 从 hummer 上获取用户属性，admin + mute
    [[SYHummerManager sharedManager] fetchMembersWithCompletionHandler:^(NSArray<SYUser *> * _Nullable members, NSError * _Nullable error) {
        if (error) {
            YYLogError(@"[MouseLive-LiveUserInfoList] fetchMemberFromHummer, failed 错误信息:%@", error);
        }
        else {
            YYLogError(@"[MouseLive-LiveUserInfoList] fetchMemberFromHummer OK");
            [self.userLock lock];
            NSArray *keys = [self.userDiction allKeys];
            for (long i = 0, max = keys.count; i < max; i++) {
                LiveUserModel *userModel = [self.userDiction objectForKey:keys[i]];
                if ([userModel.Uid isEqualToString:self.anchorId]) {
                    userModel.isAnchor = YES;
                }
                
                [members enumerateObjectsUsingBlock:^(SYUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.hummerUser.ID == userModel.Uid.longLongValue) {
                        *stop = YES;
                        userModel.isAdmin = obj.isAdmin;
                        userModel.isMuted = obj.isMuted;
                    }
                }];
            }
            [self.userLock unlock];
            NSDictionary *c = [self.userDiction copy];
             if (complete) {
                 complete(roomInfo, c);
                }
        }
    }];
    
    YYLogDebug(@"[MouseLive-LiveUserInfoList] fetchMemberFromHummer exit");
}

- (void)fetchUserList:(CompleteRoomInfo)complete
{
    YYLogDebug(@"[MouseLive-LiveUserInfoList] fetchUserList entry");
   
    // @"api/v1/getRoomInfo"
    // "Uid", "RoomId", "kRType"
//    NSDictionary *params =  @{
//        kUid:@(self.localUid.longLongValue),
//        kRoomId:@(self.ownerRoomid.longLongValue),
//        kRType:@(self.roomType),
//    };
    LiveDefaultConfig *config = [[LiveDefaultConfig alloc]init];
    config.localUid = self.localUid;
    config.ownerRoomId = self.ownerRoomid;
    __weak typeof (self) weakSelf = self;

    [[LivePresenter shareInstance]fetchRoomInfoWithType:self.roomType config:config success:^(int taskId, id  _Nullable respObjc) {
        LiveRoomModel *model = respObjc;
        [weakSelf.userLock lock];
        for (long i = 0, max = model.UserList.count; i < max; i++) {
            LiveUserModel *userModel = model.UserList[i];
            if ([userModel.Uid isEqualToString:weakSelf.anchorId]) {
                userModel.isAnchor = YES;
                
                // 设置全部禁言
                if ([SYHummerManager sharedManager].isAllMuted) {
                    if (!userModel.isAnchor) {
                        userModel.isMuted = YES;
                    }
                }
            }
            userModel.roomId = weakSelf.ownerRoomid;
            [weakSelf.userDiction setObject:userModel forKey:userModel.Uid];
        }
        
        NSDictionary *c = nil;
        if (weakSelf.userDiction.count) {
            c = [weakSelf.userDiction copy];
        }
        else {
            c = [[NSDictionary alloc] init];
        }
        
        [weakSelf.userLock unlock];
       
        // 发送获取 hummer 信息
        [weakSelf fetchMemberFromHummerRoomInfo:model.RoomInfo complete:complete];

    } failure:^(int taskId, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
        
    }];
//    int taskId = [HttpService sy_httpRequestWithType:SYHttpRequestKeyType_RoomInfo params:params success:^(int taskId, id  _Nullable respObjc) {
//        [weakSelf.taskArray removeObject:@(taskId)];
//        NSString *code = [NSString stringWithFormat:@"%@",respObjc[kCode]];
//        if ([code isEqualToString:ksuccessCode]) {
//            YYLogDebug(@"[MouseLive-LiveUserInfoList] fetchUserList OK");
//            LiveRoomModel *model = [LiveRoomModel mj_objectWithKeyValues:[respObjc objectForKey:kData]];
//
//            [weakSelf.userLock lock];
//            for (long i = 0, max = model.UserList.count; i < max; i++) {
//                LiveUserModel *userModel = model.UserList[i];
//                if ([userModel.Uid isEqualToString:weakSelf.anchorId]) {
//                    userModel.isAnchor = YES;
//
//                    // 设置全部禁言
//                    if ([SYHummerManager sharedManager].isAllMuted) {
//                        if (!userModel.isAnchor) {
//                            userModel.isMuted = YES;
//                        }
//                    }
//                }
//                userModel.roomId = weakSelf.ownerRoomid;
//                [weakSelf.userDiction setObject:userModel forKey:userModel.Uid];
//            }
//
//            NSDictionary *c = nil;
//            if (weakSelf.userDiction.count) {
//                c = [weakSelf.userDiction copy];
//            }
//            else {
//                c = [[NSDictionary alloc] init];
//            }
//
//            [weakSelf.userLock unlock];
//
//            if (complete) {
//                complete(model.RoomInfo, c);
//            }
//
//            // 发送获取 hummer 信息
//            [weakSelf initFetchMember];
//        }
//        else {
//            YYLogError(@"[MouseLive-LiveUserInfoList] fetchUserList failed， uid:%@, 错误信息:%@", params, [NSString stringWithFormat:@"%@",respObjc[kMsg]]);
//            if (complete) {
//                complete([[LiveRoomInfoModel alloc] init], [[NSDictionary alloc] init]);
//            }
//        }
//
//    } failure:^(int taskId, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
//        [weakSelf.taskArray removeObject:@(taskId)];
//        YYLogError(@"[MouseLive-LiveUserInfoList] fetchUserList http failed");
//    }];
//
//    [self.taskArray addObject:@(taskId)];
//    YYLogDebug(@"[MouseLive-LiveUserInfoList] fetchUserList exit");
}

/// 获取主播列表
/// @param complete 主播列表获取完的回调
- (void)getAnchorList:(CompleteAnchorList)complete
{
    YYLogDebug(@"[MouseLive-LiveUserInfoList] getAnchorList entry");
//    /**
//        获取主播列表（PK使用）
//        "Uid":0, or 121297
//        "RType": 1,
//     */
//    #define GetAnchorList @"api/v1/getAnchorList"
//    /**
//     获取直播房间观众列表
//     "Uid": 121297,
//     "Ri
    
//    NSDictionary *params =  @{
//        kRType:@(self.roomType),
//        kUid:@(self.localUid.longLongValue),
//    };
    LiveDefaultConfig *config = [[LiveDefaultConfig alloc]init];
       config.localUid = self.localUid;
    
    __weak typeof (self) weakSelf = self;

    [[LivePresenter shareInstance] fetchAnchorListWithType:self.roomType config:config success:^(int taskId, id  _Nullable respObjc) {
        [weakSelf.anchorDiction removeAllObjects];
        NSArray *dataArray = respObjc;
        for (long i = 0, max = dataArray.count; i < max; i++) {
            LiveAnchorModel *model = dataArray[i];
            [weakSelf.anchorDiction setObject:model forKey:model.AId];
        }

        NSDictionary *c = nil;
        if (weakSelf.anchorDiction.count) {
            c = [weakSelf.anchorDiction copy];
        }
        else {
            c = [[NSDictionary alloc] init];
        }
        
        if (complete) {
            complete(c);
        }
    } failure:^(int taskId, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
        
    }];
//    int taskId = [HttpService sy_httpRequestWithType:SYHttpRequestKeyType_AnchorList params:params success:^(int taskId, id  _Nullable respObjc) {
//        [weakSelf.taskArray removeObject:@(taskId)];
//        NSString *code = [NSString stringWithFormat:@"%@",respObjc[kCode]];
//        if ([code isEqualToString:ksuccessCode]) {
//            YYLogDebug(@"[MouseLive-LiveUserInfoList] getAnchorList ok");
//            NSArray *ListArray = [respObjc objectForKey:kData];
//            NSArray *dataArray = [LiveAnchorModel mj_objectArrayWithKeyValuesArray:ListArray];
//
//            [weakSelf.anchorDiction removeAllObjects];
//
//            for (long i = 0, max = dataArray.count; i < max; i++) {
//                LiveAnchorModel *model = dataArray[i];
//                [weakSelf.anchorDiction setObject:model forKey:model.AId];
//            }
//
//            NSDictionary *c = nil;
//            if (weakSelf.anchorDiction.count) {
//                c = [weakSelf.anchorDiction copy];
//            }
//            else {
//                c = [[NSDictionary alloc] init];
//            }
//
//            if (complete) {
//                complete(c);
//            }
//        }
//        else {
//            YYLogError(@"[MouseLive-LiveUserInfoList] getAnchorList failed， uid:%@, 错误信息:%@", params, [NSString stringWithFormat:@"%@",respObjc[kMsg]]);
//            if (complete) {
//                complete([[NSDictionary alloc] init]);
//            }
//        }
//    } failure:^(int taskId, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
//        [weakSelf.taskArray removeObject:@(taskId)];
//        YYLogError(@"[MouseLive-LiveUserInfoList] getAnchorList http failed");
//    }];
//
//    [self.taskArray addObject:@(taskId)];
//    YYLogDebug(@"[MouseLive-LiveUserInfoList] getAnchorList exit");
}


@end
