//
//  VideoLiveViewController.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/2.
//  Copyright © 2020 sy. All rights reserved.
//

#import "VideoLiveViewController.h"
#import "LiveBGView.h"

@interface VideoLiveViewController () <LiveBGDelegate>

@property(nonatomic, strong) UIButton *hungUpButton;//主播挂断按钮

@end

@implementation VideoLiveViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}
- (LiveType)liveType
{
    return LiveTypeVideo;
}

- (UIButton *)hungUpButton
{
    if (!_hungUpButton) {
        _hungUpButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.view insertSubview:_hungUpButton aboveSubview:self.talkTableView];
        [_hungUpButton setTitle:NSLocalizedString(@"Video_Disconnect", nil) forState:UIControlStateNormal];// Disconnect
        CGFloat wh =[NSLocalizedString(@"Video_Disconnect", nil) boundingRectWithSize:CGSizeMake(1000, 13) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont fontWithName:FONT_Regular size:12.0f]} context:nil].size.width;
        [_hungUpButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-12);
            make.top.mas_equalTo(LIVE_BG_VIEW_SMALL_HEIGHT.longLongValue + LIVE_BG_VIEW_SMALL_TOP - 25);
            make.size.mas_equalTo(CGSizeMake(wh > 46 ? wh + 5 : 46, 20));
        }];
        [_hungUpButton addTarget:self action:@selector(hungUpAction) forControlEvents:UIControlEventTouchUpInside];
        
        [_hungUpButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _hungUpButton.titleLabel.font = [UIFont fontWithName:FONT_Regular size:12.0f];
        _hungUpButton.layer.cornerRadius = 10;
        _hungUpButton.layer.masksToBounds = YES;
        UIImage *bgImage = [UIImage yy_gradientImageWithBounds:CGRectMake(0,0,46,20) andColors:@[[UIColor colorWithRed:23/255.0 green:202/255.0 blue:205/255.0 alpha:1.0],[UIColor colorWithRed:1/255.0 green:220/255.0 blue:149/255.0 alpha:1.0]] andGradientType:GradientDirectionLeftToRight];
        [_hungUpButton setBackgroundImage:bgImage forState:UIControlStateNormal];
        _hungUpButton.hidden = YES;
    }
    return _hungUpButton;
}

//挂断
- (void)hungUpAction
{
    WeakSelf
    [self.liveBG disconnectWithUid:self.currentVideoMircUid roomid:self.currentVideoMircRoomId complete:^(NSError * _Nullable error) {
        weakSelf.hungUpButton.hidden = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeToolButtonState object:@{@"uid":@"",@"state":@"OFF"}];
    }];
}

//刷新挂断按钮状态
- (void)refreshHungUpButtonState:(NSNotification *)notify
{
    if (self.isAnchor) {
        NSString *state = notify.object;
        if ([state isEqualToString:@"1"]) {
            self.hungUpButton.hidden = NO;
        } else {
            self.hungUpButton.hidden = YES;
        }
    }
}

- (void)getLinkUserInfoWithConfig:(LiveDefaultConfig *)config
{
    // add by LanPZzzz
    // 如果是视频房
    // 如果连麦用户是 PK 主播，用户信息需要放入到其他缓存上
    if (config.anchroSecondRoomId && ![config.anchroSecondRoomId isEqualToString:@""] && ![config.anchroSecondRoomId isEqualToString:self.liveRoomInfo.RoomId]) {
        YYLogDebug(@"[MouseLive-View] getLinkUserInfoWithConfig is PK anchor, uid:%@, roomid:%@", config.anchroSecondUid, config.anchroSecondRoomId);
        [self.userInfoList getOtherRoomUserInfoWithUid:config.anchroSecondUid complete:^(LiveUserModel * _Nonnull m) {
            YYLogDebug(@"[MouseLive-View] getLinkUserInfoWithConfig getOtherRoomUserInfoWithUid");
        }];
    }
}

#pragma mark - 进入视频房间
- (void)startUpLiveWithMircUserListArray:(NSArray<LiveUserModel *> *)mircUserListArray
{
    WeakSelf
    if (mircUserListArray.count) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Uid == %@", self.liveRoomInfo.ROwner.Uid];
        NSArray *filteredArray = [mircUserListArray filteredArrayUsingPredicate:predicate];
        if (filteredArray.count > 0) {
            LiveUserModel *mircUser = filteredArray.lastObject;
            //当前有正在连麦的观众
            if (![mircUser.LinkUid isEqualToString:@"0"] && ![mircUser.LinkRoomId isEqualToString:@"0"]) {
                //设置底部工具栏  自己不可以连麦
                weakSelf.toolView.mircEnable = NO;
                weakSelf.toolView.localRuningMirc = NO;
                [weakSelf.toolView refreshVideoToolView];
                LiveDefaultConfig *config = [[LiveDefaultConfig alloc]init];
                config.localUid = LoginUserUidString;
                config.ownerRoomId = weakSelf.liveRoomInfo.RoomId;
                config.anchroMainUid = mircUser.Uid;
                config.anchroMainRoomId = weakSelf.liveRoomInfo.RoomId;
                config.anchroSecondUid = mircUser.LinkUid;
                config.anchroSecondRoomId = mircUser.LinkRoomId;
                [weakSelf.liveBG joinRoomWithConfig:config pushUrl:nil];
                
                [weakSelf getLinkUserInfoWithConfig:config];
            } else {
                //自己首次开播或当前无连麦观众
                if (!weakSelf.isAnchor) {
                    weakSelf.toolView.mircEnable = YES;
                    weakSelf.toolView.localRuningMirc = NO;
                    [weakSelf.toolView refreshVideoToolView];
                }
                
                weakSelf.config.ownerRoomId = weakSelf.liveRoomInfo.RoomId;
                [weakSelf.liveBG joinRoomWithConfig:weakSelf.config pushUrl:nil];
                
                
            }
        }
    } else {
        //房间里面没人也一样进来
        //自己首次开播或当前无连麦观众
        if (!weakSelf.isAnchor) {
            weakSelf.toolView.mircEnable = YES;
            weakSelf.toolView.localRuningMirc = NO;
            [weakSelf.toolView refreshVideoToolView];
        }
        
        weakSelf.config.ownerRoomId = weakSelf.liveRoomInfo.RoomId;
        [weakSelf.liveBG joinRoomWithConfig:weakSelf.config pushUrl:nil];
    }
}

#pragma mark - LiveBGDelegate
- (void)didShowCanvasWith:(NSString *)leftUid rightUid:(NSString *)rightUid
{
    [super didShowCanvasWith:leftUid rightUid:rightUid];
    if (self.isAnchor) {
        if (rightUid.length) {
            self.hungUpButton.hidden = NO;
        } else {
            self.hungUpButton.hidden = YES;
            //对方主播断网杀进程
            self.config.anchroSecondUid = @"";
            self.config.anchroSecondRoomId = @"";
        }
    }
}

- (void)didChatJoinWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    if (![roomid isEqualToString:self.liveRoomInfo.RoomId]) {
        // 如果不是自己的房间，就要保存其他房间的用户信息
        [self.userInfoList getOtherRoomUserInfoWithUid:uid complete:^(LiveUserModel * _Nonnull u) {
            YYLogDebug(@"[MouseLive-App] didChatJoinWithUid roomid:%@", roomid);
        }];
    }
    if (self.isAnchor) {
        self.currentVideoMircUid = uid;
        self.currentVideoMircRoomId = roomid;
        self.hungUpButton.hidden = NO;
    }
    //隐藏连接中状态条
    [self hidenlinkHud];
    
    //改变底部状态栏
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeToolButtonState object:@{@"uid":uid ,@"state":@"ON"}];
}

// 连麦用户离开 -- 新加 -- 把断开按钮消失掉 音聊人员下位
- (void)didChatLeaveWithUid:(NSString *)uid
{
    if ([uid isEqualToString:self.currentVideoMircUid]) {
         if (self.hungUpButton.hidden == NO) {
             self.hungUpButton.hidden = YES;
            
              YYLogDebug(@"[MouseLive VideoLiveViewController] hungupButton hidden didChatLeaveWithUid %@ currentMircUid %@",uid, self.currentVideoMircUid);
           }
    }
    //改变底部状态栏  自己可以连麦了
    //添加currentMirUid 作用当上一个连麦用户离开时，不要更新当前连麦用户的底部按钮状态
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeToolButtonState object:@{@"uid":uid ,@"currentMirUid":self.currentVideoMircUid ? self.currentVideoMircUid :@"",@"state":@"OFF"}];
    if (!self.isAnchor) {
        // 如果不是主播，需要释放资源
        [self destroyEffects];
    }
}


// 用户取消连麦（主播取消连麦）
- (void)didInviteRefuseWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    [super didInviteRefuseWithUid:uid roomid:roomid];
    self.hungUpButton.hidden = YES;
}

//用户收到拒绝连麦的请求
- (void)didBeInviteCancelWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    [super didBeInviteCancelWithUid:uid roomid:roomid];
    self.hungUpButton.hidden = YES;
}

// 连麦超时
- (void)didInviteTimeOutWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    [super didInviteTimeOutWithUid:uid roomid:roomid];
    self.hungUpButton.hidden = YES;
}

// 用户连麦中
- (void)didInviteRunningWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    //观众端显示
    [super didInviteRunningWithUid:uid roomid:roomid];
    self.hungUpButton.hidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}
@end
