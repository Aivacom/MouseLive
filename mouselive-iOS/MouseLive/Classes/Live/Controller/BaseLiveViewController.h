//
//  BaseLiveViewController.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/18.
//  Copyright © 2020 sy. All rights reserved.
//

#import "BaseViewController.h"
#import "AudioMicStateController.h"
#import "LiveBottonToolView.h"
#import "LivePublicTalkView.h"
#import "LiveRoomInfoModel.h"
#import "LiveDefaultConfig.h"
#import "AudioContentView.h"
#import "LiveUserInfoList.h"
#import "LiveAnchorView.h"
#import "LiveProtocol.h"
#import "LiveBG.h"
#import "SYPlayer.h"

typedef void (^BackBlock)(void);

NS_ASSUME_NONNULL_BEGIN

@interface BaseLiveViewController :BaseViewController

@property (nonatomic, readonly)  SYPlayer *player;

// 1 RTC模式 2 CDN模式（RTMP一对多）
@property (nonatomic,assign)PublishMode publishMode;

//当前正在连麦的观众
@property(nonatomic,   copy) NSString *currentVideoMircUid;

//当前正在连麦房间
@property(nonatomic,   copy) NSString *currentVideoMircRoomId;

//是否是主播
@property (nonatomic,assign)BOOL isAnchor;


//直播信息配置
@property(nonatomic, strong)LiveDefaultConfig *config;

//音频开播 或视频开播
@property (nonatomic,assign)LiveType liveType;

//底部工具栏
@property (nonatomic, strong) LiveBottonToolView *toolView;

//直播
@property (nonatomic, strong,nullable) LiveBG* liveBG;

//留言区
@property (nonatomic, weak) LivePublicTalkView *talkTableView;

//主播信息栏
@property (nonatomic, strong) LiveAnchorView *anchorView;

//音聊房
@property (nonatomic,strong) AudioContentView *audioContentView;

//用户本地列表对象
@property(nonatomic, strong) LiveUserInfoList *userInfoList;

//直播房间信息
@property (nonatomic, strong) LiveRoomInfoModel *liveRoomInfo;

//语音房，麦克风控制
@property (nonatomic, strong) AudioMicStateController* audioMicStateController;

//返回主页面回调
@property (nonatomic, copy) BackBlock backBlock;

@property (nonatomic, assign) BOOL isResponsBackblock;

//拉流或推流地址地址
@property (nonatomic, copy)NSString *url;

//是否需要重新进入音聊房间
@property(nonatomic, assign) BOOL shouldJion;


//初始化
- (instancetype)initWithAnchor:(BOOL)isAnchor config:(LiveDefaultConfig *)config pushMode:(PublishMode)pushModel;

//开始直播
- (void)startUpLiveWithMircUserListArray:(NSArray<LiveUserModel *> *)mircUserListArray;

//显示连接中状态条
- (void)showLinkHud;

//隐藏连接中状态条
- (void)hidenlinkHud;

//显示音聊房变声视图
- (void)showAudioWhine;

//观众连麦
- (void)linkMicr;

//公屏聊天消息封装
- (NSAttributedString *)fectoryChatMessageWithMessageString:(NSString *)message isjoinOrLeave:(BOOL)state;

//刷新挂断按钮
- (void)refreshHungUpButtonState:(NSNotification *)notify;


#pragma mark -LiveBGDelegate

//用户完成连麦
- (void)didChatJoinWithUid:(NSString*)uid roomid:(NSString*)roomid;

//用户进入
- (void)didUserJoin:(NSDictionary<NSString*, NSString*>*)userList;

//用户退出
- (void)didUserLeave:(NSDictionary<NSString*, NSString*>*)userList;

//连麦用户离开 -- 新加 -- 把断开按钮消失掉 音聊人员下位
- (void)didChatLeaveWithUid:(NSString*)uid;

//用户取消连麦（主播取消连麦）
- (void)didInviteRefuseWithUid:(NSString *)uid roomid:(NSString *)roomid;

//用户收到拒绝连麦的请求
- (void)didBeInviteCancelWithUid:(NSString *)uid roomid:(NSString *)roomid;

//连麦超时
- (void)didInviteTimeOutWithUid:(NSString *)uid roomid:(NSString *)roomid;

//用户连麦中
- (void)didInviteRunningWithUid:(NSString *)uid roomid:(NSString *)roomid;

//显示码率
- (void)didShowCanvasWith:(NSString*)leftUid rightUid:(NSString*)rightUid;

//切回前台 刷新UI
- (void)refreshLiveStatusWithLinkUid:(NSString * _Nullable)uid;

// 被取消连麦的时候释放资源
- (void)destroyEffects;


@end

NS_ASSUME_NONNULL_END
