//
//  LiveBG.m
//  MouseLive
//
//  Created by 张建平 on 2020/4/18.
//  Copyright © 2020 sy. All rights reserved.
//

#import "LiveBG.h"
#import "LiveInvite.h"
#import "LiveBeInvited.h"
#import "CCService.h"
#import "LiveBGView.h"
#import <YYModel.h>
#import "SYAppId.h"

@interface LiveBG () <LiveInviteDelegate, LiveBeInvitedDelegate, CCServiceDelegate, LiveBGViewDelegate>

@property (nonatomic, copy) NSString *localUid;
@property (nonatomic, copy) NSString *ownerRoomId;
@property (nonatomic, assign) BOOL isAnchor;  // 是否是主播
@property (nonatomic, weak) id<LiveBGDelegate> delegate;
@property (nonatomic, strong) LiveDefaultConfig *config;
@property (nonatomic, assign) BOOL haveVideo;  // 是否有视频
@property (nonatomic, strong) NSMutableDictionary *voiceChatJoinDictionary; // 语音房现在有多少人在连麦
@property (nonatomic, assign) int remoteLimit;  // 远程连麦的个数限制 -- 需要逻辑上再处理下
@property (nonatomic, strong) LiveInvite *liveInvite; // 主动连麦操作, invite 和 beinvited 外面应该还有一个manager 的
@property (nonatomic, strong) LiveBeInvited *liveBeInvited;  // 被动连麦操作
@property (nonatomic, strong) LiveBGView *liveBgView; // LiveBGView
@property (nonatomic, assign) int joinCount; // 调用加入房间的次数
@property (nonatomic, weak, readwrite) UIView *bgView;

@property (nonatomic, strong) id<SYPlayerProtocol> player;
@property (nonatomic, assign)PublishMode publishMode;

@end

@implementation LiveBG

#pragma mark -- public
#pragma mark -- 初始化
- (instancetype) initWithView:(UIView *)view anchor:(BOOL)isAnchor delegate:(id<LiveBGDelegate>) delegate limit:(int)limit haveVideo:(BOOL)haveVideo
{
    if (self = [super init]) {
        self.liveBgView = [[LiveBGView alloc] initWithView:view anchor:isAnchor haveVideo:haveVideo delegate:self];
        self.haveVideo = haveVideo;
        self.remoteLimit = limit;
        self.liveBeInvited = [[LiveBeInvited alloc] initWithDelegate:self];
        self.isAnchor = isAnchor;
        self.delegate = delegate;
        self.voiceChatJoinDictionary = [[NSMutableDictionary alloc] init];
        self.bgView = view;
        
#if 1
        [[CCService sharedInstance] setUseWS:YES];
#endif
        
        [[CCService sharedInstance] addObserver:self];
        
        YYLogDebug(@"MouseLive-iOS initWithFrame live video. is anchor:%d, haveVideo:%d", isAnchor, haveVideo);
    }
    return self;
}

- (instancetype) initWithView:(UIView *)view anchor:(BOOL)isAnchor delegate:(id<LiveBGDelegate>) delegate limit:(int)limit haveVideo:(BOOL)haveVideo config:(LiveDefaultConfig *)config
{
    if (self = [self initWithView:view anchor:isAnchor delegate:delegate limit:limit haveVideo:haveVideo]) {
        self.localUid = config.localUid;
        self.ownerRoomId = config.ownerRoomId;
        self.config = config;
    }
    
    return self;
}

#pragma mark -- 进入房间
- (void)joinRoomWithConfig:(LiveDefaultConfig *)config pushUrl:(nullable NSString *)pushUrl
{
    YYLogDebug(@"MouseLive-iOS joinRoomWithConfig entry, config:%@, pushUrl:%@", [config string], pushUrl);
    if (self.joinCount > 0) {
        YYLogDebug(@"MouseLive-iOS joinRoomWithConfig 加入 %d 次", ++self.joinCount);
        return;
    }
    
    // 如果设置 kCDNRtmpPushUrl，就使用 kCDNRtmpPushUrl
    if (![kCDNRtmpPushUrl isEqualToString:@""] && ([kCDNRtmpPushUrl containsString:@"http"] || [kCDNRtmpPushUrl containsString:@"https"])) {
        pushUrl = kCDNRtmpPushUrl;
    }
    
    self.joinCount++;
    self.localUid = config.localUid;
    self.ownerRoomId = config.ownerRoomId;
    self.config = config;
    
    [[CCService sharedInstance] joinRoom];
    WeakSelf
    [self sendJoinRoomWithComplete:^(NSError * _Nullable error) {
        // 这里只打日志就好了
        if (error) {
            YYLogDebug(@"MouseLive-iOS joinRoomWithConfig didJoinRoomError sendJoinRoomWithComplete");
            if ([weakSelf.delegate respondsToSelector:@selector(didJoinRoomError)]) {
                YYLogDebug(@"MouseLive-iOS joinRoomWithConfig didJoinRoomError delegate sendJoinRoomWithComplete");
                [weakSelf.delegate performSelector:@selector(didJoinRoomError)];
            }
        }
    }];
    
    if (![self.liveBgView joinRoomWithConfig:config pushUrl:pushUrl]) {
        YYLogDebug(@"MouseLive-iOS joinRoomWithConfig didJoinRoomError");
        if ([weakSelf.delegate respondsToSelector:@selector(didJoinRoomError)]) {
            YYLogDebug(@"MouseLive-iOS joinRoomWithConfig didJoinRoomError delegate");
            [weakSelf.delegate performSelector:@selector(didJoinRoomError)];
        }
        YYLogDebug(@"MouseLive-iOS joinRoomWithConfig joinRoom exit");
        return;
    }
    
    YYLogDebug(@"MouseLive-iOS joinRoomWithConfig, exit");
}

#pragma mark -- CDN模式观众进入房间
- (void)joinRoomWithConfig:(LiveDefaultConfig *)config pullUrl:(nonnull NSString *)pullUrl
{
    if (!_player) {
        YYLogDebug(@"MouseLive-iOS joinRoomWithConfig AliPlayer is Null");
        return;
    }
    
    YYLogDebug(@"MouseLive-iOS joinRoomWithConfig entry, config:%@, pullUrl:%@", [config string], pullUrl);
    if (self.joinCount > 0) {
        YYLogDebug(@"MouseLive-iOS joinRoomWithConfig 加入 %d 次", ++self.joinCount);
        return;
    }
    
    // 如果设置 kCDNRtmpPullUrl，就使用 kCDNRtmpPullUrl
    if (![kCDNRtmpPullUrl isEqualToString:@""] && ([kCDNRtmpPullUrl containsString:@"http"] || [kCDNRtmpPullUrl containsString:@"https"])) {
        pullUrl = kCDNRtmpPullUrl;
    }
    
    self.joinCount++;
    self.localUid = config.localUid;
    self.ownerRoomId = config.ownerRoomId;
    self.config = config;
    
    [self.player upadteUrl:pullUrl];
    
    [self.player start];
    
    self.publishMode = PUBLISH_STREAM_CDN;
    
    [[CCService sharedInstance] joinRoom];
    WeakSelf
    [self sendJoinRoomWithComplete:^(NSError * _Nullable error) {
        // 这里只打日志就好了
        if (error) {
            YYLogDebug(@"MouseLive-iOS joinRoomWithConfig didJoinRoomError sendJoinRoomWithComplete");
            if ([weakSelf.delegate respondsToSelector:@selector(didJoinRoomError)]) {
                YYLogDebug(@"MouseLive-iOS joinRoomWithConfig didJoinRoomError delegate sendJoinRoomWithComplete");
                [weakSelf.delegate performSelector:@selector(didJoinRoomError)];
            }
        }
    }];
}

#pragma mark -- CDN模式观众设置播放器
- (void)setPlayer:(id<SYPlayerProtocol>)palyer
{
    _player = palyer;
    _player.playView.frame = self.bgView.frame;
    [self.bgView addSubview:_player.playView];
}

- (LiveInvite *)liveInvite
{
    if (!_liveInvite) {
        _liveInvite = [[LiveInvite alloc] initWithDelegate:self uid:self.localUid roomid:self.ownerRoomId roomType:self.haveVideo ? WS_ROOM_TYPE_LIVE : WS_ROOM_TYPE_CHAT];
    }
    return _liveInvite;
}

#pragma mark -- 退出房间
- (void)leaveRoom
{
    YYLogDebug(@"MouseLive-iOS leaveRoom, config:%@", [self.config string]);
    
    // 取消掉其他任务
    [self.liveInvite cancelWithComplete:nil];
    
    // 发送退出房间消息
    [self sendLeaveRoomWithComplete:nil];
    
    [[CCService sharedInstance] removeObserver:self];
    
    [[CCService sharedInstance] leaveRoom];
    
    [self.liveBgView leaveRoom];
    
    YYLogDebug(@"MouseLive-iOS. leaveRoom exit");
}

#pragma mark -- 连麦某人
- (void)connectWithUid:(NSString *)uid roomid:(NSString *)roomid complete:(SendComplete)complete
{
    YYLogDebug(@"MouseLive-iOS connectWithUid, entry  uid:%@, roomid:%@", uid, roomid);
    // 1. 如果自己是主播，只能发送跨房间连麦
    // 2. 如果是观众，同房间间下，只能发送给主播
    BOOL canSend = YES;
    if (self.isAnchor) {
        if (![roomid isEqualToString:self.ownerRoomId]) {
            canSend = YES;
        }
    }
    else {
        if ([roomid isEqualToString:self.ownerRoomId]) {
            canSend = YES;
        }
    }
    
    if (canSend) {
        // 发送连麦请求
        YYLogDebug(@"MouseLive-iOS connectWithUid, 发送连麦 uid:%@, roomid:%@", uid, roomid);
        [self.liveInvite sendInvoteWithUid:uid roomId:roomid complete:complete];
    }
    else {
        YYLogError(@"MouseLive-iOS connectWithUid, send connect is error");
    }
    YYLogDebug(@"MouseLive-iOS. connectWithUid, exit");
}

#pragma mark -- 断开某人
- (void)disconnectWithUid:(NSString *)uid roomid:(NSString *)roomid complete:(SendComplete)complete
{
    YYLogDebug(@"MouseLive-iOS disconnectWithUid entry, uid:%@, roomid:%@", uid, roomid);
    if (![self.ownerRoomId isEqualToString:roomid]) {
        // 跨房间，一定是主播
        [self removeSubscribeWithRoomId:roomid uid:uid complete:complete];
    }
    else {
        // 发送断开连麦的请求，等待对方断麦
        WeakSelf
        [self sendHangupWithUid:uid roomid:roomid complete:^(NSError * _Nullable error) {
            if (!error) {
                [weakSelf.liveBgView disconnectWithUid:uid roomid:roomid];
                
                [weakSelf sendChatLeaveToOuter:uid];
            }
            else {
                YYLogDebug(@"MouseLive-iOS disconnectWithUid sendHangupWithUid error:%@", error);
            }
            
            if (complete) {
                complete(error);
            }
        }];
    }
    YYLogDebug(@"MouseLive-iOS disconnectWithUid. exit");
}

- (void)disconnectSelf:(SendComplete)complete
{
    YYLogDebug(@"MouseLive-iOS disconnectSelf entry");
    [self.liveBgView disconnectWithUid:self.config.localUid roomid:self.config.anchroMainRoomId];
    [self sendChatLeaveToOuter:self.config.localUid];
    [self sendHangupWithUid:self.config.anchroMainUid roomid:self.config.anchroMainRoomId complete:^(NSError * _Nullable error) {
        if (error) {
            YYLogDebug(@"MouseLive-iOS disconnectWithUid sendHangupWithUid error:%@", error);
        }
        
        if (complete) {
            complete(error);
        }
    }];
    YYLogDebug(@"MouseLive-iOS disconnectSelf exit");
}

#pragma mark -- 重新连接
- (void)reconnectWithConfig:(LiveDefaultConfig *)config
{
    YYLogDebug(@"MouseLive-iOS reconnectWithConfig entry, config:%@", [config string]);
    if (self.haveVideo) {
        if (self.isAnchor) {
            // 1. 如果是主播
            if (self.liveBgView.rightCanvas != nil) {
                // 1.1 切后台前有连麦人
                if (!config.anchroSecondUid || [config.anchroSecondUid isEqualToString:@""]) {
                    // 1.2 如果连麦人已经不存在了，清除掉连麦者视图
                    YYLogDebug(@"MouseLive-iOS reconnectWithConfig. self is anchor, remove the canvas");
                    NSString *uid = self.liveBgView.rightCanvas.status.uid;
                    [self.liveBgView disconnectWithUid:self.liveBgView.rightCanvas.status.uid roomid:self.liveBgView.rightCanvas.status.roomid];
                    
                    // 1.3 返回当前的人已经断麦
                    [self sendChatLeaveToOuter:uid];
                }
            }
        }
        else {
            // 2. 如果不是主播
            if (self.liveBgView.rightCanvas != nil) {
                // 2.1 以前有连麦者
                NSString *lastUid = self.liveBgView.rightCanvas.status.uid;
                NSString *lastRoomId = self.liveBgView.rightCanvas.status.roomid;
                 if (!config.anchroSecondUid || [config.anchroSecondUid isEqualToString:@""]) {
                     // 2.1.1 如果现在没有连麦者，清除视图
                     YYLogDebug(@"MouseLive-iOS reconnectWithConfig. self is not anchor, remove the canvas");
                     [self.liveBgView disconnectWithUid:lastUid roomid:lastRoomId];
                     
                     // 2.1.2 返回当前的人已经断麦
                     [self sendChatLeaveToOuter:lastUid];
                 }
                 else {
                     if (![config.anchroSecondUid isEqualToString:lastUid]) {
                         
                         YYLogDebug(@"MouseLive-iOS reconnectWithConfig. self is not anchor, remove the old canvas");
                         
                         // 2.1.3 如果不是以前的连麦者，清理视图
                         [self.liveBgView disconnectWithUid:lastUid roomid:lastRoomId];
                         
                         YYLogDebug(@"MouseLive-iOS reconnectWithConfig. self is not anchor, add the new canvas");
                         
                         // 2.1.4 并重新创建视图
                         [self.liveBgView connectWithUid:config.anchroSecondUid roomid:config.anchroSecondRoomId];
                         
                         // 2.1.5 发送有人连麦 -- 可以不发送，因为以前也是连麦的
                         [self sendChatJoinToOuter:config.anchroSecondUid roomid:config.anchroSecondRoomId];
                     }
                 }
            }
            else {
                // 3. 如果以前没有连麦者
                if (config.anchroSecondUid && ![config.anchroSecondUid isEqualToString:@""]) {
                    YYLogDebug(@"MouseLive-iOS reconnectWithConfig. self is not viewer, add the new canvas");
                    
                    // 3.1 如果现在是有连麦人的
                    [self.liveBgView connectWithUid:config.anchroSecondUid roomid:config.anchroSecondRoomId];
                    
                    // 3.2 发送有人连麦
                    [self sendChatJoinToOuter:config.anchroSecondUid roomid:config.anchroSecondRoomId];
                }
            }
        }
    }
    YYLogDebug(@"MouseLive-iOS reconnectWithConfig. exit");
}

#pragma mark -- 接受连麦
- (void)acceptWithUid:(NSString *)uid complete:(SendComplete)complete
{
    YYLogDebug(@"MouseLive-iOS acceptWithUid, accept from ui. uid:%@", uid);
    
    // 发送接受连麦
    WeakSelf
    [self.liveBeInvited acceptWithUid:uid complete:^(NSError * _Nullable error, NSString* roomId) {
        if (!error) {
            // 处理连麦
            [weakSelf handleAcceptWithUid:uid roomid:roomId];
        }
        else {
            YYLogDebug(@"MouseLive-iOS acceptWithUid send request failed, error:%@", error);
            if (!complete) {
                if ([weakSelf.delegate respondsToSelector:@selector(didSendRequestFailed:)]) {
                    [weakSelf.delegate didSendRequestFailed:error];
                }
            }
        }
        
        if (complete) {
            complete(error);
        }
    }];

    
    YYLogDebug(@"MouseLive-iOS.  acceptWithUid  exit");
}

#pragma mark -- 拒绝连麦
- (void)refuseWithUid:(NSString *)uid complete:(SendComplete)complete
{
    YYLogDebug(@"MouseLive-iOS refuseWithUid refuse from ui. uid:%@", uid);
    // 发送拒绝连麦
    [self.liveBeInvited refuseWithUid:uid complete:complete];
    YYLogDebug(@"MouseLive-iOS. refuseWithUid exit");
}

#pragma mark -- 自己闭麦/开麦
- (void)disableLocalAudio:(BOOL)disabled complete:(SendComplete)complete
{
    YYLogDebug(@"MouseLive-iOS disableLocalAudio entry. disabled:%d", disabled);
    // 发送闭麦, 同房间
    WSMicOffRequest *q = [[WSMicOffRequest alloc] init];
    q.ChatType = self.haveVideo ? WS_ROOM_TYPE_LIVE : WS_ROOM_TYPE_CHAT;
    q.SrcUid = self.localUid.longLongValue;
    q.SrcRoomId = self.ownerRoomId.longLongValue;
    q.DestUid = self.localUid.longLongValue;
    q.DestRoomId = self.ownerRoomId.longLongValue;
    q.MicEnable = !disabled;
    [q createTraceId];
    
    WeakSelf
    [[CCService sharedInstance] sendMicEnable:q complete:^(NSError * _Nullable error) {
        if (!error) {
            // 处理连麦
            [weakSelf.liveBgView disableLocalAudio:disabled];
        }
        else {
            YYLogDebug(@"MouseLive-iOS disableLocalAudio send request failed, error:%@", error);
            if (!complete) {
                if ([weakSelf.delegate respondsToSelector:@selector(didSendRequestFailed:)]) {
                    [weakSelf.delegate didSendRequestFailed:error];
                }
            }
        }
        
        if (complete) {
            complete(error);
        }
    }];
    
    YYLogDebug(@"MouseLive-iOS. disableLocalAudio exit");
}

#pragma mark -- 闭麦某一个人

/// 发送 mic off 请求
/// @param uid 对方 uid
/// @param off off - YES 闭麦; NO 开麦;
- (void)micOffWithUid:(NSString *)uid off:(BOOL)off complete:(SendComplete)complete
{
    YYLogDebug(@"MouseLive-iOS micOffWithUid entry. uid:%@, off:%d", uid, off);
    // 发送闭麦, 同房间
    WSMicOffRequest *q = [[WSMicOffRequest alloc] init];
    q.ChatType = self.haveVideo ? WS_ROOM_TYPE_LIVE : WS_ROOM_TYPE_CHAT;
    q.SrcUid = self.localUid.longLongValue;
    q.SrcRoomId = self.ownerRoomId.longLongValue;
    q.DestUid = uid.longLongValue;
    q.DestRoomId = self.ownerRoomId.longLongValue;
    q.MicEnable = !off;
    [q createTraceId];
    
    WeakSelf
    [[CCService sharedInstance] sendMicEnable:q complete:^(NSError * _Nullable error) {
        if (error) {
            YYLogDebug(@"MouseLive-iOS micOffWithUid send request failed, error:%@", error);
            if (!complete) {
                if ([weakSelf.delegate respondsToSelector:@selector(didSendRequestFailed:)]) {
                    [weakSelf.delegate didSendRequestFailed:error];
                }
            }
        }
        
        if (complete) {
            complete(error);
        }
    }];
    
    YYLogDebug(@"MouseLive-iOS. micOffWithUid exit");
}

#pragma mark -- private
#pragma mark -- 跨房间订阅
- (void)addSubscribeWithRoomId:(NSString * _Nonnull)roomId uid:(NSString * _Nonnull)uid
{
    YYLogDebug(@"MouseLive-iOS addSubscribe . uid:%@, roomid:%@", uid, roomId);
    
    [self.liveBgView connectWithUid:uid roomid:roomId];
    
    // 如果已经连麦，通知完成了
    [self.liveBeInvited completeWithUid:uid];
    YYLogDebug(@"MouseLive-iOS. addSubscribe exit");
}

#pragma mark -- 跨房间取消订阅
- (void)removeSubscribeWithRoomId:(NSString * _Nonnull)roomId uid:(NSString * _Nonnull)uid complete:(SendComplete)complete
{
    YYLogDebug(@"MouseLive-iOS . removeSubscribe uid:%@, roomid:%@", uid, roomId);
    
    // 2. 发送挂断请求
    if (complete) {
        YYLogDebug(@"MouseLive-iOS . removeSubscribe send handup");
        [self sendHangupWithUid:uid roomid:roomId complete:^(NSError * _Nullable error) {
            if (error) {
                YYLogDebug(@"MouseLive-iOS . removeSubscribe send handup, error:%@", error);
                complete(error);
            }
            else {
                [self.liveBgView disconnectWithUid:uid roomid:roomId];
            }
        }];
    }
    else {
        [self.liveBgView disconnectWithUid:uid roomid:roomId];
    }
    
    YYLogDebug(@"MouseLive-iOS. removeSubscribe exit");
}


#pragma mark -- 发送挂断请求
- (void)sendHangupWithUid:(NSString *)uid roomid:(NSString *)roomid complete:(SendComplete)complete
{
    YYLogDebug(@"MouseLive-iOS. sendHangupWithUid entry, uid:%@, roomid:%@", uid, roomid);
    WSInviteRequest *q = [[WSInviteRequest alloc] init];
    q.ChatType = self.haveVideo ? WS_ROOM_TYPE_LIVE : WS_ROOM_TYPE_CHAT;
    q.SrcUid = self.localUid.longLongValue;
    q.SrcRoomId = self.ownerRoomId.longLongValue;
    q.DestUid = uid.longLongValue;
    q.DestRoomId = roomid.longLongValue;
    [q createTraceId];
    
    WeakSelf
    [[CCService sharedInstance] sendHangup:q complete:^(NSError * _Nullable error) {
        if (error) {
            YYLogDebug(@"MouseLive-iOS sendHangupWithUid send request failed, error:%@", error);
            if (!complete) {
                if ([weakSelf.delegate respondsToSelector:@selector(didSendRequestFailed:)]) {
                    [weakSelf.delegate didSendRequestFailed:error];
                }
            }
        }
        
        if (complete) {
            complete(error);
        }
    }];
    YYLogDebug(@"MouseLive-iOS. sendHangupWithUid exit");
}

#pragma mark -- 发送进入房间消息给后台
- (void)sendJoinRoomWithComplete:(SendComplete)complete
{
    YYLogDebug(@"MouseLive-iOS. sendJoinRoomWithComplete entry, send WS_JOIN_ROOM");
    // thunder 进入房间成功后，才发送 ws 消息，ws 启动后调用
    WSRoomRequest *q = [[WSRoomRequest alloc] init];
    q.Uid = self.config.localUid.longLongValue;
    q.LiveRoomId = self.config.ownerRoomId.longLongValue;
    q.ChatRoomId = 0;
    [[CCService sharedInstance] sendJoinRoom:q complete:complete];
    YYLogDebug(@"MouseLive-iOS. sendJoinRoomWithComplete exit");
}

#pragma mark -- 发送退出房间消息给后台
- (void)sendLeaveRoomWithComplete:(SendComplete)complete
{
    YYLogDebug(@"MouseLive-iOS. sendLeaveRoomWithComplete entry, send WS_LEAVE_ROOM");
    // thunder 进入房间成功后，才发送 ws 消息，ws 启动后调用
    WSRoomRequest *q = [[WSRoomRequest alloc] init];
    q.Uid = self.config.localUid.longLongValue;
    q.LiveRoomId = self.config.ownerRoomId.longLongValue;
    q.ChatRoomId = 0;
    [[CCService sharedInstance] sendLeaveRoom:q complete:complete];
    YYLogDebug(@"MouseLive-iOS. sendLeaveRoomWithComplete exit");
}

#pragma mark -- 发送有人连麦的回调
- (void)sendChatJoinToOuter:(NSString *)uid roomid:(NSString *)roomid
{
    YYLogDebug(@"MouseLive-iOS sendChatJoinToOuter send delegate to ui. uid:%@, roomid:%@", uid, roomid);
    if (!self.haveVideo) {
        // 有人连麦进来
        if (self.isAnchor) {
            [self.voiceChatJoinDictionary setValue:@(1) forKey:uid];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(didChatJoinWithUid:roomid:)]) {
        YYLogDebug(@"MouseLive-iOS sendChatJoinToOuter send delegate didChatJoinWithUid to ui. uid:%@, roomid:%@", uid, roomid);
        [self.delegate didChatJoinWithUid:uid roomid:roomid];
    }
    YYLogDebug(@"MouseLive-iOS. sendChatJoinToOuter exit");
}

#pragma mark -- 发送有人断麦的回调
- (void)sendChatLeaveToOuter:(NSString *)uid
{
    YYLogDebug(@"MouseLive-iOS .sendChatLeaveToOuter entry. uid:%@", uid);
    if ([self.delegate respondsToSelector:@selector(didChatLeaveWithUid:)]) {
        YYLogDebug(@"MouseLive-iOS.sendChatLeaveToOuter didChatLeaveWithUid");
        [self.delegate didChatLeaveWithUid:uid];
    }
    
    // 清除连麦者，主要是语音房间
    [self.voiceChatJoinDictionary removeObjectForKey:uid];
    YYLogDebug(@"MouseLive-iOS .sendChatLeaveToOuter exit");
}



#pragma mark -- CCServiceDelegate
#pragma mark -- 处理有人断麦
- (BOOL)handleHangupWithBody:(NSDictionary *)body
{
    YYLogDebug(@"MouseLive-iOS. handleHangupWithBody body:%@", body);
    WSInviteRequest *q = (WSInviteRequest *)[WSInviteRequest yy_modelWithJSON:body];
    if (q.DestUid == self.localUid.longLongValue && q.DestRoomId == self.ownerRoomId.longLongValue) {
        // 在连麦中的用户，回接受到断开连麦消息
        if (q.SrcRoomId == self.ownerRoomId.longLongValue) {
            YYLogDebug(@"MouseLive-iOS. handleHangupWithBody same room");
            if (self.haveVideo) {
                YYLogDebug(@"MouseLive-iOS. handleHangupWithBody stop video");
                if (!self.isAnchor) {
                    // 同房间下，一定是观众关闭连麦
                    [self.liveBgView disconnectWithUid:self.localUid roomid:self.ownerRoomId];
                    
                    if (self.publishMode == PUBLISH_STREAM_CDN && _player) {
                        [self.liveBgView leaveRoom];
                        [self.bgView addSubview:self.player.playView];
                        
                        [self.player start];
                    }
                }
                else {
                    // 其他人走 onRemoteVideoStop
                    return YES;
                }
            }
            else {
                // 关闭语音，并删除
                YYLogDebug(@"MouseLive-iOS. handleHangupWithBody stop audio");
                
                // 音频，只能是同房间
                NSString *uid = nil;
                NSString *srcUid = [NSString stringWithFormat:@"%lld", q.SrcUid];
                if (self.isAnchor) {
                    if (![srcUid isEqualToString:self.localUid]) {
                        // 主播断开某人连麦
                        uid = srcUid;
                        
                        // 发送自己退出消息
                        [self sendChatLeaveToOuter:uid];
                    }
                }

                YYLogDebug(@"MouseLive-iOS.handleHangupWithBody exit");
                return YES;
            }
        }
        else {
            YYLogDebug(@"MouseLive-iOS. handleHangupWithBody removeSubscribe");
            // 如果是跨房间，已经接受到挂断请求了，就不发送了
            [self removeSubscribeWithRoomId:[NSString stringWithFormat:@"%lld", q.SrcRoomId] uid:[NSString stringWithFormat:@"%lld", q.SrcUid] complete:nil];
        }
        
        [self sendChatLeaveToOuter:[NSString stringWithFormat:@"%lld", q.SrcUid]];
    }
    
    YYLogDebug(@"MouseLive-iOS. handleHangupWithBody exit");
    return YES;
}

#pragma mark -- 处理有人断麦广播
- (BOOL)handleHangupBroatcastWithBody:(NSDictionary *)body
{
    YYLogDebug(@"MouseLive-iOS.handleHangupBroatcastWithBody  body:%@", body);
    // 接受到断开请求
    WSInviteRequest *q = (WSInviteRequest *)[WSInviteRequest yy_modelWithJSON:body];
    if (self.haveVideo) {
        if (q.DestRoomId == self.ownerRoomId.longLongValue) {
            if (q.SrcRoomId != self.ownerRoomId.longLongValue) {
                // dst 本方主播，src 是对方主播
                // 不同房间下，需要取消订阅
                YYLogDebug(@"MouseLive-iOS. handleHangupBroatcastWithBody different room 1");
                [self removeSubscribeWithRoomId:[NSString stringWithFormat:@"%lld", q.SrcRoomId] uid:[NSString stringWithFormat:@"%lld", q.SrcUid] complete:nil];
                
                [self sendChatLeaveToOuter:[NSString stringWithFormat:@"%lld", q.SrcUid]];
            }
            else {
                // dst 是被断麦用户，src 是主播
                YYLogDebug(@"MouseLive-iOS. handleHangupBroatcastWithBody same room 1");
                // TODO: zhangjianping 视频上有人断麦
                [self.liveBgView disconnectWithUid:[NSString stringWithFormat:@"%lld", q.DestUid] roomid:[NSString stringWithFormat:@"%lld", q.DestRoomId]];
                
                [self sendChatLeaveToOuter:[NSString stringWithFormat:@"%lld", q.DestUid]];
            }
        }
        else {
            if (q.SrcRoomId == self.ownerRoomId.longLongValue) {
                // dst 对方主播，src 本方主播
                // 不同房间下，需要取消订阅
                YYLogDebug(@"MouseLive-iOS. handleHangupBroatcastWithBody different room 2");
                [self removeSubscribeWithRoomId:[NSString stringWithFormat:@"%lld", q.DestRoomId] uid:[NSString stringWithFormat:@"%lld", q.DestUid] complete:nil];
                
                [self sendChatLeaveToOuter:[NSString stringWithFormat:@"%lld", q.DestUid]];
            }
        }
    }
    else {
        // 音频，只能是同房间
        YYLogDebug(@"MouseLive-iOS. handleHangupBroatcastWithBody audio");
        NSString *uid = nil;
        NSString *srcUid = [NSString stringWithFormat:@"%lld", q.SrcUid];
        NSString *dstUid = [NSString stringWithFormat:@"%lld", q.DestUid];
        if (!self.isAnchor) {
            if ([srcUid isEqualToString:self.config.anchroMainUid]) {
                // 主播断开某人连麦
                uid = dstUid;
            }
            else {
                // 自己断开的
                uid = srcUid;
            }
            
            if ([dstUid isEqualToString:self.localUid]) {
                // 断开自己
                [self.liveBgView disconnectWithUid:self.localUid roomid:self.ownerRoomId];
            }

            [self sendChatLeaveToOuter:uid];
        }
    }

    YYLogDebug(@"MouseLive-iOS. handleHangupBroatcastWithBody exit");
    return YES;
}

#pragma mark -- 处理有人连麦广播
- (BOOL)handleChatingbroadcastWithBody:(NSDictionary *)body
{
    YYLogDebug(@"MouseLive-iOS. handleChatingbroadcastWithBody body:%@", body);
    WSInviteRequest *q = (WSInviteRequest *)[WSInviteRequest yy_modelWithJSON:body];
    if (self.haveVideo) {
        // 可能发送本房间的主播，也可能是对方房间的主播
        if (q.DestRoomId == self.ownerRoomId.longLongValue) {
            if (q.SrcRoomId != self.ownerRoomId.longLongValue) {
                // 本房间的主播,dst 本房间，src 对方房间
                // 同房间不处理，不同房间处理，需要取消订阅
                YYLogDebug(@"MouseLive-iOS. handleChatingbroadcastWithBody different room 1");
                [self addSubscribeWithRoomId:[NSString stringWithFormat:@"%lld", q.SrcRoomId] uid:[NSString stringWithFormat:@"%lld", q.SrcUid]];
                
                [self sendChatJoinToOuter:[NSString stringWithFormat:@"%lld", q.SrcUid] roomid:[NSString stringWithFormat:@"%lld", q.SrcRoomId]];
            }
            else {
                if (!self.isAnchor) {
                    // TODO: zhangjianping 视频上有人连麦
                    [self.liveBgView connectWithUid:[NSString stringWithFormat:@"%lld", q.DestUid] roomid:[NSString stringWithFormat:@"%lld", q.DestRoomId]];
                }
                
                // 如果是同房间的，返回请求连麦的人
                [self sendChatJoinToOuter:[NSString stringWithFormat:@"%lld", q.DestUid] roomid:[NSString stringWithFormat:@"%lld", q.DestRoomId]];
            }
        }
        else {
            if (q.SrcRoomId == self.ownerRoomId.longLongValue) {
                // 对方房间的主播，dst 对方房间，src本房间主播
                // 同房间不处理，不同房间处理，需要取消订阅
                YYLogDebug(@"MouseLive-iOS. handleChatingbroadcastWithBody different room 2");
                [self addSubscribeWithRoomId:[NSString stringWithFormat:@"%lld", q.DestRoomId] uid:[NSString stringWithFormat:@"%lld", q.DestUid]];
            }
            else {
                // TODO: zhangjianping 视频上有人连麦
                [self.liveBgView connectWithUid:[NSString stringWithFormat:@"%lld", q.DestUid] roomid:[NSString stringWithFormat:@"%lld", q.DestRoomId]];
            }
            
            [self sendChatJoinToOuter:[NSString stringWithFormat:@"%lld", q.DestUid] roomid:[NSString stringWithFormat:@"%lld", q.DestRoomId]];
        }
    }
    else {
        // 音频，只能是同房间下
        [self sendChatJoinToOuter:[NSString stringWithFormat:@"%lld", q.DestUid] roomid:[NSString stringWithFormat:@"%lld", q.DestRoomId]];
    }
    
    YYLogDebug(@"MouseLive-iOS. handleChatingbroadcastWithBody exit");
    return YES;
}

#pragma mark -- 处理有人进入广播
- (BOOL)handleJoinBroadcastWithBody:(id)body
{
    YYLogDebug(@"MouseLive-iOS. handleJoinBroadcastWithBody body:%@", body);
    // 接受到用户进入请求
    NSArray<WSRoomRequest *> *array = (NSArray<WSRoomRequest *> *)body;
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    for (WSRoomRequest* q in array) {
        NSString *uid = [NSString stringWithFormat:@"%lld", q.Uid];
        NSString *roomid = [NSString stringWithFormat:@"%lld", q.LiveRoomId];
        if ([self.ownerRoomId isEqualToString:roomid]) {
            [dic setValue:roomid forKey:uid];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(didUserJoin:)]) {
        [self.delegate didUserJoin:[dic copy]];
    }
    YYLogDebug(@"MouseLive-iOS. handleJoinBroadcastWithBody exit");
    return YES;
}

#pragma mark -- 处理有人离开广播
- (BOOL)handleLeaveBroadcastWithBody:(id)body
{
    YYLogDebug(@"MouseLive-iOS. handleLeaveBroadcastWithBody body:%@", body);
    NSArray<WSRoomRequest *> *array = (NSArray<WSRoomRequest *> *)body;
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    for (WSRoomRequest* q in array) {
        NSString *uid = [NSString stringWithFormat:@"%lld", q.Uid];
        NSString *roomid = [NSString stringWithFormat:@"%lld", q.LiveRoomId];
        
        BOOL add = YES;
        
        if (!self.isAnchor) {
            if (q.Uid == self.config.anchroMainUid.longLongValue && q.LiveRoomId == self.config.anchroMainRoomId.longLongValue) {
                // 主播离开了, 直接退出房间
                YYLogDebug(@"MouseLive-iOS. handleLeaveBroadcastWithBody anchor is out");
                if ([self.delegate respondsToSelector:@selector(didCloseRoom)]) {
                    YYLogDebug(@"MouseLive-iOS. handleLeaveBroadcastWithBody didCloseRoom");
                    [self.delegate performSelector:@selector(didCloseRoom)];
                }
                
                YYLogDebug(@"MouseLive-iOS. handleLeaveBroadcastWithBody exit");
                return YES;
            }
        }
        
        if (self.liveBgView.rightCanvas) {
            if ([self.liveBgView.rightCanvas.status.uid isEqualToString:uid]) {
                if (![self.ownerRoomId isEqualToString:roomid]) {
                    // 跨房间，返回连麦者已经退出
                    YYLogDebug(@"MouseLive-iOS. handleLeaveBroadcastWithBody removeSubscribe");
                    [self removeSubscribeWithRoomId:roomid uid:uid complete:nil];
                    [self sendChatLeaveToOuter:uid];
                    
                    add = NO;
                }
                else {
                    YYLogDebug(@"MouseLive-iOS. handleLeaveBroadcastWithBody video_ClearRemoteCanvasWithUid");
                    [self.liveBgView disconnectWithUid:uid roomid:roomid];
                }
            }
        }
        
        if (!self.haveVideo) {
            // 清除连麦者
            [self.voiceChatJoinDictionary removeObjectForKey:uid];
        }
        
        if (add) {
            if ([self.ownerRoomId isEqualToString:roomid]) {
                [dic setValue:roomid forKey:uid];
            }
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(didUserLeave:)]) {
        [self.delegate didUserLeave:[dic copy]];
    }
    
#if 0
    // 接受到用户离开请求
    WSRoomRequest *q = (WSRoomRequest *)[WSRoomRequest yy_modelWithJSON:body];
    NSString *uid = [NSString stringWithFormat:@"%lld", q.Uid];
    NSString *roomid = [NSString stringWithFormat:@"%lld", q.LiveRoomId];
    if (!self.isAnchor) {
        if (q.Uid == self.config.anchroMainUid.longLongValue && q.LiveRoomId == self.config.anchroMainRoomId.longLongValue) {
            // 主播离开了
            if ([self.delegate respondsToSelector:@selector(didCloseRoom)]) {
                YYLogDebug(@"MouseLive-iOS. handleLeaveBroadcastWithBody didCloseRoom");
                [self.delegate performSelector:@selector(didCloseRoom)];
            }
            
            YYLogDebug(@"MouseLive-iOS. handleLeaveBroadcastWithBody exit");
            return YES;
        }
    }
    
    if (self.rightCanvas) {
        if ([self.rightCanvas.status.uid isEqualToString:uid]) {
            if (![self.ownerRoomId isEqualToString:roomid]) {
                // 跨房间下
                [self removeSubscribeWithRoomId:roomid uid:uid complete:nil];

                [self sendChatLeaveToOuter:uid];
                
                YYLogDebug(@"MouseLive-iOS. handleLeaveBroadcastWithBody exit");
                return YES;
            }
            else {
                [self video_ClearRemoteCanvasWithUid:uid];
            }
        }
    }
    
    if (!self.haveVideo) {
        // 清除连麦者
        [self.voiceChatJoinDictionary removeObjectForKey:uid];
    }
    
    if ([self.delegate respondsToSelector:@selector(didUserLeave:roomid:)]) {
        YYLogDebug(@"MouseLive-iOS. handleLeaveBroadcastWithBody didUserLeave, uid:%@, roomid:%@", uid, roomid);
        [self.delegate didUserLeave:uid roomid:roomid];
    }
#endif
    
    YYLogDebug(@"MouseLive-iOS. handleLeaveBroadcastWithBody exit");
    return YES;
}

#pragma mark -- 处理有人开麦/闭麦广播
- (BOOL)handleMicOffBroadcastWithBody:(NSDictionary *)body
{
    YYLogDebug(@"MouseLive-iOS. handleJoinBroadcastWithBody body:%@", body);
    WSMicOffRequest *q = (WSMicOffRequest *)[WSMicOffRequest yy_modelWithJSON:body];
    NSString *uid = [NSString stringWithFormat:@"%lld", q.DestUid];
    
    if (!self.haveVideo) {
        if (q.DestUid == q.SrcUid) {
            if (self.localUid.longLongValue == q.SrcRoomId) {
                // 自己，过滤掉
                return YES;
            }
            else {
                // 有人自己开麦/闭麦
                if (q.MicEnable) {
                    if ([self.delegate respondsToSelector:@selector(didMicOnWithUid:)]) {
                        [self.delegate didMicOnWithUid:uid];
                    }
                }
                else {
                    if ([self.delegate respondsToSelector:@selector(didMicOffWithUid:)]) {
                        [self.delegate didMicOffWithUid:uid];
                    }
                }
            }
        }
        else {
            // 音频房使用
            if ([self.localUid isEqualToString:uid]) {
                // 如果是自己
                if (q.MicEnable) {
                    if ([self.delegate respondsToSelector:@selector(didMicOffSelfByAnchor)]) {
                        [self.delegate didMicOnSelfByAnchor];
                    }
                }
                else {
                    if ([self.delegate respondsToSelector:@selector(didMicOffSelfByAnchor)]) {
                        [self.delegate didMicOffSelfByAnchor];
                    }
                }
            }
            else {
                // 主播关闭其他人
                if (q.MicEnable) {
                    if ([self.delegate respondsToSelector:@selector(didMicOnByAnchorWith:)]) {
                        [self.delegate didMicOnByAnchorWith:uid];
                    }
                }
                else {
                    if ([self.delegate respondsToSelector:@selector(didMicOffByAnchorWith:)]) {
                        [self.delegate didMicOffByAnchorWith:uid];
                    }
                }
            }
        }
    }
    
    YYLogDebug(@"MouseLive-iOS. handleJoinBroadcastWithBody exit");
    return YES;
}

#pragma mark -- 处理有人发送申请连麦
- (BOOL)handleApplyWithBody:(NSDictionary *)body
{
    [self.liveBeInvited handleMsgWithCmd:@(CCS_CHAT_APPLY) body:body];
    return YES;
}

#pragma mark -- 处理有人接受申请连麦
- (BOOL)handleAcceptWithBody:(NSDictionary *)body
{
    return [self.liveInvite handleMsgWithCmd:@(CCS_CHAT_ACCEPT) body:body];
}

#pragma mark -- 处理有人发送拒绝连麦
- (BOOL)handleRejectWithBody:(NSDictionary *)body
{
    return [self.liveInvite handleMsgWithCmd:@(CCS_CHAT_REJECT) body:body];
}

#pragma mark -- 处理有人发送取消连麦
- (BOOL)handleCancelWithBody:(NSDictionary *)body
{
    BOOL ret = [self.liveBeInvited handleMsgWithCmd:@(CCS_CHAT_CANCEL) body:body];
    if (!ret) {
        ret = [self.liveInvite handleMsgWithCmd:@(CCS_CHAT_CANCEL) body:body];
    }
    return ret;
}

#pragma mark -- 处理有人发送正在连麦中
- (BOOL)handleChattingWithBody:(NSDictionary *)body
{
    return [self.liveInvite handleMsgWithCmd:@(CCS_CHAT_CHATTING) body:body];
}

#pragma mark - LiveInviteDelegate
- (void)didInviteWithCmd:(LiveInviteActionType)type item:(LiveInviteItem *)item
{
    YYLogDebug(@"MouseLive-iOS. didInviteWithCmd entry, item:%@, type:%lu", item, (unsigned long)type);
    // ui 线程运行
    switch ((int)type) {
        case LIVE_INVITE_TYPE_ACCEPT:
            return [self handleAcceptWithUid:item.uid roomid:item.roomid];
        case LIVE_INVITE_TYPE_REFUSE:
            if ([self.delegate respondsToSelector:@selector(didInviteRefuseWithUid:roomid:)]) {
                YYLogDebug(@"MouseLive-iOS. didInviteWithCmd didInviteRefuseWithUid, uid:%@, roomid:%@", item.uid, item.roomid);
                [self.delegate performSelector:@selector(didInviteRefuseWithUid:roomid:) withObject:item.uid withObject:item.roomid];
            }
            break;
        case LIVE_INVITE_TYPE_RUNNING:
            if ([self.delegate respondsToSelector:@selector(didInviteRunningWithUid:roomid:)]) {
                YYLogDebug(@"MouseLive-iOS. didInviteWithCmd didInviteRunningWithUid, uid:%@, roomid:%@", item.uid, item.roomid);
                [self.delegate performSelector:@selector(didInviteRunningWithUid:roomid:) withObject:item.uid withObject:item.roomid];
            }
            break;
        case LIVE_INVITE_TYPE_TIME_OUT:
            if ([self.delegate respondsToSelector:@selector(didInviteTimeOutWithUid:roomid:)]) {
                YYLogDebug(@"MouseLive-iOS. didInviteWithCmd didInviteTimeOutWithUid, uid:%@, roomid:%@", item.uid, item.roomid);
                [self.delegate performSelector:@selector(didInviteTimeOutWithUid:roomid:) withObject:item.uid withObject:item.roomid];
            }
            break;
    }
    YYLogDebug(@"MouseLive-iOS. didInviteWithCmd exit");
}

#pragma mark -- 处理有人点击接受连麦的请求
- (void)handleAcceptWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    YYLogDebug(@"MouseLive-iOS handleAcceptWithUid handle accept from ws. uid:%@, roomid:%@", uid, roomid);
    if ([self.ownerRoomId isEqualToString:roomid]) {
        YYLogDebug(@"MouseLive-iOS handleAcceptWithUid handle accept from ws. same room. uid:%@, roomid:%@", uid, roomid);
        if (self.isAnchor) {
            if (self.haveVideo) {
                // 有人连麦
                [self.liveBgView connectWithUid:uid roomid:roomid];
                
                // 如果是主播，发送接受连麦
                YYLogDebug(@"MouseLive-iOS handleAcceptWithUid handle accept from ws. is anchor. uid:%@, roomid:%@", uid, roomid);
                if ([self.delegate respondsToSelector:@selector(didInviteAcceptWithUid:roomid:)]) {
                    YYLogDebug(@"MouseLive-iOS handleAcceptWithUid handle accept from ws. send didInviteAcceptWithUid to uid. uid:%@, roomid:%@", uid, roomid);
                    [self.delegate didInviteAcceptWithUid:uid roomid:roomid];
                }
            }
            
            [self sendChatJoinToOuter:uid roomid:roomid];
        }
        else {
            if (self.haveVideo) {
                YYLogDebug(@"MouseLive-iOS handleAcceptWithUid handle accept from ws. view, stop video. uid:%@, roomid:%@", uid, roomid);
                // 自己被连麦了
                if (self.publishMode == PUBLISH_STREAM_CDN && _player) {
                    [self.player stop];
                    [self.player.playView removeFromSuperview];
                    
                    if (![self.liveBgView joinRoomWithConfig:self.config pushUrl:nil]) {
                        YYLogDebug(@"MouseLive-iOS joinRoomWithConfig didJoinRoomError");
                        if ([self.delegate respondsToSelector:@selector(didJoinRoomError)]) {
                            YYLogDebug(@"MouseLive-iOS joinRoomWithConfig didJoinRoomError delegate");
                            [self.delegate performSelector:@selector(didJoinRoomError)];
                        }
                        YYLogDebug(@"MouseLive-iOS joinRoomWithConfig joinRoom exit");
                        return;
                    }
                    
                    YYLogDebug(@"MouseLive-iOS joinRoomWithConfig, exit");
                }
                
                [self.liveBgView connectWithUid:self.localUid roomid:self.ownerRoomId];

            }
        }
    }
    else {
        // 如果跨房间，一定是主播
        YYLogDebug(@"MouseLive-iOS handleAcceptWithUid handle accept from ws. different room. uid:%@, roomid:%@", uid, roomid);
        [self addSubscribeWithRoomId:roomid uid:uid];
        
        [self sendChatJoinToOuter:uid roomid:roomid];
    }
    YYLogDebug(@"MouseLive-iOS. handleAcceptWithUid exit");
}

#pragma mark -- 检测是否已经超过连接数量
- (BOOL)isChatingLimit
{
    // 如果已经超过连麦数量限制了，也发送拒绝
    BOOL ret = YES;
    if (self.isAnchor) {
        if (self.voiceChatJoinDictionary.count < self.remoteLimit) {
            ret = NO;
        }
    }
    
    return ret;
}

#pragma mark -- LiveBeInvitedDelegate
- (void)didBeInvitedWithCmd:(LiveBeInvitedActiontype)type item:(nonnull LiveInviteItem *)item
{
    YYLogDebug(@"MouseLive-iOS. didBeInvitedWithCmd entry, uid:%@, roomid:%@, type:%lu", item.uid, item.roomid, (unsigned long)type);
    // ui 线程运行
    if (type == LIVE_BE_INVITED_CANCEL) {
        // 用户取消
        if ([self.delegate respondsToSelector:@selector(didBeInviteCancelWithUid:roomid:)]) {
            YYLogDebug(@"MouseLive-iOS. didBeInvitedWithCmd send didBeInviteCancelWithUid, uid:%@, roomid:%@", item.uid, item.roomid);
            [self.delegate performSelector:@selector(didBeInviteCancelWithUid:roomid:) withObject:item.uid withObject:item.roomid];
        }
    }
    else if (type == LIVE_BE_INVITED_APPLY) {
        // 如果已经连麦了，发送拒绝
        if (self.liveBgView.rightCanvas || [self isChatingLimit]) {
            YYLogDebug(@"MouseLive-iOS. didBeInvitedWithCmd refuseWithUid");
            [self.liveBeInvited refuseWithUid:item.uid complete:^(NSError * _Nullable error) {
                YYLogDebug(@"MouseLive-iOS. didBeInvitedWithCmd refuseWithUid, error:%@", error);
            }];
            YYLogDebug(@"MouseLive-iOS. didBeInvitedWithCmd exit");
            return;
        }
        
        if ([self.delegate respondsToSelector:@selector(didBeInvitedWithUid:roomid:)]) {
            DDLogDebug(@"delegate beInvited didBeInvitedWithCmd, uid:%@, roomid:%@", item.uid, item.roomid);
            [self.delegate didBeInvitedWithUid:item.uid roomid:item.roomid];
        }
    }
    YYLogDebug(@"MouseLive-iOS. didBeInvitedWithCmd exit");
}

#pragma mark -- CCServiceDelegate
/// 广播有人进入的消息
/// @param body 有人进入房间列表 -- (NSArray<WSRoomRequest*>*)
- (BOOL)didJoinRoomBroadcast:(id)body
{
    return [self handleJoinBroadcastWithBody:body];
}

/// 广播有人退出的消息
/// @param body 有人退出房间列表 -- (NSArray<WSRoomRequest*>*)
- (BOOL)didLeaveRoomBroadcast:(id)body
{
    return [self handleLeaveBroadcastWithBody:body];
}

/// 房间被销毁
/// @param body -- (NSDictionary *)
- (BOOL)didRoomDestory:(id)body
{
    // 房间被销毁，直接返回主播退出房间
    if ([self.delegate respondsToSelector:@selector(didCloseRoom)]) {
        [self.delegate didCloseRoom];
    }
    return YES;
}

/// 接收到请求连麦的消息
/// @param body 结构体
- (BOOL)didChatApply:(id)body
{
    return [self handleApplyWithBody:body];
}

/// 接收到取消连麦的消息
/// @param body 结构体
- (BOOL)didChatCancel:(id)body
{
    return [self handleCancelWithBody:body];
}

/// 接收到接受连麦的消息
/// @param body 结构体
- (BOOL)didChatAccept:(id)body
{
    return [self handleAcceptWithBody:body];
}

/// 接收到拒绝连麦的消息
/// @param body 结构体
- (BOOL)didChatReject:(id)body
{
    return [self handleRejectWithBody:body];
}

/// 接收到挂断连麦的消息
/// @param body 结构体
- (BOOL)didChatHangup:(id)body
{
    return [self handleHangupWithBody:body];
}

/// 接收到有人连麦的广播
/// @param body 结构体
- (BOOL)didChatingBroadcast:(id)body
{
    return [self handleChatingbroadcastWithBody:body];
}

/// 接收到有人挂断连麦的广播
/// @param body 结构体
- (BOOL)didHangupBroadcast:(id)body
{
    return [self handleHangupBroatcastWithBody:body];
}

/// 接收到主播已经连麦满的消息
/// @param body 结构体
- (BOOL)didChattingLimit:(id)body
{
    return [self handleChattingWithBody:body];
}

/// 广播有人自己改变麦克风状态的消息
/// @param body 结构体
- (BOOL)didMicEnableBroadcast:(id)body
{
    return [self handleMicOffBroadcastWithBody:body];
}

/// 网络断开
- (void)didNetClose
{
    YYLogDebug(@"MouseLive-iOS. didNetClose entry");
    if ([self.delegate respondsToSelector:@selector(didNetClose)]) {
        YYLogDebug(@"MouseLive-iOS. didNetClose delegate didNetClose");
        [self.delegate didNetClose];
    }
    YYLogDebug(@"MouseLive-iOS. didNetClose exit");
}

/// 网络出现异常
/// @param error 异常 error
- (void)didNetError:(NSError *)error
{
    YYLogDebug(@"MouseLive-iOS. didNetError entry, error:%@", error);
    if ([self.delegate respondsToSelector:@selector(didNetError:)]) {
        YYLogDebug(@"MouseLive-iOS. didNetError delegate didNetError");
        [self.delegate didNetError:error];
    }
    YYLogDebug(@"MouseLive-iOS. didNetError exit");
}

/// 网络已经连接
- (void)didNetConnected
{
    YYLogDebug(@"MouseLive-iOS. didNetConnected entry");
    if ([self.delegate respondsToSelector:@selector(didNetConnected)]) {
        YYLogDebug(@"MouseLive-iOS. didNetConnected delegate didNetConnected");
        [self.delegate didNetConnected];
    }
    YYLogDebug(@"MouseLive-iOS. didNetConnected exit");
}

/// 网络连接中
- (void)didnetConnecting
{
    YYLogDebug(@"MouseLive-iOS. didnetConnecting entry");
    if ([self.delegate respondsToSelector:@selector(didnetConnecting)]) {
        YYLogDebug(@"MouseLive-iOS. didnetConnecting delegate didnetConnecting");
        [self.delegate didnetConnecting];
    }
    YYLogDebug(@"MouseLive-iOS. didnetConnecting exit");
}

#pragma mark -- LiveBGViewDelegate

/// 刷新图像时返回给 UI -- 如果视频有人进入，会返回左边和右边的 uid，只有在 chatJoin 后才会返回，didChatLeaveWithUid 是不会返回
/// @param leftUid 如果只有一个图像，返回整个图像时谁的 uid ；如果有2个图像，返回左侧图像的 uid
/// @param rightUid 如果只有一个图像，返回nil；如果有2个图像，返回右侧图像的 uid
- (void)didShowCanvasWith:(NSString *)leftUid rightUid:(NSString *)rightUid
{
    if ([self.delegate respondsToSelector:@selector(didShowCanvasWith:rightUid:)]) {
        [self.delegate didShowCanvasWith:leftUid rightUid:rightUid];
    }
}

/// 反馈网络状态
/// @param status 网络状态
- (void)didUpdateNetworkQualityStatus:(NetworkQualityStauts *)status
{
    if ([self.delegate respondsToSelector:@selector(didUpdateNetworkQualityStatus:)]) {
        [self.delegate didUpdateNetworkQualityStatus:status];
    }
}

/// 音量的回调
/// @param uid uid 数组
/// @param volume volume 数组
- (void)didPlayVolumeWithUid:(NSArray<NSString *> *)uid volume:(NSArray<NSNumber *> *)volume
{
    if ([self.delegate respondsToSelector:@selector(didPlayVolumeWithUid:volume:)]) {
        [self.delegate didPlayVolumeWithUid:uid volume:volume];
    }
}

/// 有用户连麦退出
/// @param uid 退出的用户 uid
- (void)didChatLeaveWithUid:(NSString *)uid
{
    [self sendChatLeaveToOuter:uid];
}

/// 有用户连麦进入
/// @param uid 进入的用户 uid
- (void)didChatJoinWithUid:(NSString *)uid
{
    [self sendChatJoinToOuter:uid roomid:self.ownerRoomId];
}

/// 自己被封了
- (void)didSelfBanned
{
    if ([self.delegate respondsToSelector:@selector(didSelfBanned)]) {
        [self.delegate didSelfBanned];
    }
}

/// CDN 推流失败
- (void)didPublishStreamToCDNError
{
    if ([self.delegate respondsToSelector:@selector(didPublishStreamToCDNError)]) {
        [self.delegate didPublishStreamToCDNError];
    }
}

/// thunder 网络已经断开
- (void)didThunderNetClose
{
    if ([self.delegate respondsToSelector:@selector(didThunderNetClose)]) {
        [self.delegate didThunderNetClose];
    }
}

/// token 鉴权失败
- (void)didTokenError
{
    if ([self.delegate respondsToSelector:@selector(didTokenError)]) {
        [self.delegate didTokenError];
    }
}

@end
