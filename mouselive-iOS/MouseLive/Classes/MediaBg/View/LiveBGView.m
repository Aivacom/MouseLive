//
//  LiveBGView.m
//  MouseLive
//
//  Created by 张建平 on 2020/3/5.
//  Copyright © 2020 sy. All rights reserved.
//

#import "LiveBGView.h"
#import "Masonry.h"
#import "SYCommonMacros.h"
#import "YYCGUtilities.h"
#import "GobalViewBound.h"
#import "SYThunderManagerNew.h"
#import "LiveInvite.h"
#import "LiveBeInvited.h"
#import "LiveInviteItem.h"
#import "WSRoomRequest.h"
#import "WSInviteRequest.h"
#import "WSMicOffRequest.h"
#import "SYThunderEvent.h"
#import "MixVideoConfig.h"
#import "SYToken.h"

@interface LiveBGView () <SYThunderDelegate>

@property (nonatomic, strong) SYVideoCanvas* leftCanvas;
@property (nonatomic, strong, readwrite) SYVideoCanvas *rightCanvas;
@property (nonatomic, copy) NSString *localUid;
@property (nonatomic, copy) NSString *ownerRoomId;
@property (nonatomic, assign) BOOL isAnchor;  // 是否是主播
@property (nonatomic, strong) LiveDefaultConfig *config;
@property (nonatomic, assign) BOOL haveVideo;  // 是否有视频
@property (nonatomic, strong) NetworkQualityStauts *networkQualityStatus;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *subscribeDic; // 保存跨房间连麦的用户 <uid, roomid>
@property (nonatomic, weak) id<LiveBGViewDelegate> delegate;
@property (nonatomic, weak) UIView *bgView;
@property (nonatomic, copy) NSString *pushUrl; // CDN 推流地址, 如果有推流地址，就要使用 CDN 推流
@property (nonatomic, assign) int pushVideoHeight; // 推流的视频高度，对应推流的分辨率高度
@property (nonatomic, assign) int pushVideoWidth; // 推流的视频宽度，对应推流的分辨率宽度
@property (nonatomic, assign) int tokenUpdateCount; // token 更新的次数

@end

@implementation LiveBGView

#pragma mark -- public
#pragma mark -- 初始化
- (instancetype)initWithView:(UIView *)view anchor:(BOOL)isAnchor haveVideo:(BOOL)haveVideo delegate:(id<LiveBGViewDelegate>)delegate
{
    if (self = [super init]) {
        self.bgView = view;
        if (haveVideo) {
            self.bgView.backgroundColor = [UIColor blackColor];
        }
        else {
            self.bgView.backgroundColor = [UIColor clearColor];
        }

        self.delegate = delegate;
        self.haveVideo = haveVideo;
        self.isAnchor = isAnchor;
        self.networkQualityStatus = [[NetworkQualityStauts alloc] init];
        self.subscribeDic = [[NSMutableDictionary alloc] init];
        self.tokenUpdateCount = 0;
        
        YYLogDebug(@"MouseLive-iOS initWithFrame live video. is anchor:%d, haveVideo:%d", isAnchor, haveVideo);
    }
    return self;
}

#pragma mark -- 进入房间
- (BOOL)joinRoomWithConfig:(LiveDefaultConfig *)config pushUrl:(NSString *)pushUrl
{
    YYLogDebug(@"MouseLive-iOS joinRoomWithConfig entry, config:%@, pushUrl:%@", [config string], pushUrl);
    self.localUid = config.localUid;
    self.ownerRoomId = config.ownerRoomId;
    self.config = config;
    self.pushUrl = pushUrl;
    
    [[SYThunderEvent sharedManager] setDelegate:self];
    
    // 发送token 消息，可以不使用
    int ret = [[SYThunderManagerNew sharedManager] joinRoom:self.ownerRoomId uid:self.localUid haveVideo:self.haveVideo pushUrl:pushUrl];
    YYLogDebug(@"MouseLive-iOS joinRoomWithConfig joinRoom return:%d ", ret);
    if (ret != 0) {
        return NO;
    }
    
    if (self.haveVideo) {
        if (self.isAnchor) {
            // 如果是主播，进入房间后，添加 local view
            [self video_CreateLeftCanvasWithUid:self.localUid roomid:self.ownerRoomId isLocal:YES];
        }
        else {
            // 加入主播
            [self video_CreateLeftCanvasWithUid:self.config.anchroMainUid roomid:self.config.anchroMainRoomId isLocal:NO];
        }
        
        if (self.config.anchroSecondRoomId && ![self.config.anchroSecondRoomId isEqualToString:@""]) {
            if (self.config.anchroSecondRoomId != self.ownerRoomId) {
                // 跨房间，不用发送连麦完成消息
                [self addSubscribe:self.config.anchroSecondRoomId uid:self.config.anchroSecondUid];
            }
            else {
                // 同房间其他观众连麦
                [self video_CreateRightCanvasWithUid:self.config.anchroSecondUid roomid:self.config.anchroSecondRoomId isLocal:NO];
            }
        }
    }
    
    YYLogDebug(@"MouseLive-iOS joinRoomWithConfig, exit");
    return YES;
}

#pragma mark -- 退出房间
- (void)leaveRoom
{
    YYLogDebug(@"MouseLive-iOS leaveRoom, config:%@", [self.config string]);
    
    if (self.haveVideo) {
        NSArray *keys = [self.subscribeDic allKeys];
        for (int i = 0, max = (int)keys.count; i < max; i++) {
            NSString *remoteRoomid = [self.subscribeDic objectForKey:keys[i]];
            NSString *remoteUid = keys[i];
            
            // 发送挂断消息
            // 如果订阅中，需要取消订阅
            YYLogDebug(@"MouseLive-iOS leaveRoom, removeSubscribe, uid:%@, roomid:%@", remoteUid, remoteRoomid);
            [self removeSubscribe:remoteRoomid uid:remoteUid];
        }
    }
    
    // 退出房间
    [[SYThunderManagerNew sharedManager] leaveRoom];
    
    YYLogDebug(@"MouseLive-iOS. leaveRoom exit");
}

#pragma mark -- 连接某人
- (void)connectWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    YYLogDebug(@"MouseLive-iOS connectWithUid entry, uid:%@, roomid:%@", uid, roomid);
    if (![self.ownerRoomId isEqualToString:roomid]) {
        // 跨房间，只有视频
        YYLogDebug(@"MouseLive-iOS disconnectWithUid video addSubscribe");
        [self addSubscribe:roomid uid:uid];
    }
    else {
        if (![self.localUid isEqualToString:uid]) {
            YYLogDebug(@"MouseLive-iOS disconnectWithUid video others");
            // TODO: zhangjianping 视频上有其他人连麦
            [self video_CreateRightCanvasWithUid:uid roomid:roomid isLocal:NO];
        }
        else {
            YYLogDebug(@"MouseLive-iOS disconnectWithUid video self");
            // 自己
            // 1. 打开摄像头
            // 2. 打开视频 + 音频
            [[SYThunderManagerNew sharedManager] enableVideoLive];
            [self video_CreateRightCanvasWithUid:self.localUid roomid:roomid isLocal:YES];
            self.config.anchroSecondUid = self.config.localUid;
            self.config.anchroMainRoomId = self.config.ownerRoomId;
        }
    }
    YYLogDebug(@"MouseLive-iOS. connectWithUid exit");
}

#pragma mark -- 断开某人
- (void)disconnectWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    YYLogDebug(@"MouseLive-iOS disconnectWithUid entry, uid:%@, roomid:%@", uid, roomid);
    if (self.haveVideo) {
        YYLogDebug(@"MouseLive-iOS disconnectWithUid video");
        [self video_DisconnectWithUid:uid roomid:roomid];
        
        if (self.config.anchroSecondUid == self.config.localUid) {
            self.config.anchroSecondRoomId = @"";
            self.config.anchroSecondUid = @"";
        }
    }
    else {
        YYLogDebug(@"MouseLive-iOS disconnectWithUid audio");
        [self audio_DisconnectWithUid:uid roomid:roomid];
    }

    YYLogDebug(@"MouseLive-iOS disconnectWithUid. exit");
}

#pragma mark -- 关闭音频
- (void)disableLocalAudio:(BOOL)disabled
{
    [[SYThunderManagerNew sharedManager] disableLocalAudio:disabled haveVideo:self.haveVideo];
}

#pragma mark -- private

#pragma mark -- 跨房间订阅
- (void)addSubscribe:(NSString * _Nonnull)roomId uid:(NSString * _Nonnull)uid
{
    YYLogDebug(@"MouseLive-iOS addSubscribe . uid:%@, roomid:%@", uid, roomId);
    
    // 1. 保存加入到订阅的用户 uid + roomid
    [self.subscribeDic setValue:roomId forKey:uid];
    
    // 2. 订阅
    [[SYThunderManagerNew sharedManager] addSubscribe:roomId uid:uid];

    // 3. 创建远程视图
    [self video_CreateRightCanvasWithUid:uid roomid:roomId isLocal:NO];
    
    YYLogDebug(@"MouseLive-iOS. addSubscribe exit");
}

#pragma mark -- 跨房间取消订阅
- (void)removeSubscribe:(NSString * _Nonnull)roomId uid:(NSString * _Nonnull)uid
{
    YYLogDebug(@"MouseLive-iOS . removeSubscribe uid:%@, roomid:%@", uid, roomId);
    
    // 1. 取消订阅对面主播
    [[SYThunderManagerNew sharedManager] removeSubscribe:roomId uid:uid];
    
    // 2. 删除保存的订阅数据
    [self.subscribeDic removeObjectForKey:uid];
    
    // 3. 删除视图
    [self video_ClearRemoteCanvasWithUid:uid];

    YYLogDebug(@"MouseLive-iOS. removeSubscribe exit");
}

#pragma mark -- audio

#pragma mark -- audio 断开
- (void)audio_DisconnectWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    YYLogDebug(@"MouseLive-iOS audio_DisconnectWithUid uid:%@, roomid:%@", uid, roomid);
    if (!self.isAnchor) {
        if ([self.localUid isEqualToString:uid]) {
            // 如果是自己
            // 如果不是主播
            // 1. 关闭音频
            YYLogDebug(@"MouseLive-iOS disconnectWithUid not anchor, stop local audio. uid:%@, roomid:%@", uid, roomid);
            [[SYThunderManagerNew sharedManager] disableLocalAudio:YES haveVideo:self.haveVideo];
            
            // 关闭本地声音的时候，要关闭耳返
            [[SYThunderManagerNew sharedManager] setEnableInEarMonitor:NO];
        }
    }
    YYLogDebug(@"MouseLive-iOS audio_DisconnectWithUid exit");
}

#pragma mark -- video 断开自己
- (void)video_DisconnectWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    YYLogDebug(@"MouseLive-iOS video_DisconnectWithUid entry uid:%@, roomid:%@", uid, roomid);
    if ([self.ownerRoomId isEqualToString:roomid]) {
        if ([self.localUid isEqualToString:uid]) {
            YYLogDebug(@"MouseLive-iOS video_DisconnectWithUid self");
            // 1. 关闭视频 + 音频
            // 2. 断开摄像头 -- 待定
            [[SYThunderManagerNew sharedManager] disableLocalVideo:YES];
            [[SYThunderManagerNew sharedManager] disableLocalAudio:YES haveVideo:self.haveVideo];
            
            [self video_ClearRemoteCanvasWithUid:self.localUid];
        }
        else {
            YYLogDebug(@"MouseLive-iOS video_DisconnectWithUid other");
            [self video_ClearRemoteCanvasWithUid:uid];
        }
    }
    else {
        YYLogDebug(@"MouseLive-iOS video_DisconnectWithUid removeSubscribe");
        [self removeSubscribe:roomid uid:uid];
    }
    YYLogDebug(@"MouseLive-iOS video_DisconnectWithUid exit");
}

#pragma mark -- video
#pragma mark - 创建视图
- (SYVideoCanvas *)video_CreateCanvasWithUid:(NSString *)uid roomid:(NSString *)roomid isLocal:(BOOL)isLocal
{
    YYLogDebug(@"MouseLive-iOS createCanvasWithUid -- entry");
    SYVideoCanvas *remoteCanvas = [[SYThunderManagerNew sharedManager] createVideoCanvasWithUid:uid isLocalCanvas:isLocal];
    SYCanvasStatus *canvasStatus = [[SYCanvasStatus alloc] init];
    canvasStatus.uid = uid;
    canvasStatus.roomid = roomid;
    canvasStatus.isAudioStreamStoped = NO;
    canvasStatus.isVideoStreamStoped = NO;
    remoteCanvas.status = canvasStatus;
    YYLogDebug(@"MouseLive-iOS createCanvasWithUid -- exit");
    return remoteCanvas;
}

#pragma mark -- 创建左视图
- (void)video_CreateLeftCanvasWithUid:(NSString *)uid roomid:(NSString *)roomid isLocal:(BOOL)isLocal
{
    YYLogDebug(@"MouseLive-iOS . createLeftCanvasWithUid uid:%@, roomid:%@, isLocal:%d", uid, roomid, isLocal);
    self.leftCanvas = [self video_CreateCanvasWithUid:uid roomid:roomid isLocal:isLocal];
    [self.bgView addSubview:self.leftCanvas.view];
    [self video_VideoShowBig:self.leftCanvas];
}

#pragma mark -- 创建右视图
- (void)video_CreateRightCanvasWithUid:(NSString *)uid roomid:(NSString *)roomid isLocal:(BOOL)isLocal
{
    YYLogDebug(@"MouseLive-iOS . createRightCanvasWithUid uid:%@, roomid:%@, isLocal:%d", uid, roomid, isLocal);
    if (![self.rightCanvas.uid isEqualToString:uid]) {
        self.rightCanvas = [self video_CreateCanvasWithUid:uid roomid:roomid isLocal:isLocal];
        [self.bgView addSubview:self.rightCanvas.view];
        [self video_VideoShowSmall:self.leftCanvas right:self.rightCanvas];
    }
    else {
        [self.rightCanvas.view removeFromSuperview];
        self.rightCanvas = [self video_CreateCanvasWithUid:uid roomid:roomid isLocal:isLocal];
        [self.bgView addSubview:self.rightCanvas.view];
        [self video_VideoShowSmall:self.leftCanvas right:self.rightCanvas];
    }
}

#pragma mark -- 清除视图
- (void)video_ClearRemoteCanvasWithUid:(NSString *)uid
{
    YYLogDebug(@"MouseLive-iOS . clearRemoteCanvasWithUid uid:%@, right.uid:%@", uid, self.rightCanvas.uid);
    if ([self.rightCanvas.uid isEqualToString:uid]) {
        YYLogDebug(@"MouseLive-iOS . clearRemoteCanvasWithUid uid is euqal self.rightCanvas.uid!!");
        [[SYThunderManagerNew sharedManager] clearCanvasViewWithUID:uid];
        [self.rightCanvas.view removeFromSuperview];
        
        [self video_VideoShowBig:self.leftCanvas];
        [self.networkQualityStatus.netWorkQualityDictionary removeObjectForKey:uid];
        self.rightCanvas = nil;
    }
}

#pragma mark -- 视频显示 1 个视图
- (void)video_VideoShowBig:(SYVideoCanvas *)canvas
{
    [canvas.view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bgView).offset(0);
        make.left.equalTo(self.bgView).offset(0);
        make.width.equalTo(@(self.bgView.frame.size.width));
        make.height.equalTo(@(self.bgView.frame.size.height));
    }];
    
    [self video_setOneMixVideo:canvas];
    
    YYLogDebug(@"MouseLive-iOS videoShowBig -- left uid:%@, local uid:%@, is anchor:%d", canvas.status.uid, self.localUid, self.isAnchor);
    if ([self.delegate respondsToSelector:@selector(didShowCanvasWith:rightUid:)]) {
        [self.delegate didShowCanvasWith:canvas.status.uid rightUid:@""];
    }
}

#pragma mark -- 混画 1 个视图
- (void)video_setOneMixVideo:(SYVideoCanvas *)canvas
{
    YYLogDebug(@"MouseLive-iOS video_setOneMixVideo entry, uid:%@, roomid:%@", canvas.status.uid, canvas.status.roomid);
    if (self.haveVideo) {
        self.pushVideoWidth = [[SYThunderManagerNew sharedManager] getVideoWidth];
        self.pushVideoHeight = [[SYThunderManagerNew sharedManager] getVideoHeight];
        
        YYLogDebug(@"MouseLive-iOS video_setOneMixVideo video height:%d, width:%d", self.pushVideoHeight, self.pushVideoWidth);
        
        NSMutableArray *array = [[NSMutableArray alloc] init];
        MixVideoConfig *config = [[MixVideoConfig alloc] init];
        config.bCrop = YES;
        config.bStandard = YES;
        config.rect = CGRectMake(0, 0, self.pushVideoWidth, self.pushVideoHeight);
        config.roomId = canvas.status.roomid;
        config.uid = canvas.status.uid;
        [array addObject:config];
        [[SYThunderManagerNew sharedManager] setMixCanvasWith:array];
    }
    YYLogDebug(@"MouseLive-iOS video_setOneMixVideo exit");
}

#pragma mark -- 混画 2 个视图
- (void)video_setTwoMixVideo:(SYVideoCanvas *)left right:(SYVideoCanvas *)right
{
    YYLogDebug(@"MouseLive-iOS video_setOneMixVideo entry, left - uid:%@, roomid:%@, right - uid:%@, roomid:%@", left.status.uid, left.status.roomid, right.status.uid, right.status.roomid);
    if (self.haveVideo) {
        self.pushVideoWidth = [[SYThunderManagerNew sharedManager] getVideoWidth];
        self.pushVideoHeight = [[SYThunderManagerNew sharedManager] getVideoHeight];
        
        YYLogDebug(@"MouseLive-iOS video_setOneMixVideo video height:%d, width:%d", self.pushVideoHeight, self.pushVideoWidth);
        
        NSMutableArray *array = [[NSMutableArray alloc] init];
        MixVideoConfig *leftConfig = [[MixVideoConfig alloc] init];
        leftConfig.bCrop = YES;
        leftConfig.bStandard = YES;
        leftConfig.rect = CGRectMake(0, 0, self.pushVideoWidth / 2, self.pushVideoHeight);
        leftConfig.roomId = left.status.roomid;
        leftConfig.uid = left.status.uid;
        [array addObject:leftConfig];
        
        MixVideoConfig *rightConfig = [[MixVideoConfig alloc] init];
        rightConfig.bCrop = YES;
        rightConfig.bStandard = YES;
        rightConfig.rect = CGRectMake(self.pushVideoWidth / 2, 0, self.pushVideoWidth / 2, self.pushVideoHeight);
        rightConfig.roomId = right.status.roomid;
        rightConfig.uid = right.status.uid;
        [array addObject:rightConfig];
        [[SYThunderManagerNew sharedManager] setMixCanvasWith:array];
    }
    YYLogDebug(@"MouseLive-iOS video_setOneMixVideo exit");
}

#pragma mark -- 视频显示 2 个视图
- (void)video_VideoShowSmall:(SYVideoCanvas *)left right:(SYVideoCanvas *)right
{
    YYLogDebug(@"MouseLive-iOS videoShowSmall entry, config:%@", [self.config string]);
    YYLogDebug(@"MouseLive-iOS , left uid:%@, right uid:%@", left.status.uid, right.status.uid);
    if (!self.isAnchor) {
        // 如果是观众，local 一定是主播，主播都是在左边
        if (![left.status.uid isEqualToString:self.config.anchroMainUid]) {
            // 如果是主播与自己连麦，自己在右边
            SYVideoCanvas *tmp = left;
            left = right;
            right = tmp;
        }
    }
    else {
        // 如果是直播，主播自己一定在左边
        if (![left.status.uid isEqualToString:self.localUid]) {
            // 如果是主播与自己连麦，自己在右边
            SYVideoCanvas *tmp = left;
            left = right;
            right = tmp;
        }
    }
    
    [left.view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bgView).offset(LIVE_BG_VIEW_SMALL_TOP);
        make.left.equalTo(self.bgView).offset(LIVE_BG_VIEW_SMALL_LEFT);
        make.width.equalTo(LIVE_BG_VIEW_SMALL_WIDTH);
        make.height.equalTo(LIVE_BG_VIEW_SMALL_HEIGHT);
    }];
    
    [right.view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bgView).offset(LIVE_BG_VIEW_SMALL_TOP);
        make.left.equalTo(self.bgView).offset(LIVE_BG_VIEW_SMALL_RIGHT);
        make.width.equalTo(LIVE_BG_VIEW_SMALL_WIDTH);
        make.height.equalTo(LIVE_BG_VIEW_SMALL_HEIGHT);
    }];
    
    [self video_setTwoMixVideo:left right:right];
    
    YYLogDebug(@"MouseLive-iOS VideoShowSmall -- left uid:%@, right uid:%@, local uid:%@, is anchor:%d", left.status.uid, right.status.uid, self.localUid, self.isAnchor);
    if ([self.delegate respondsToSelector:@selector(didShowCanvasWith:rightUid:)]) {
        [self.delegate didShowCanvasWith:left.status.uid rightUid:right.status.uid];
    }
    YYLogDebug(@"MouseLive-iOS VideoShowSmall -- exit");
}

#pragma mark - ThunderEventDelegate
/*!
 @brief 进入房间回调
 @param room 房间名
 @param uid 用户id
 @elapsed 未实现
 */
- (void)thunderEngine: (ThunderEngine * _Nonnull)engine onJoinRoomSuccess:(nonnull NSString *)room withUid:(nonnull NSString *)uid elapsed:(NSInteger)elapsed
{
    YYLogDebug(@"MouseLive-iOS . onJoinRoomSuccess. uid:%@, roomid:%@", uid, room);
    
    // 初始化
    [[SYThunderManagerNew sharedManager] setupIsVideo:self.haveVideo];
    
    if (self.isAnchor) {
        if (self.haveVideo) {
            // 打开视频开关
            [[SYThunderManagerNew sharedManager] enableVideoLive];
        }
        else {
            // 打开音频
            [[SYThunderManagerNew sharedManager] disableLocalAudio:NO haveVideo:self.haveVideo];
        }
    }
    else {
        if ([self.config.anchroSecondUid isEqualToString:uid]) {
            // 如果是自己断开了，又进来了并且在连麦中，打开自己
            [[SYThunderManagerNew sharedManager] enableVideoLive];
        }
    }
    
    if (!self.haveVideo) {
        // 如果是音频房，didShowCanvasWith 显示 右下角的网络状态
        if ([self.delegate respondsToSelector:@selector(didShowCanvasWith:rightUid:)]) {
            [self.delegate didShowCanvasWith:self.localUid rightUid:@""];
        }
    }
    
    YYLogDebug(@"MouseLive-iOS. onJoinRoomSuccess exit");
}
/*!
 @brief 离开房间
 */
- (void)thunderEngine: (ThunderEngine * _Nonnull)engine onLeaveRoomWithStats:(ThunderRtcRoomStats * _Nonnull)stats
{
}

/*!
 @brief 远端用户音频流停止/开启回调
 @param stopped 停止/开启，YES=停止 NO=开启
 @param uid 远端用户uid
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRemoteAudioStopped:(BOOL)stopped byUid:(nonnull NSString *)uid
{
    YYLogDebug(@"MouseLive-iOS . onRemoteAudioStopped uid:%@, stop:%d", uid, stopped);
}

- (void)remoteVideoLeaveWithUid:(NSString *)uid
{
    YYLogDebug(@"MouseLive-iOS . remoteVideoLeaveWithUid uid:%@", uid);
    if (self.isAnchor) {
        // 如果是主播，观众已经退出
        YYLogDebug(@"MouseLive-iOS . remoteVideoLeaveWithUid is anchor. uid:%@", uid);
        [self video_ClearRemoteCanvasWithUid:uid];
    }
    else {
        if (![self.config.anchroMainUid isEqualToString:uid]) {
            // 如果不是主播
            [self video_ClearRemoteCanvasWithUid:uid];
        }
    }
    
    // 观众退出，通知上层
    if ([self.delegate respondsToSelector:@selector(didChatLeaveWithUid:)]) {
        [self.delegate didChatLeaveWithUid:uid];
    }
    YYLogDebug(@"MouseLive-iOS. remoteVideoLeaveWithUid exit");
}

/*!
 @brief 某个Uid用户的视频流状态变化回调
 @param stopped 流是否已经断开（YES:断开 NO:连接）
 @param uid 对应的uid
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRemoteVideoStopped:(BOOL)stopped byUid:(nonnull NSString *)uid
{
    YYLogDebug(@"MouseLive-iOS. onRemoteVideoStopped   uid:%@, stopped:%d", uid, stopped);
    if (stopped) {
        [self remoteVideoLeaveWithUid:uid];
    }

    YYLogDebug(@"MouseLive-iOS. onRemoteVideoStopped  uid:%@, stopped:%d", uid, stopped);
}

/*!
 @brief 业务鉴权结果
 @param bizAuthResult 由业务鉴权服务返回，0表示成功；
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine bPublish:(BOOL)bPublish bizAuthResult:(NSInteger)bizAuthResult
{
    // -- 由后台服务器发送鉴权
}

#pragma mark play

/*!
 @brief 说话声音音量提示回调
 @param speakers 用户Id-用户音量（未实现，音量=totalVolume）
 @param totalVolume 混音后总音量
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onPlayVolumeIndication:(NSArray<ThunderRtcAudioVolumeInfo *> * _Nonnull)speakers
          totalVolume:(NSInteger)totalVolume
{
    NSMutableArray *uidArray = [[NSMutableArray alloc] init];
    NSMutableArray *volumeArray = [[NSMutableArray alloc] init];
    
    for (long i = 0, max = speakers.count; i < max; i++) {
        [uidArray addObject:speakers[i].uid];
        [volumeArray addObject:@(speakers[i].volume)];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didPlayVolumeWithUid:volume:)]) {
            [self.delegate performSelector:@selector(didPlayVolumeWithUid:volume:) withObject:uidArray withObject:volumeArray];
        }
    });
}

/*!
 @brief 采集声音音量提示回调
 @param totalVolume 采集总音量（包含麦克风采集和文件播放）
 @param cpt 采集时间戳
 @param micVolume 麦克风采集音量
 @
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onCaptureVolumeIndication:(NSInteger)totalVolume cpt:(NSUInteger)cpt micVolume:(NSInteger)micVolume
{
    
}

/*!
 @brief 音频播放数据回调
 @param uid 用户id
 @param duration 时长
 @param cpt 采集时间戳
 @param pts 播放时间戳
 @data 解码前数据
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onAudioPlayData:(nonnull NSString *)uid duration:(NSUInteger)duration cpt:(NSUInteger)cpt pts:(NSUInteger)pts data:(nullable NSData *)data
{
    
}

/*!
 @brief 音频播放频谱数据回调
 @data 频谱数据,类型UInt8，数值范围[0-LIVE_BG_VIEW_TOP]
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onAudioPlaySpectrumData:(nullable NSData *)data
{
    
}

/*!
 @brief 音频采集数据回调
 @data 采集PCM
 @sampleRate 数据采样率
 @channel 数据声道数
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onAudioCapturePcmData:(nullable NSData *)data sampleRate:(NSUInteger)sampleRate channel:(NSUInteger)channel
{
    
}

/*!
 @brief 渲染音频数据回调
 @data 渲染PCM
 @sampleRate 数据采样率
 @channel 数据声道数
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onAudioRenderPcmData:(nullable NSData *)data duration:(NSUInteger)duration sampleRate:(NSUInteger)sampleRate channel:(NSUInteger)channel
{
    
}

/*!
 @brief 接收到的透传协议消息回调
 @param msgData 透传的消息
 @param uid 发送该消息的uid
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRecvUserAppMsgData:(nonnull NSData *)msgData uid:(nonnull NSString *)uid
{
    
}

/*!
 @brief 透传协议发送失败状态回调
 @param status 失败状态(1-频率太高 2-发送数据太大 3-未成功开播)
 目前规定透传频率2次/s,发送数据大小限制在<=200Byte
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onSendAppMsgDataFailedStatus:(NSUInteger) status
{
    
}

/*!
 @brief 已显示远端视频首帧回调
 @param uid 对应的uid
 @param size 视频尺寸(宽和高)
 @param elapsed 从开始请求视频流到发生此事件过去的时间
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRemoteVideoPlay:(nonnull NSString *)uid size:(CGSize)size elapsed:(NSInteger)elapsed
{
    
}

/*!
 @brief sdk与服务器的网络连接状态回调
 @param status 连接状态，参见ThunderConnectionStatus
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onConnectionStatus:(ThunderConnectionStatus)status
{
    YYLogDebug(@"MouseLive-iOS onConnectionStatus, status:%ld", (long)status);
    // TODO: zhangjianping 先不使用
//    if (status == THUNDER_CONNECTION_STATUS_DISCONNECTED) {
//        if ([self.delegate respondsToSelector:@selector(didThunderNetClose)]) {
//            [self.delegate didThunderNetClose];
//        }
//    }
}

/*!
 @brief 已发送本地音频首帧的回调
 @param elapsed 从本地用户调用 joinRoom 方法直至该回调被触发的延迟（毫秒）
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onFirstLocalAudioFrameSent:(NSInteger)elapsed
{
    
}

/*
 @brief 开播或设置转码任务后调用 addPublishOriginStreamUrl设置推原流到CDN 或调用 addPublishTranscodingStreamUrl设置推混画流到CDN后会触发此回调。
 用于通知CDN推流是否成功，若推流失败errorCode指示具体原因。
 @param url: 推流的目标url
 @param errorCode： 推流错误码
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onPublishStreamToCDNStatusWithUrl:(NSString * _Nonnull)url errorCode:(ThunderPublishCDNErrorCode)errorCode
{
    YYLogDebug(@"MouseLive-iOS. onPublishStreamToCDNStatusWithUrl error:%ld", (long)errorCode);
    if (errorCode != THUNDER_PUBLISH_CDN_ERR_SUCCESS) {
        // 如果推流出现错误
        if ([self.delegate respondsToSelector:@selector(didPublishStreamToCDNError)]) {
            [self.delegate didPublishStreamToCDNError];
        }
    }
}

/*
 @brief 服务器网络连接中断通告，SDK 在调用 joinRoom 后无论是否加入成功，只要 10 秒和服务器无法连接就会触发该回调
 */
- (void)thunderEngineConnectionLost:(ThunderEngine * _Nonnull)engine
{
    YYLogError(@"[MouseLive-iOS] === thunderEngineConnectionLost!!!!!!");
}

/*!
 @brief 鉴权过期回调
 */
- (void)thunderEngineTokenRequest:(ThunderEngine * _Nonnull)engine
{
    YYLogDebug(@"[MouseLive-iOS] thunderEngineTokenRequest");
    [[SYToken sharedInstance] updateTokenWithComplete:^(NSString * _Nonnull token, NSError * _Nullable error) {
        if (!error) {
            YYLogDebug(@"[MouseLive-iOS] thunderEngineTokenRequest, update token:%@", token);
            [[SYThunderManagerNew sharedManager] updateToken:token];
        }
        else {
            YYLogDebug(@"[MouseLive-iOS] thunderEngineTokenRequest, error:%@", error);
        }
    }];
}

/**
@brief 鉴权服务即将过期回调
@param [OUT] token 即将服务失效的Token
@remark  用户的token快过期时会收到该回调
*/
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onTokenWillExpire:(nonnull NSString *)token
{
    YYLogError(@"[MouseLive-iOS] onTokenWillExpire, need token!!!!");
    [[SYToken sharedInstance] updateTokenWithComplete:^(NSString * _Nonnull token, NSError * _Nullable error) {
        if (!error) {
            YYLogDebug(@"[MouseLive-iOS] onTokenWillExpire, update token:%@", token);
            [[SYThunderManagerNew sharedManager] updateToken:token];
        }
        else {
            YYLogDebug(@"[MouseLive-iOS] onTokenWillExpire, error:%@", error);
        }
    }];
}

/*!
 @brief sdk鉴权结果
 @param sdkAuthResult 参见ThunderRtcSdkAuthResult
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine sdkAuthResult:(ThunderRtcSdkAuthResult)sdkAuthResult
{
    YYLogDebug(@"[MouseLive-iOS] sdkAuthResult, sdkAuthResult:%ld", (long)sdkAuthResult);
    self.tokenUpdateCount++;
    if (sdkAuthResult == THUNDER_SDK_AUTHRES_ERR_SERVER_INTERNAL ||
        sdkAuthResult == THUNDER_SDK_AUTHRES_ERR_NO_TOKEN ||
        sdkAuthResult == THUNDER_SDK_AUTHRES_ERR_TOKEN_EXPIRE ||
        sdkAuthResult == THUNDER_SDK_AUTHRES_ERR_TOKEN_WILL_EXPIRE) {
        [[SYToken sharedInstance] updateTokenWithComplete:^(NSString * _Nonnull token, NSError * _Nullable error) {
            if (!error) {
                YYLogDebug(@"[MouseLive-iOS] sdkAuthResult, update token:%@", token);
                [[SYThunderManagerNew sharedManager] updateToken:token];
            }
            else {
                YYLogDebug(@"[MouseLive-iOS] sdkAuthResult, error:%@", error);
            }
        }];
    }
    
    if (sdkAuthResult == THUNDER_SDK_AUTHRES_SUCCUSS) {
        self.tokenUpdateCount = 0;
    }
    
    if (self.tokenUpdateCount >= 4) {
        // token 鉴权连续 3 次，都不成功
        YYLogDebug(@"[MouseLive-iOS] sdkAuthResult 3 time failed. will send didTokenError");
        if ([self.delegate respondsToSelector:@selector(didTokenError)]) {
            YYLogDebug(@"[MouseLive-iOS] sdkAuthResult send didTokenError");
            [self.delegate didTokenError];
        }
    }
}

/*!
 @brief 用户被封禁回调
 @param status 封禁状态（YES-封禁 NO-解禁）
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onUserBanned:(BOOL)status
{
    YYLogError(@"[MouseLive-iOS] onUserBanned, status:%d", status);
    if (status) {
        if ([self.delegate respondsToSelector:@selector(didSelfBanned)]) {
            [self.delegate didSelfBanned];
        }
    }
}

/*!
 @brief 远端用户加入回调
 @param uid 远端用户uid
 @param elapsed 加入耗时
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onUserJoined:(nonnull NSString *)uid elapsed:(NSInteger)elapsed
{
    
}

/*!
 @brief 远端用户离开当前房间回调
 @param uid 离线用户uid
 @param reason 离线原因，参见ThunderLiveRtcUserOfflineReason
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onUserOffline:(nonnull NSString *)uid reason:(ThunderLiveRtcUserOfflineReason)reason
{
    
}

/*!
 @brief 网路上下行质量报告回调
 @param uid 表示该回调报告的是持有该id的用户的网络质量，当uid为0时，返回的是本地用户的网络质量
 @param txQuality 该用户的上行网络质量，参见ThunderLiveRtcNetworkQuality
 @param rxQuality 该用户的下行网络质量，参见ThunderLiveRtcNetworkQuality
 */
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onNetworkQuality:(nonnull NSString *)uid txQuality:(ThunderLiveRtcNetworkQuality)txQuality rxQuality:(ThunderLiveRtcNetworkQuality)rxQuality
{
    if (self.haveVideo) {
        // 如果是视频，就接受所有的
        NetWorkQuality *quality = [self.networkQualityStatus.netWorkQualityDictionary objectForKey:uid];
        if (!quality) {
            quality = [[NetWorkQuality alloc] init];
            quality.uid = uid;
            [self.networkQualityStatus.netWorkQualityDictionary setValue:quality forKey:uid];
        }

        quality.uploadNetQuality = txQuality;
        quality.downloadNetQuality = rxQuality;
    }
    else {
        if (self.isAnchor) {
            if ([self.localUid isEqualToString:uid]) {
                // 如果是音频，就只接受主播的
                NetWorkQuality *quality = [self.networkQualityStatus.netWorkQualityDictionary objectForKey:uid];
                if (!quality) {
                    quality = [[NetWorkQuality alloc] init];
                    quality.uid = uid;
                    [self.networkQualityStatus.netWorkQualityDictionary setValue:quality forKey:uid];
                }

                quality.uploadNetQuality = txQuality;
                quality.downloadNetQuality = rxQuality;
            }
        }
    }
    
    // 打日志
//    NSArray* keys = [self.networkQualityStatus.netWorkQualityDictionary allKeys];
//    for (NSString* key in keys) {
//        NetWorkQuality* quality = [self.networkQualityStatus.netWorkQualityDictionary objectForKey:key];
//        YYLogDebug(@"MouseLive-iOS. onNetworkQuality, uid:%@, :%lu, rxQuality:%lu", key, (unsigned long)quality.uploadNetQuality, (unsigned long)quality.downloadNetQuality);
//    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onFirstLocalVideoFrameSent:(NSInteger)elapsed
{
}


- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onNetworkTypeChanged:(NSInteger)type
{
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRoomStats:(nonnull RoomStats *)stats
{
    // 回调网络质量
    self.networkQualityStatus.audioUpload = stats.txAudioBitrate / 8192;
    self.networkQualityStatus.audioDownload = stats.rxAudioBitrate / 8192;
    self.networkQualityStatus.videoUpload = stats.txVideoBitrate / 8192;
    self.networkQualityStatus.videoDownload = stats.rxVideoBitrate / 8192;
    self.networkQualityStatus.upload = stats.txBitrate / 8192;
    self.networkQualityStatus.download = stats.rxBitrate / 8192;
    
//    YYLogDebug(@"==== Au:%f, Ad:%f, Vu:%f, Vd:%f, u:%f, d:%f", self.networkQualityStatus.audioUpload, self.networkQualityStatus.audioDownload, self.networkQualityStatus.videoUpload, self.networkQualityStatus.videoDownload, self.networkQualityStatus.upload, self.networkQualityStatus.download);
    
    if ([self.delegate respondsToSelector:@selector(didUpdateNetworkQualityStatus:)]) {
        [self.delegate didUpdateNetworkQualityStatus:self.networkQualityStatus];
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onVideoSizeChangedOfUid:(nonnull NSString *)uid size:(CGSize)size rotation:(NSInteger)rotation
{
    YYLogDebug(@"[MouseLive-iOS] onVideoSizeChangedOfUid, uid:%@, w:%f, h:%f, rotation:%ld", uid, size.width, size.height, (long)rotation);
    //   size.width:544.000000, height:960.000000
    //    #649 2020/05/02 14:14:45:222 D <-[LiveBGView thunderEngine:onVideoSizeChangedOfUid:size:rotation:]:916> createVideoCanvasWithUid setVideoWatermark  rect x:442.453339, y:100.749626, width:72.533333, height:72.533333
    
    //   size.width:368.000000, height:640.000000
    //    #928 2020/05/02 14:15:28:781 D <-[LiveBGView thunderEngine:onVideoSizeChangedOfUid:size:rotation:]:916> createVideoCanvasWithUid setVideoWatermark  rect x:299.306671, y:67.166420, width:49.066666, height:49.066666

    
    //   size.width:240.000000, height:320.000000
    //    #762 2020/05/02 14:20:12:380 D <-[LiveBGView thunderEngine:onVideoSizeChangedOfUid:size:rotation:]:930> createVideoCanvasWithUid setVideoWatermark  rect x:200.199997, y:33.583210, width:22.400000, height:22.400000
    
    //   rotation = 0  一直是 0
    // 基于 720P 的设置
    
    // 设置水印
    int screenHeight = [UIScreen mainScreen].bounds.size.height;
    int screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    // 水印的 startX 和 startY 可能不对，明天对应 android
    float startX = screenWidth - 70;
    float startY = 70;
    
    float scale = MAX(size.width / screenWidth, size.height / screenHeight);
    float x = startX * size.width / screenWidth;
    float y = startY * size.height / screenHeight;
    
    NSString *path =[[NSBundle mainBundle] pathForResource:@"watermark" ofType:@"png"];
//    UIImage *image = [UIImage imageWithContentsOfFile:path];
//    float w = image.size.width * scale;
//    float h = image.size.height * scale;
    
    // 缩小图标，原来图标宽高 96x96
    float w = 50 * scale;
    float h = 50 * scale;
    
    if (size.height == 320 && size.width == 240) {
        float scaleWH = 0.7;
        w = w * scaleWH;
        h = h * scaleWH;
        x = x + 5;
    }
    
    CGRect rect = CGRectMake(x, y, w, h);
    [[SYThunderManagerNew sharedManager] setVideoWatermarkWithUrl:[NSURL fileURLWithPath:path] rect:rect];
    YYLogDebug(@"createVideoCanvasWithUid setVideoWatermark  rect x:%f, y:%f, width:%f, height:%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onAudioCaptureStatus:(NSInteger)status
{
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onLocalAudioStats:(ThunderRtcLocalAudioStats * _Nonnull)stats
{
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onLocalVideoStats:(ThunderRtcLocalVideoStats * _Nonnull)stats
{
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRemoteAudioStatsOfUid:(nonnull NSString *)uid stats:(ThunderRtcRemoteAudioStats * _Nonnull)stats
{
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRemoteVideoStatsOfUid:(nonnull NSString *)uid stats:(ThunderRtcRemoteVideoStats * _Nonnull)stats
{
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onVideoCaptureStatus:(ThunderVideoCaptureStatus)status
{
}


@end
