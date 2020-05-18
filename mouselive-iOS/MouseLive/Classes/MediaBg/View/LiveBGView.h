//
//  LiveBGView.h
//  MouseLive
//
//  Created by 张建平 on 2020/3/5.
//  Copyright © 2020 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveDefaultConfig.h"
#import "NetworkQualityStauts.h"
#import "SYVideoCanvas.h"

#define LIVE_BG_VIEW_SMALL_TOP 84
#define LIVE_BG_VIEW_SMALL_LEFT 0
#define LIVE_BG_VIEW_SMALL_RIGHT (self.bgView.frame.size.width) / 2
#define LIVE_BG_VIEW_SMALL_HEIGHT @(310 * [UIScreen mainScreen].bounds.size.height / 667)
#define LIVE_BG_VIEW_SMALL_WIDTH @((self.bgView.frame.size.width) / 2)

NS_ASSUME_NONNULL_BEGIN

@protocol LiveBGViewDelegate <NSObject>

/// 刷新图像时返回给 UI -- 如果视频有人进入，会返回左边和右边的 uid，只有在 chatJoin 后才会返回，didChatLeaveWithUid 是不会返回
/// @param leftUid 如果只有一个图像，返回整个图像时谁的 uid ；如果有2个图像，返回左侧图像的 uid
/// @param rightUid 如果只有一个图像，返回nil；如果有2个图像，返回右侧图像的 uid
- (void)didShowCanvasWith:(NSString*)leftUid rightUid:(NSString*)rightUid;

/// 反馈网络状态
/// @param status 网络状态
- (void)didUpdateNetworkQualityStatus:(NetworkQualityStauts*)status;

/// 音量的回调
/// @param uid uid 数组
/// @param volume volume 数组
- (void)didPlayVolumeWithUid:(NSArray<NSString*>*)uid volume:(NSArray<NSNumber*>*)volume;

/// 有用户连麦退出
/// @param uid 退出的用户 uid
- (void)didChatLeaveWithUid:(NSString*)uid;

/// 有用户连麦进入
/// @param uid 进入的用户 uid
- (void)didChatJoinWithUid:(NSString*)uid;

/// 推送到 CDN 失败
- (void)didPublishStreamToCDNError;

/// 自己被封了
- (void)didSelfBanned;

/// thunder 网络已经断开 -- 先不使用
- (void)didThunderNetClose;

/// token 鉴权失败
- (void)didTokenError;

@end

@interface LiveBGView : NSObject

@property (nonatomic, readonly, strong) SYVideoCanvas* rightCanvas;

#pragma mark -- new

/// 初始化 view
/// @param view 绘画 view
/// @param isAnchor 自己是否是主播
/// @param haveVideo 是否有 video
- (instancetype)initWithView:(UIView*)view anchor:(BOOL)isAnchor haveVideo:(BOOL)haveVideo delegate:(id<LiveBGViewDelegate>)delegate;

/// 加入房间
/// @param config 进入房间的个人信息，主播信息，第二主播的信息
/// @param pushUrl CDN 推流的 url，如果不传，就是不使用 CDN 推流
- (BOOL)joinRoomWithConfig:(LiveDefaultConfig*)config pushUrl:(NSString*)pushUrl;

/// 离开房间
- (void)leaveRoom;

/// 断开其他人
/// @param uid 连麦用户 uid
/// @param roomid 连麦用户 roomid
- (void)disconnectWithUid:(NSString *)uid roomid:(NSString *)roomid;

/// 如果房间相同就是同房间连麦，不相同就是跨房间连麦
/// @param uid 连麦用户 uid
/// @param roomid 连麦用户 roomid
- (void)connectWithUid:(NSString *)uid roomid:(NSString *)roomid;

/// 自己闭麦/开麦
/// @param disabled yes - 闭麦； no -开麦；
- (void)disableLocalAudio:(BOOL)disabled;

@end

NS_ASSUME_NONNULL_END
