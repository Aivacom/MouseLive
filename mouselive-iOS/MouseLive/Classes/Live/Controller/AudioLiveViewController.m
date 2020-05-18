//
//  VideoLiveViewController.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/2.
//  Copyright © 2020 sy. All rights reserved.
//

#import "AudioLiveViewController.h"
#import "AudioWhineView.h"
#import "SYThunderManagerNew.h"
#import "SYHummerManager.h"

@interface AudioLiveViewController ()<LiveBGDelegate,LiveProtocol,UIGestureRecognizerDelegate>
/**音聊区*/
@property (nonatomic, strong) AudioWhineView *whineView;
@property (nonatomic, strong) UIButton *linkMricButton;
@property (nonatomic, assign) BOOL isRefreshAudioView;

@end


@implementation AudioLiveViewController
#pragma mark -private value

- (LiveType)liveType
{
    return LiveTypeAudio;
}

/**上麦按钮*/
- (UIButton *)linkMricButton
{
    if (!_linkMricButton) {
        _linkMricButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_linkMricButton setBackgroundImage:[UIImage imageNamed:@"audio_link_mirc"] forState:UIControlStateNormal];
        //@"上麦"
        [_linkMricButton setTitle:NSLocalizedString(@"Connect", nil) forState:UIControlStateNormal];
        //:@"下麦"
        [_linkMricButton setTitle:NSLocalizedString(@"Disconnect", nil) forState:UIControlStateSelected];
        _linkMricButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];
        CGFloat wh =[NSLocalizedString(@"Disconnect", nil) boundingRectWithSize:CGSizeMake(1000, 13) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]} context:nil].size.width;
        wh = wh > 63 ? wh + 6 : 63;
        [ self.view insertSubview:_linkMricButton aboveSubview:self.talkTableView];
        _linkMricButton.frame = CGRectMake(SCREEN_WIDTH - wh - 8, SCREEN_HEIGHT - Live_Tool_H - TabbarSafeBottomMargin - 47 ,wh, 32);
        [_linkMricButton addTarget:self action:@selector(linkMricClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _linkMricButton;
}

- (AudioWhineView *)whineView
{
    if (!_whineView) {
        _whineView = [AudioWhineView shareAudioWhineView];
        [self.view insertSubview:_whineView atIndex:self.view.subviews.count -1];
        [_whineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(0);
            make.top.mas_equalTo(SCREEN_HEIGHT);
            make.height.mas_equalTo(SCREEN_HEIGHT);
            make.width.mas_equalTo(SCREEN_WIDTH);
        }];
        _whineView.hidden = YES;
    }
    return _whineView;
}

#pragma mark - viewDidLoad
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isRefreshAudioView = NO;
    self.audioMicStateController.isLinkWithAnchor = NO;
    if (self.isAnchor) {
        self.linkMricButton.hidden = YES;
    } else {
        self.linkMricButton.hidden = NO;
    }
    
}

#pragma mark - Button Action
- (void)linkMricClicked:(UIButton *)sender
{
    if (sender.selected) {
        //下麦
        WeakSelf
        [self.liveBG disconnectSelf:^(NSError * _Nullable error) {
            weakSelf.audioMicStateController.isLinkWithAnchor = NO;
            for (LiveUserModel *userModel in weakSelf.audioContentView.dataArray) {
                if ([userModel.Uid isEqualToString:weakSelf.config.localUid]) {
                    
                    // 要重新设回原值
                    userModel.MicEnable = YES;
                    userModel.SelfMicEnable = YES;
                    userModel.AnchorLocalLock = NO;
                    [weakSelf.userInfoList setUserInfo:userModel];
                    [weakSelf.audioContentView.dataArray removeObject:userModel];
                    break;
                }
            }
            [weakSelf.audioContentView refreshView];
            sender.selected = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeWhineView object:@"YES"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeAudioMicButtonState object:@"YES"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeAudioToolButtonState object:@"NO"];
        }];
//        [self.liveBG disconnectWithUid:self.config.localUid roomid:self.config.anchroMainRoomId complete:^(NSError * _Nullable error) {
//            weakSelf.audioMicStateController.isLinkWithAnchor = NO;
//            for (LiveUserModel *userModel in weakSelf.audioContentView.dataArray) {
//                if ([userModel.Uid isEqualToString:weakSelf.config.localUid]) {
//
//                    // 要重新设回原值
//                    userModel.MicEnable = YES;
//                    userModel.SelfMicEnable = YES;
//                    userModel.AnchorLocalLock = NO;
//                    [weakSelf.userInfoList setUserInfo:userModel];
//                    [weakSelf.audioContentView.dataArray removeObject:userModel];
//                    break;
//                }
//            }
//            [weakSelf.audioContentView refreshView];
//            sender.selected = NO;
//            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeWhineView object:@"YES"];
//            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeAudioMicButtonState object:@"YES"];
//            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeAudioToolButtonState object:@"NO"];
//        }];

    } else {
        //上麦
        [self linkMicr];
    }
}

- (void)linkMicr
{
    WeakSelf
    [self.liveBG connectWithUid:self.config.anchroMainUid roomid:self.config.anchroMainRoomId complete:^(NSError * _Nullable error) {
        weakSelf.linkMricButton.userInteractionEnabled = NO;
        //显示连接中状态条
        [weakSelf showLinkHud];
    }];
}


#pragma mark - 进入音频房间
/**实现父类方法*/
//刷新头像
- (void)startUpLiveWithMircUserListArray:(NSArray<LiveUserModel *> *)mircUserListArray
{
    [self.audioContentView.dataArray removeAllObjects];
    WeakSelf
    // 找已经上麦的人
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Uid != %@ AND LinkUid != %@ AND LinkRoomId != %@", weakSelf.liveRoomInfo.ROwner.Uid,@"0",@"0"];
    
    NSArray *filteredArray = [mircUserListArray filteredArrayUsingPredicate:predicate];
    if (filteredArray.count) {
        for (LiveUserModel *userModel in filteredArray) {
            if (![userModel.Uid isEqualToString:self.config.anchroMainUid]) {
                userModel.AnchorLocalLock = NO;
                [weakSelf.audioContentView.dataArray addObject:userModel];
            }
        }
    }
    [weakSelf.audioContentView refreshView];
    [weakSelf.toolView refreshAudioToolView];
    weakSelf.config.ownerRoomId = weakSelf.liveRoomInfo.RoomId;
    if (self.shouldJion) {
    [weakSelf.liveBG joinRoomWithConfig:weakSelf.config pushUrl:nil];
    }
}

#pragma mark - LiveBGDelegate

// 1音量的回调
- (void)didPlayVolumeWithUid:(NSArray<NSString *> *)uid volume:(NSArray<NSNumber *> *)volume
{
    return;
    //做麦克风闪烁
    //    for (LiveUserModel *model in self.audioContentView.dataArray) {
    //        for (NSString *userId in uid) {
    //            if ([userId isEqualToString:model.Uid]) {
    //                model.isSpeaking = YES;
    //            }else{
    //                model.isSpeaking = NO;
    //            }
    //        }
    //    }
    //    [self.audioContentView refreshView];
}

- (void)handleSelfJoin
{
    // 如果是自己上麦
    LiveUserModel *selfModel = LOCAL_USER;
    selfModel.MicEnable = YES;
    selfModel.SelfMicEnable = YES;
    if ([SYHummerManager sharedManager].isAllMicOff) {
        selfModel.MicEnable = NO;
    }
    else {
        // 如果没有全体禁麦，就打开音频
        [[SYThunderManagerNew sharedManager] disableLocalAudio:NO haveVideo:NO];
    }
    
    [self.audioContentView.dataArray addObject:selfModel];
    [self.audioContentView refreshView];
    self.linkMricButton.userInteractionEnabled = YES;
    self.linkMricButton.selected = YES;
    self.isRefreshAudioView = NO;
    self.audioMicStateController.isLinkWithAnchor = YES;
}


// 3主播完成连麦
- (void)didChatJoinWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    //隐藏连接中状态条
    [self hidenlinkHud];
    self.isRefreshAudioView = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeToolButtonState object:@{@"uid":uid,@"state":@"ON"}];
    if ([uid isEqualToString:self.config.localUid]) {
        [self handleSelfJoin];
        
        NSDictionary *messageDict = @{
            @"NickName":LOCAL_USER.NickName,
            @"Uid" :self.config.localUid,
            @"message":NSLocalizedString(@"have a seat.", nil),
            @"type": @"Notice"
        };
        NSAttributedString *messageString = [ self fectoryChatMessageWithMessageString:[NSString yy_stringFromJsonObject:messageDict] isjoinOrLeave:NO];
        [self.talkTableView.dataArray addObject: messageString];
        [self.talkTableView refreshTalkView];
    } else {
        // 其他人上麦
        WeakSelf
        [self.userInfoList getUserInfoWithUid:uid complete:^(LiveUserModel * _Nonnull userModel) {
            if ([SYHummerManager sharedManager].isAllMicOff) {
                // 全部禁麦
                userModel.MicEnable = NO;
            }
            [weakSelf.audioContentView.dataArray addObject:userModel];
            [weakSelf.audioContentView refreshView];
        }];
        
        // 如果不是自己的， 有人上座 黄色字体
        [self.userInfoList getUserInfoWithUid:uid complete:^(LiveUserModel * _Nonnull userModel) {
            NSDictionary *messageDict = @{
                @"NickName":userModel.NickName,
                @"Uid" :userModel.Uid,
                @"message":NSLocalizedString(@"have a seat.", nil),
                @"type": @"Notice"
            };
            NSAttributedString *messageString = [ weakSelf fectoryChatMessageWithMessageString:[NSString yy_stringFromJsonObject:messageDict] isjoinOrLeave:NO];
            [weakSelf.talkTableView.dataArray addObject: messageString];
            [weakSelf.talkTableView refreshTalkView];
        }];
        
    }
    
}


// 5连麦用户下麦 还在房间收听 -- 新加 -- 把断开按钮消失掉 音聊人员下位 自己不会
- (void)didChatLeaveWithUid:(NSString *)uid
{
    //  2.音频聊天对应人员下位
    for (LiveUserModel *userModel in self.audioContentView.dataArray) {
        if ([userModel.Uid isEqualToString:uid]) {
            
            // 要重新设回原值
            userModel.MicEnable = YES;
            userModel.SelfMicEnable = YES;
            userModel.AnchorLocalLock = NO;
            [self.userInfoList setUserInfo:userModel];
            [self.audioContentView.dataArray removeObject:userModel];
            break;
        }
    }
    [self.audioContentView refreshView];
    
    if (![self.config.localUid isEqualToString:uid]) {
        // 如果不是自己的，有人下座 黄色字体
        WeakSelf
        [self.userInfoList getUserInfoWithUid:uid complete:^(LiveUserModel * _Nonnull userModel) {
            NSDictionary *messageDict = @{
                @"NickName":userModel.NickName,
                @"Uid" :userModel.Uid,
                @"message":NSLocalizedString(@"left the seat.", nil),
                @"type":@"Notice"
            };
            NSAttributedString *messageString = [ weakSelf fectoryChatMessageWithMessageString:[NSString yy_stringFromJsonObject:messageDict] isjoinOrLeave:NO];
            [weakSelf.talkTableView.dataArray addObject: messageString];
            [weakSelf.talkTableView refreshTalkView];
        }];
    }
    else {
        NSDictionary *messageDict = @{
            @"NickName":LOCAL_USER.NickName,
            @"Uid" :LOCAL_USER.Uid,
            @"message":NSLocalizedString(@"left the seat.", nil),
            @"type":@"Notice"
        };
        NSAttributedString *messageString = [ self fectoryChatMessageWithMessageString:[NSString yy_stringFromJsonObject:messageDict] isjoinOrLeave:NO];
        [self.talkTableView.dataArray addObject: messageString];
        [self.talkTableView refreshTalkView];
        //变声view状态更改
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeWhineView object:@"YES"];
        if (!self.isAnchor) {
            self.linkMricButton.selected = NO;
            // 下边的工具栏换成开麦图标
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeAudioMicButtonState object:@"YES"];
            
            //隐藏工具栏中的开麦 + 变声
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeAudioToolButtonState object:@"NO"];
        }
    }
}

//连麦用户离开
- (void)didUserLeave:(NSDictionary<NSString *, NSString *> *)userList
{
    NSArray<NSString *>* uidKeys = [userList allKeys];
    
    for (NSString* uid in uidKeys) {
        for (LiveUserModel* userModel in self.audioContentView.dataArray) {
            if ([userModel.Uid isEqualToString:uid]) {
                [self.audioContentView.dataArray removeObject:userModel];
                break;
            }
        }
    }
    
    [self.audioContentView refreshView];
    [super didUserLeave:userList];
}


// 用户取消连麦（主播取消连麦）
- (void)didInviteRefuseWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    [super didInviteRefuseWithUid:uid roomid:roomid];
    if (!self.isAnchor) {
        [self changeLinkMicBtnStatus];
    }
}

//用户收到拒绝连麦的请求
- (void)didBeInviteCancelWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    [super didBeInviteCancelWithUid:uid roomid:roomid];
    if (!self.isAnchor) {
        [self changeLinkMicBtnStatus];
    }
}

// 连麦超时
- (void)didInviteTimeOutWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    [super didInviteTimeOutWithUid:uid roomid:roomid];
    if (!self.isAnchor) {
        [self changeLinkMicBtnStatus];
    }
}

// 用户连麦中
- (void)didInviteRunningWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    [super didInviteRunningWithUid:uid roomid:roomid];
    if (!self.isAnchor) {
        [self changeLinkMicBtnStatus];
    }
}


/// 某人打开麦克风
/// @param uid 用户 id
- (void)didMicOnWithUid:(NSString *)uid
{
    [self.audioMicStateController handleDidMicOnWithUid:uid];
}


/// 某人关闭麦克风
/// @param uid 用户 id
- (void)didMicOffWithUid:(NSString *)uid
{
    [self.audioMicStateController handleDidMicOffWithUid:uid];
}


/// 主播关闭本人的麦克风
- (void)didMicOffSelfByAnchor
{
    [self.audioMicStateController handleDidMicOffSelfByAnchor];
}


/// 主播打开本人的麦克风
- (void)didMicOnSelfByAnchor
{
    [self.audioMicStateController handleDidMicOnSelfByAnchor];
}


/// 主播打开其他人麦克风
/// @param uid 用户 id
- (void)didMicOnByAnchorWith:(NSString *)uid
{
    [self.audioMicStateController handleDidMicOnByAnchorWith:uid];
}


/// 主播关闭其他人麦克风
/// @param uid 用户 id
- (void)didMicOffByAnchorWith:(NSString *)uid
{
    [self.audioMicStateController handleDidMicOffByAnchorWith:uid];
}

#pragma mark -private
/**显示变声视图*/
- (void)showAudioWhine
{
    self.whineView.hidden = NO;
    self.whineView.transform = CGAffineTransformMakeTranslation(0, - SCREEN_HEIGHT);
    
}
/**隐藏变声视图*/
- (void)hidenWhineView
{
    self.whineView.hidden = YES;
    self.whineView.transform = CGAffineTransformIdentity;
    
}

/**
 
 隐藏变声
 */
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self hidenWhineView];
    
}
/**上麦 下麦改变底部工具栏的静麦和变声按钮的显示和隐藏*/
- (void)changeLinkMicBtnStatus
{
    self.linkMricButton.selected = NO;
    self.linkMricButton.userInteractionEnabled = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeAudioToolButtonState object:@"NO"];
}
@end
