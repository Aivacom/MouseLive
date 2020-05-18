//
//  LiveBG.h
//  MouseLive
//
//  Created by 张建平 on 2020/4/18.
//  Copyright © 2020 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveDefaultConfig.h"
#import "NetworkQualityStauts.h"
#import "SYPlayerProtocol.h"

//直播模式
typedef enum {
   PUBLISH_STREAM_RTC,
   PUBLISH_STREAM_CDN
}PublishMode;

NS_ASSUME_NONNULL_BEGIN

@protocol LiveBGDelegate <NSObject>
@optional

/// 网络错误
/// @param error 错误码
- (void)didNetError:(NSError*)error;

/// 网络关闭
- (void)didNetClose;

/// 网络已经连接
- (void)didNetConnected;

/// 网络连接中
- (void)didnetConnecting;

/// 加入房间失败
- (void)didJoinRoomError;

/// 发送消息失败，可能是 WS， 或者 hummer
/// @param error 错误码
- (void)didSendRequestFailed:(NSError*)error;

/// 音量的回调
/// @param uid uid 数组
/// @param volume volume 数组
- (void)didPlayVolumeWithUid:(NSArray<NSString*>*)uid volume:(NSArray<NSNumber*>*)volume;

/// 接受到被连麦的请求
/// @param uid 连麦用户 uid
/// @param roomid 连麦用户 roomid
- (void)didBeInvitedWithUid:(NSString*)uid roomid:(NSString*)roomid;

/// 被连麦的用户接受到取消连麦的请求
/// @param uid 连麦用户 uid
/// @param roomid 连麦用户 roomid
- (void)didBeInviteCancelWithUid:(NSString*)uid roomid:(NSString*)roomid;

/// 用户取消连麦
/// @param uid 连麦用户 uid
/// @param roomid 连麦用户 roomid
- (void)didInviteRefuseWithUid:(NSString*)uid roomid:(NSString*)roomid;

/// 连麦超时
/// @param uid 连麦用户 uid
/// @param roomid 连麦用户 roomid
- (void)didInviteTimeOutWithUid:(NSString*)uid roomid:(NSString*)roomid;

/// 用户接受连麦
/// @param uid 连麦用户 uid
/// @param roomid 连麦用户 roomid
- (void)didInviteAcceptWithUid:(NSString*)uid roomid:(NSString*)roomid;

/// 用户连麦中
/// @param uid 连麦用户 uid
/// @param roomid 连麦用户 roomid
- (void)didInviteRunningWithUid:(NSString*)uid roomid:(NSString*)roomid;

/// 用户进入
/// @param userList -- <uid, roomid>
- (void)didUserJoin:(NSDictionary<NSString*, NSString*>*)userList;

/// 用户退出
/// @param userList -- <uid, roomid>
- (void)didUserLeave:(NSDictionary<NSString*, NSString*>*)userList;

/// 主播离开了
- (void)didCloseRoom;

/// 连麦用户进入 -- 需要上位音频用户
/// @param uid 连麦用户 uid
/// @param roomid 连麦用户 roomid
- (void)didChatJoinWithUid:(NSString*)uid roomid:(NSString*)roomid;

/// 连麦用户离开 -- 把断开按钮消失掉 音聊人员下位
/// @param uid 连麦用户 uid
- (void)didChatLeaveWithUid:(NSString*)uid;

/// 刷新图像时返回给 UI -- 如果视频有人进入，会返回左边和右边的 uid，只有在 chatJoin 后才会返回，didChatLeaveWithUid 是不会返回
/// @param leftUid 如果只有一个图像，返回整个图像时谁的 uid ；如果有2个图像，返回左侧图像的 uid
/// @param rightUid 如果只有一个图像，返回nil；如果有2个图像，返回右侧图像的 uid
- (void)didShowCanvasWith:(NSString*)leftUid rightUid:(NSString*)rightUid;

/// 反馈网络状态
/// @param status 网络状态
- (void)didUpdateNetworkQualityStatus:(NetworkQualityStauts*)status;

/// 某人打开麦克风
/// @param uid 用户 id
- (void)didMicOnWithUid:(NSString*)uid;

/// 某人关闭麦克风
/// @param uid 用户 id
- (void)didMicOffWithUid:(NSString*)uid;

/// 主播关闭本人的麦克风
- (void)didMicOffSelfByAnchor;

/// 主播打开本人的麦克风
- (void)didMicOnSelfByAnchor;

/// 主播关闭其他人麦克风
/// @param uid 用户 id
- (void)didMicOffByAnchorWith:(NSString*)uid;

/// 主播打开其他人麦克风
/// @param uid 用户 id
- (void)didMicOnByAnchorWith:(NSString*)uid;

/// 自己被封了
- (void)didSelfBanned;

/// CDN 推流失败
- (void)didPublishStreamToCDNError;

/// thunder 网络已经断开 -- 先不使用
- (void)didThunderNetClose;

/// token 鉴权失败
- (void)didTokenError;

@end

@interface LiveBG : NSObject

@property (nonatomic, readonly, weak) UIView* bgView;

- (instancetype) initWithView:(UIView*)view anchor:(BOOL)isAnchor delegate:(id<LiveBGDelegate>) delegate limit:(int)limit haveVideo:(BOOL)haveVideo config:(LiveDefaultConfig*)config;

/// 初始化 view
/// @param view 绘画 view
/// @param isAnchor 自己是否是主播
/// @param delegate 回调 delegate
/// @param limit 连麦的限制数
/// @param haveVideo 是否有 video
- (instancetype) initWithView:(UIView*)view anchor:(BOOL)isAnchor delegate:(id<LiveBGDelegate>) delegate limit:(int)limit haveVideo:(BOOL)haveVideo;

/// 加入房间
/// @param config 进入房间的个人信息，主播信息，第二主播的信息
/// @param pushUrl CDN 推流的 url，如果不传，就是不使用 CDN 推流
- (void)joinRoomWithConfig:(LiveDefaultConfig*)config pushUrl:(nullable NSString *)pushUrl;

/// CDN模式观众加入房间
/// @param config 进入房间的个人信息，主播信息，第二主播的信息
/// @param pullUrl CDN 拉流的 url，如果不传，就是不使用 CDN 推流
- (void)joinRoomWithConfig:(LiveDefaultConfig*)config pullUrl:(nonnull NSString *)pullUrl;

/// CDN模式观众设置播放器
/// @param palyer CDN模式观众使用的播放器，需要符合SYPlayerProtocol协议
- (void)setPlayer:(id<SYPlayerProtocol>)palyer;

/// 离开房间
- (void)leaveRoom;

/// 如果房间相同就是同房间连麦，不相同就是跨房间连麦
/// @param uid 连麦用户 uid
/// @param roomid 连麦用户 roomid
/// @param complete 成功/失败回调 -- error 为空 成功
- (void)connectWithUid:(NSString*)uid roomid:(NSString*)roomid complete:(SendComplete)complete;

/// 取消连麦，一定在连麦中
/// @param uid 连麦用户 uid
/// @param roomid 连麦用户 roomid
/// @param complete 成功/失败回调 -- error 为空 成功
- (void)disconnectWithUid:(NSString*)uid roomid:(NSString*)roomid complete:(SendComplete)complete;

- (void)disconnectSelf:(SendComplete)complete;

/// 重新连接，因为切前后台和息屏，都有断开长连接情况，所以在切回 app 后，是要重新获取状态的，连麦+端麦等状态都需要改变。
/// 此接口只有在切前后台+息屏等需要状态更新的时候才调用，并且只有视频情况才有用
/// @param config 进入房间的个人信息，主播信息，第二主播的信息
- (void)reconnectWithConfig:(LiveDefaultConfig*)config;

/// 接受连麦
/// @param uid 连麦用户 uid
/// @param complete 成功/失败回调 -- error 为空 成功
- (void)acceptWithUid:(NSString*)uid complete:(SendComplete)complete;

/// 拒绝连麦
/// @param uid 连麦用户 uid
/// @param complete 成功/失败回调 -- error 为空 成功
- (void)refuseWithUid:(NSString*)uid complete:(SendComplete)complete;

/// 闭麦/开麦某一个人
/// @param uid 要闭麦的用户 id
/// @param off YES 闭麦某个人;  NO 开麦某个人
/// @param complete 成功/失败回调 -- error 为空 成功
- (void)micOffWithUid:(NSString*)uid off:(BOOL)off complete:(SendComplete)complete;

/// 自己闭麦/开麦
/// @param disabled yes - 闭麦； no -开麦；
/// @param complete 成功/失败回调 -- error 为空 成功
- (void)disableLocalAudio:(BOOL)disabled complete:(SendComplete)complete;

@end

NS_ASSUME_NONNULL_END
