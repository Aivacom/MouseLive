//
//  BaseLiveViewController.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/18.
//  Copyright © 2020 sy. All rights reserved.
//

#import "BaseLiveViewController.h"
#import "LiveAnchorView.h"
#import "LivePublicTalkView.h"
#import "LiveCodeRateView.h"
#import "LiveBottomSettingView.h"
#import "GearPickView.h"
#import "AudioContentView.h"
#import "PublishViewController.h"
#import "ApplyAlertView.h"
#import "LiveUserView.h"
#import "LiveUserListView.h"
#import "IQKeyboardManager.h"
#import "SYHummerManager.h"
#import "SYThunderManagerNew.h"
#import "MBProgressHUD+HM.h"
#import "StartViewController.h"
#import "KeyString.h"
#import "PeopleHeader.h"
#import "LivePresenter.h"
#import "LiveBGView.h"
#import "SYPlayer.h"
#import "SYAppId.h"
#import "BaseLiveViewController+SYAddEffect.h"
#import "SYThunderEvent.h"
#if USE_BEATIFY
#import "SYEffectView.h"
#endif


@interface BaseLiveViewController()<LiveBGDelegate,LivePresenterDelegate,UITextFieldDelegate,SYHummerManagerObserver,SYPlayerDelegate,UIGestureRecognizerDelegate
#if USE_BEATIFY
,ThunderVideoCaptureFrameObserver, SYEffectViewDelegate>
#else
>
#endif
/**显示码流*/
@property (nonatomic, strong) LiveCodeRateView *leftCodeRateView;
/**显示码流*/
@property (nonatomic, strong) LiveCodeRateView *rightCodeRateView;
/**显示码流*/
@property (nonatomic, strong) LiveCodeRateView *bottomCodeRateView;
/**底部设置栏*/
@property (nonatomic, strong)LiveBottomSettingView *settingView;
//档位选择pickview
@property (nonatomic, strong)GearPickView *gearPickView;
//申请连麦
@property (nonatomic, strong)ApplyAlertView *applyView;
/**观众信息*/
@property (nonatomic, strong)LiveUserView *userView;
/**观众列表页*/
@property (nonatomic, strong)LiveUserListView *userListView;
/**连麦者的头像视图*/
@property (nullable, nonatomic, strong)PeopleHeader *headerView;
/** 直播开始前的占位图片 */
@property(nonatomic, strong) UIImageView *placeHolderView;
/**聊天输入框*/
@property(nonatomic, strong)UITextField *chatTextField;
/**连接中状态条*/
@property(nonatomic, strong) UIView *linkHUD;

@property(nonatomic, strong) UILabel *wordLabel;
/**码率左uid*/
@property(nonatomic, copy)NSString *codeLeftUid;
/**码率右uid*/
@property(nonatomic, copy)NSString *codeRightUid;
/**聊天ID*/
@property(nonatomic, copy) NSString *chatId;
/**15s计时器*/
@property (nonatomic, strong) dispatch_source_t timer;

@property(nonatomic, assign)  BOOL isFrontCamera;

@property(nonatomic, assign)  BOOL isMirror;

@property(nonatomic, strong)  SYPlayer *player;

@property(nonatomic, strong) UIAlertController *netAlert;

@property(nonatomic, assign) BOOL isVisible;//弹出框是否已经显示了

@property(nonatomic, assign) BOOL shouldReConnected;//是否需要重连

//内容view
@property (nonatomic, strong) UIView *bgContentView;
#if USE_BEATIFY
@property (nonatomic, strong) SYEffectView *effectView;
#endif

@property (nonatomic, strong) NSMutableArray* taskArray;

@property (nonatomic, strong) UIView *netAlertView;


@end

@implementation BaseLiveViewController

#pragma mark -- get / set
- (NSMutableArray *)taskArray
{
    if (!_taskArray) {
        _taskArray = [[NSMutableArray alloc] init];
    }
    return _taskArray;
}

#pragma mark - life cycle

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.chatTextField removeFromSuperview];
    self.chatTextField = nil;
    self.timer = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //关闭自动键盘
    [IQKeyboardManager sharedManager].enable = NO;
    [IQKeyboardManager sharedManager].enableAutoToolbar = NO;
    [IQKeyboardManager sharedManager].shouldResignOnTouchOutside = YES;
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

//停止倒计时
- (void)stopTimer
{
    YYLogError(@"[MouseLive-BaseLiveViewController] stopTimer  start");

    if (self.timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
    
    YYLogError(@"[MouseLive-BaseLiveViewController] stopTimer  end");

}


// 开启倒计时效果
- (void)startTimer
{
    
    if (self.timer) {
        dispatch_cancel(self.timer);
        self.timer = nil;
    }
    WeakSelf
    __block NSInteger time = 15; //倒计时时间
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    dispatch_source_set_timer(self.timer ,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
    
    dispatch_source_set_event_handler(self.timer , ^{
        
        if (time <= 0) { //倒计时结束，关闭
            
            dispatch_source_cancel(weakSelf.timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //设置按钮的样式
                weakSelf.wordLabel.text = [NSString stringWithFormat:@"%@(15s)",NSLocalizedString(@"Connecting...",nil)];
                
            });
            
        } else {
            
            int seconds = time % 60;
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //设置按钮显示读秒效果
                weakSelf.wordLabel.text = [NSString stringWithFormat:@"%@(%.2ds)", NSLocalizedString(@"Connecting...",nil),seconds];
                
            });
            time--;
        }
    });
    dispatch_resume(self.timer);
}


- (UIView *)linkHUD
{
    if (!_linkHUD) {
        _linkHUD = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        
        [self.view addSubview:_linkHUD];
        
        self.wordLabel = [[UILabel alloc]init];
        
        [_linkHUD addSubview:self.wordLabel];
        
        [self.wordLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(0);
        }];
        
        self.wordLabel.text = [NSString stringWithFormat:@"%@(15s)",NSLocalizedString(@"Connecting...",nil)];
        
        self.wordLabel.textColor = [UIColor whiteColor];
        
        self.wordLabel.textAlignment = NSTextAlignmentCenter;
        
        _linkHUD.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        
        self.wordLabel.layer.cornerRadius = 4.0f;
        
        self.wordLabel.layer.masksToBounds = YES;
    }
    return _linkHUD;
}

- (UITextField *)chatTextField
{
    if (!_chatTextField) {
        _chatTextField = [[UITextField alloc]initWithFrame:CGRectMake(6,SCREEN_HEIGHT - TabbarSafeBottomMargin - Live_Tool_H,88 * SCREEN_WIDTH/360, Live_Tool_H)];
        _chatTextField.delegate = self;
        _chatTextField.backgroundColor = [UIColor clearColor];
        _chatTextField.returnKeyType = UIReturnKeyDone;
        [self.view addSubview:_chatTextField];
    }
    return _chatTextField;
}

- (UIView *)netAlertView
{
    if (!_netAlertView) {
        _netAlertView = [[UIView alloc]initWithFrame:self.view.bounds];
        [MBProgressHUD yy_showMessage:NSLocalizedString(@"Reconnecting to internet, please wait.", nil) toView:_netAlertView];
        [self.view addSubview:_netAlertView];
    }
    return _netAlertView;
}

#pragma mark- 初始化方法
- (instancetype) initWithAnchor:(BOOL)isAnchor config:(LiveDefaultConfig *)config pushMode:(PublishMode)pushModel
{
    if (self = [super init]) {
        self.isAnchor = isAnchor;
        self.shouldJion = YES;
        self.shouldReConnected = NO;
        self.config = config;
        self.publishMode = pushModel;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.bgContentView.hidden = NO;
    [[SYHummerManager sharedManager] addHummerObserver:self];
    [LivePresenter shareInstance].delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sendBackgroundMsg)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    if (self.liveType == LiveTypeAudio) {
        self.liveBG.bgView.layer.contents = (id)[UIImage imageNamed:@"bg_color.png"].CGImage;
        //添加音频图
        self.audioContentView.hidden = NO;
        self.anchorView.hidden = YES;
    } else {
        self.audioContentView.hidden = YES;
        //主播信息
        self.anchorView.hidden = NO;
        
#if USE_BEATIFY
        [self registerVideoCaptureFrameObserver];
#endif
    }
    //档位选择
    self.gearPickView.hidden = YES;
    //底部工具栏
    self.toolView.hidden = NO;
    //设置菜单栏
    self.settingView.hidden = YES;
    if (self.isAnchor) {
        [self hummerCreateChatRoom];
    } else {
        //观众进入房间
        [self audiencejoinRoom];
    }
    [self.talkTableView reloadData];
    self.isFrontCamera = YES;
    self.isMirror = NO;
    
    [self.view addSubview:self.chatTextField];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingGear:) name:kNotifySettingGear object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refreshHungUpButtonState:) name:kNotifyshowHungUpButton object:nil];
    
#if USE_BEATIFY
    
    [self addEffectView];
    
#endif
   //临时解决 刚进入直播 等待页面启动起来才能操作页面
    if (self.publishMode == PUBLISH_STREAM_RTC || self.isAnchor) {
        MBProgressHUD *progessView = [MBProgressHUD yy_showMessage:nil toView:self.view];
        progessView.tag = 1000;
        [NSTimer timerWithTimeInterval:10 repeats:NO block:^(NSTimer * _Nonnull timer) {
            if ([MBProgressHUD HUDForView:self.view].tag == 1000) {
                [MBProgressHUD yy_hideHUDForView:self.view];
            }
        }];
    }
}

//子类实现
- (void)refreshHungUpButtonState:(NSNotification *)notify
{
    
}

#pragma mark -应用进入后台
- (void)sendBackgroundMsg
{
    NSLog(@"sendBackgroundMsg");
    if (LOCAL_USER.Uid == self.liveRoomInfo.ROwner.Uid) {
        NSDictionary *messageDict = @{
            @"NickName":LOCAL_USER.NickName,
            @"Uid" :LOCAL_USER.Uid,
            @"message":NSLocalizedString(@"Owner will be right back.", @"主播离开一下下,很快回来哦"),
            @"type" :@"Notice"
        };
        NSMutableString *sendString = [[NSMutableString alloc]initWithString:[NSString yy_stringFromJsonObject:messageDict]];
        WeakSelf
        [[SYHummerManager sharedManager] sendBroadcastMessage:sendString completionHandler:^(NSError * _Nullable error) {
            if (!error) {
                [weakSelf.talkTableView.dataArray addObject:[weakSelf fectoryChatMessageWithMessageString:sendString isjoinOrLeave:NO]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.talkTableView refreshTalkView];
                });
                YYLogError(@"[MouseLive-BaseLiveViewController] sendBackgroundMsg  success");

            } else {
                YYLogError(@"[MouseLive-BaseLiveViewController] sendBackgroundMsg  error");

            }
        }];
    }
    
}

#pragma mark -观众进入房间

- (void)audiencejoinRoom
{
    NSDictionary *params = @{
        kRoomId:@(self.config.anchroMainRoomId.longLongValue),
        kUid:@([self.config.localUid integerValue]),
        kRType: @(self.liveType == LiveTypeVideo ? 1 : 2),
    };
    [[LivePresenter shareInstance]fetchGetchatIdWithParams:params];
}

#pragma mark -主播创建聊天室
- (void)hummerCreateChatRoom
{
    self.config.ownerRoomId = self.liveRoomInfo.RoomId;
    WeakSelf
    [[SYHummerManager sharedManager] createChatRoomWithCompletionHandler:^(NSString * _Nullable roomId, NSError * _Nullable error) {
        if (!error) {
            YYLogDebug(@"[MouseLive-BaseLiveViewController] createChatRoomWithCompletionHandler success");
            //启动成功
            weakSelf.chatId = roomId;
            NSDictionary *params = @{
                kRoomId:@([weakSelf.config.ownerRoomId integerValue]),
                kUid:@([weakSelf.config.localUid integerValue]),
                kRChatId:@([weakSelf.chatId integerValue]),
                kRType: @(weakSelf.liveType == LiveTypeVideo ? 1 : 2),
            };
            [[LivePresenter shareInstance] fetchSetchatIdWithParams:params];
        } else {
            YYLogError(@"[MouseLive-BaseLiveViewController] createChatRoomWithCompletionHandler error start");

            [weakSelf quit];
            
            YYLogError(@"[MouseLive-BaseLiveViewController] createChatRoomWithCompletionHandler error stop");

        }
    }];
}

#pragma mark - 懒加载


- (UIView *)bgContentView
{
    if (!_bgContentView) {
        _bgContentView = [[UIView alloc] initWithFrame:self.view.frame];
        _bgContentView.backgroundColor = UIColor.blackColor;
        [self.view insertSubview:_bgContentView atIndex:0];
        
//        if (self.publishMode ==  PUBLISH_STREAM_CDN) {
//            if (!self.isAnchor) {
//                _bgContentView = self.player.playView;
//            } else {
//                _bgContentView = self.liveBG.bgView;
//            }
//
//        } else if (self.publishMode ==  PUBLISH_STREAM_RTC) {
//            _bgContentView = self.liveBG.bgView;
//        }
    }
    return _bgContentView;
}

#pragma mark - 主播信息


- (PeopleHeader *)headerView
{
    if (!_headerView) {
        _headerView = [PeopleHeader shareInstance];
        [self.view insertSubview:_headerView aboveSubview:self.bgContentView];
        _headerView.hidden = YES;
        [_headerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(LIVE_BG_VIEW_SMALL_TOP + 2);
            make.left.mas_equalTo(SCREEN_WIDTH/2);
            make.size.mas_equalTo(CGSizeMake(60, 40));
        }];
    }
    return _headerView;
}

- (LiveAnchorView *)anchorView
{
    if (!_anchorView) {
        LiveAnchorView *anchorView = [LiveAnchorView liveAnchorView];
        [self.view insertSubview:anchorView aboveSubview:self.bgContentView];
        [anchorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(@0);
            make.height.equalTo(@(Anchor_H));
            make.top.equalTo(@StatusBarHeight);
        }];
        WeakSelf
        anchorView.quitBlock = ^{
            YYLogDebug(@"[MouseLive-BaseLiveViewController] 用户主动关闭房间");

            [weakSelf quit];
        };
        
        anchorView.iconClickBlock = ^(IconClikType type,BOOL selected) {
            
            [weakSelf showUserListView];
            [weakSelf.userListView refreshViewWithType:weakSelf.liveType needAnchor:NO isAnchor:weakSelf.isAnchor config:weakSelf.config userInfoList:weakSelf.userInfoList];
            
            
        };
        anchorView.pushMode = (PushModeType)self.publishMode;
        _anchorView = anchorView;
    }
    return _anchorView;
}

- (void)sendSetRoomMic:(BOOL)enable
{
    NSDictionary *params =  @{
        kMicEnable:@(enable),
        kRoomId:@(self.liveRoomInfo.RoomId.longLongValue),
        kRType:@(self.liveType),
    };
    
    WeakSelf
    int taskId = [HttpService sy_httpRequestWithType:SYHttpRequestKeyType_SetRoomMic params:params success:^(int taskId, id  _Nullable respObjc) {
        [weakSelf.taskArray removeObject:@(taskId)];
        YYLogError(@"发送房间全部开闭麦 -- param:%@， 错误信息:%@", params, [NSString stringWithFormat:@"%@",respObjc[kMsg]]);
    } failure:^(int taskId, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
        [weakSelf.taskArray removeObject:@(taskId)];
        YYLogError(@"发送房间全部开闭麦失败");
    }];
    [self.taskArray addObject:@(taskId)];
}

#pragma mark -音聊
- (AudioContentView *)audioContentView
{
    if (!_audioContentView) {
        _audioContentView = [AudioContentView audioContentView];
        [self.view insertSubview:_audioContentView aboveSubview:self.bgContentView];
        [_audioContentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.top.mas_equalTo(0);
            make.bottom.mas_equalTo(self.toolView.mas_top);
        }];
        WeakSelf
        //退出
        _audioContentView.quitBlock = ^{
            
            YYLogDebug(@"[MouseLive-BaseLiveViewController] 用户主动关闭房间");

            [weakSelf quit];
        };
        _audioContentView.iconClickBlock = ^(BOOL selected) {            //人员列表显示
            [weakSelf showUserListView];
            [weakSelf.userListView refreshViewWithType:weakSelf.liveType needAnchor:NO isAnchor:weakSelf.isAnchor config:weakSelf.config userInfoList:weakSelf.userInfoList];
        };
        //音乐播放
        _audioContentView.musicBlock = ^(BOOL isOn) {
            if (isOn) {
                [[SYThunderManagerNew sharedManager] resumeAudioFile];
            } else {
                //暂停bo
                [[SYThunderManagerNew sharedManager] pauseAudioFile];
                
            }
        };
        _audioContentView.allMicOffBlock = ^(BOOL off) {
            [[SYHummerManager sharedManager] sendAllMicOffWithOff:off completionHandler:^(NSError * _Nullable error) {
                if (!error) {
                    [weakSelf sendSetRoomMic:!off];
                } else {
                    YYLogError(@"sendAllMicOffWithOff error:%@", error);
                }
            }];
        };
        
        _audioContentView.closeOtherMicBlock = ^(LiveUserModel *model) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                YYLogDebug(@"[MouseLive-BaseLiveViewController] 主播关闭 %@ 的麦克风",model.NickName);
                
                weakSelf.userView.type = LiveTypeAudio;
                
                [weakSelf showUserViewWithModel:model];
            });
        };
        
    }
    return _audioContentView;
}

#pragma mark - 用户列表 1主播pk 2用户弹出框
- (LiveUserListView *)userListView
{
    if (!_userListView) {
        _userListView = [LiveUserListView liveUserListView];
        [self.view insertSubview:_userListView aboveSubview:self.toolView];
        [_userListView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(0);
            make.top.mas_equalTo(SCREEN_HEIGHT);
            make.height.mas_equalTo(SCREEN_HEIGHT);
            make.width.mas_equalTo(SCREEN_WIDTH);
        }];
        
        WeakSelf
        _userListView.clickBlock = ^(BOOL isAnchor, id  _Nonnull model) {
            if (weakSelf.isAnchor) {
                [weakSelf hidenUserListView];
            }
            if (isAnchor) {
                //主播pk
                LiveAnchorModel *m = (LiveAnchorModel *)model;
                [weakSelf.liveBG connectWithUid:m.AId roomid:m.ARoom complete:^(NSError * _Nullable error) {
                    // by zhangjianping
                    if (!error) {
                        weakSelf.currentVideoMircUid = m.AId;
                        weakSelf.currentVideoMircRoomId = m.ARoom;
                        [weakSelf showLinkHud];
                    }
                }];
            } else {
                //主播和管理员可以进行用户管理
                if (weakSelf.isAnchor) {
                    weakSelf.userView.isAnchor = YES;
                    weakSelf.userView.isAdmin = NO;
                    weakSelf.userView.type = LiveTypeVideo;
                    //主播点击自己不能弹框
                    if ([model isKindOfClass:[LiveUserModel class]]) {
                        LiveUserModel *userModel = (LiveUserModel *)model;
                        if (!userModel.isAnchor) {
                            [weakSelf showUserViewWithModel:model];
                        } else {
                            [weakSelf hiddenUserView];
                        }
                    }
                } else {
                    //管理员或用户点击
                    [weakSelf setModelParam:model];
                }
            }
        };
        
        _userListView.allMuteBlock = ^(BOOL mute) {
            // 全部禁言
            [[SYHummerManager sharedManager] sendAllMutedWithMuted:mute completionHandler:^(NSError * _Nullable error) {
                if (error) {
                   YYLogDebug(@"[MouseLive-BaseLiveViewController] 全部禁言 error:%@", error);
                }
            }];
        };
    }
    return _userListView;
}

- (void)setModelParam:(LiveUserModel *)model
{
    if ([SYHummerManager sharedManager].isAdmin) {
        if (![model.Uid isEqualToString:self.config.anchroMainUid]) {
            // 如果要点击的不能是主播+管理员
            if (!model.isAdmin) {
                self.userView.isAdmin = YES;
                self.userView.isAnchor = NO;
                self.userView.type = LiveTypeVideo;
                [self showUserViewWithModel:model];
                [self hidenUserListView];
            } else {
                [self hiddenUserView];
            }
        }
    }
}

#pragma mark - 用户弹出框 禁言 踢出 升管
- (LiveUserView *)userView
{
    if (!_userView) {
        _userView = [LiveUserView userView];
        [self.view insertSubview:_userView aboveSubview: self.liveType == LiveTypeVideo ? self.bgContentView:self.audioContentView];
        _userView.hidden = YES;
        [_userView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(@0);
            make.centerY.equalTo(@-100);
            make.width.equalTo(@(USERVIEW_W));
            make.height.equalTo(@(USERVIEW_H));
        }];
        WeakSelf
        [_userView setCloseBlock:^{
            [weakSelf hiddenUserView];
        }];
        [_userView setManagementBlock:^(LiveUserModel * _Nullable userModel, ManagementUserType type,UIButton *sender) {
            switch (type) {
                case ManagementUserTypeAddAdmin: {//升管
                    [[SYHummerManager sharedManager] addAdminWithUid:userModel.Uid completionHandler:^(NSError * _Nullable error) {
                        if (!error) {
                            userModel.isAdmin = YES;
                            [weakSelf.userInfoList setUserInfo:userModel];
                            [weakSelf hiddenUserView];
                        } else {
                            [MBProgressHUD yy_showError:error.domain];
                            YYLogDebug(@"[MouseLive-BaseLiveViewController] 升管 error:%@", error);
                        }
                    }];
                }
                    break;
                case ManagementUserTypeRemoveAdmin: {//降管
                    [[SYHummerManager sharedManager] removeAdminWithUid:userModel.Uid completionHandler:^(NSError * _Nullable error) {
                        if (!error) {
                            userModel.isAdmin = NO;
                            [weakSelf.userInfoList setUserInfo:userModel];
                            [weakSelf hiddenUserView];
                        } else {
                            [MBProgressHUD yy_showError:error.domain];
                        }
                    }];
                }
                    break;
                case ManagementUserTypeUnmute: {//解禁
                    [[SYHummerManager sharedManager] sendMutedWithUid:userModel.Uid muted:NO completionHandler:^(NSError * _Nullable error) {
                        if (!error) {
                            userModel.isMuted = NO;
                            [weakSelf.userInfoList setUserInfo:userModel];
                            [weakSelf hiddenUserView];
                        } else {
                            [MBProgressHUD yy_showError:error.domain];
                        }
                    }];
                }
                    break;
                case ManagementUserTypeMute: {//禁言
                    [[SYHummerManager sharedManager] sendMutedWithUid:userModel.Uid muted:YES completionHandler:^(NSError * _Nullable error) {
                        if (!error) {
                            userModel.isMuted = YES;
                            [weakSelf.userInfoList setUserInfo:userModel];
                            [weakSelf hiddenUserView];
                        } else {
                            [MBProgressHUD yy_showError:error.domain];
                        }
                    }];
                }
                    break;
                case ManagementUserTypeKick: {//踢出
                    [[SYHummerManager sharedManager] sendKickWithUid:userModel.Uid completionHandler:^(NSError * _Nullable error) {
                        if (!error) {
                            [weakSelf hiddenUserView];
                        } else {
                            [MBProgressHUD yy_showError:error.domain];
                        }
                    }];
                }
                    break;
                case ManagementUserTypeCloseMirc: {//闭麦
                    // 刷 uid 用户的状态
                    [weakSelf.liveBG micOffWithUid:userModel.Uid off:YES complete:^(NSError * _Nullable error) {
                        // by zhangjianping
                        if (!error) {
                            [weakSelf.audioMicStateController handleMicOffWithUid:userModel.Uid];
                        }
                    }];
                }
                    break;
                case ManagementUserTypeOpenMirc: {// 开麦
                    // 刷 uid 用户的状态
                    [weakSelf.liveBG micOffWithUid:userModel.Uid off:NO complete:^(NSError * _Nullable error) {
                        // by zhangjianping
                        if (!error) {
                            [weakSelf.audioMicStateController handleMicOnWithUid:userModel.Uid];
                        }
                    }];
                }
                    break;
                case ManagementUserTypeDownMirc: {//下麦
                    [weakSelf.liveBG disconnectWithUid:userModel.Uid roomid:weakSelf.config.ownerRoomId complete:^(NSError * _Nullable error) {
                        YYLogDebug(@"[MouseLive-BaseLiveViewController] ManagementUserTypeDownMirc");
                    }];
                }
                    break;
                default:
                    break;
            }
            [weakSelf hiddenUserView];
        }];
        
    }
    return _userView;
}

#pragma mark - 播放器

- (SYPlayer *)player
{
    if (!_player) {
        UIView *view = [[UIView alloc]initWithFrame:self.view.bounds];
        
        _player = [[SYPlayer alloc]initPlayerWirhUrl:self.url view:view delegate:self];
        
//        [self.bgContentView addSubview:view];
//        [self.bgContentView insertSubview:view atIndex:0];
    }
    return _player;
}
#pragma mark - 直播页面
- (LiveBG *)liveBG
{
    if (!_liveBG) {
        UIView *view = [[UIView alloc]initWithFrame:self.view.bounds];
        _liveBG = [[LiveBG alloc] initWithView:view anchor:self.isAnchor delegate:self limit:self.liveType == LiveTypeVideo ? 1 : 8 haveVideo:self.liveType == LiveTypeVideo ? YES : NO config:self.config];
//        [self.bgContentView addSubview:view];
        [self.bgContentView insertSubview:view atIndex:0];
        self.audioMicStateController.liveBG = _liveBG;
    }
    return _liveBG;
}

#pragma mark - 同意   拒绝连麦
- (ApplyAlertView *)applyView
{
    if (!_applyView) {
        _applyView = [ApplyAlertView applyAlertView];
        [self.view insertSubview:_applyView aboveSubview:self.talkTableView];
        _applyView.hidden = YES;
        _applyView.livetype = self.liveType;
        [_applyView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(@0);
            make.centerY.equalTo(@0);
            make.width.equalTo(@(SCREEN_WIDTH));
            make.height.equalTo(@(SCREEN_HEIGHT));
        }];
        WeakSelf
        _applyView.applyBlock = ^(ApplyActionType type, NSString *uid,UIButton *sender) {
            switch (type) {
                case ApplyActionTypeAgree: {//同意连麦
                    [weakSelf.liveBG acceptWithUid:uid complete:^(NSError * _Nullable error) {
                        // by zhangjianping
                        if (!error) {
                            [weakSelf hiddenMircApplay];
                            weakSelf.currentVideoMircUid = uid;
                            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyshowHungUpButton object:@"1"];
                        }
                    }];
                    
                }
                    break;
                case ApplyActionTypeReject: {//拒绝连麦
                    [weakSelf.liveBG refuseWithUid:uid complete:^(NSError * _Nullable error) {
                        // by zhangjianping
                        if (!error) {
                            [weakSelf hiddenMircApplay];
                            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyshowHungUpButton object:@"0"];
                        }
                    }];
                }
                    break;
                default:
                    break;
            }
            
        };
        
    }
    return _applyView;
}
#pragma mark - 清晰度档位
- (GearPickView *)gearPickView
{
    if (!_gearPickView) {
        _gearPickView = [GearPickView gearPickView];
        [self.view insertSubview:_gearPickView aboveSubview:self.toolView];
        [_gearPickView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(0);
            make.top.mas_equalTo(SCREEN_HEIGHT);
            make.height.mas_equalTo(Gear_H);
            make.width.mas_equalTo(SCREEN_WIDTH);
        }];
    }
    return _gearPickView;
}

#pragma mark - 设置弹出栏
- (LiveBottomSettingView *)settingView
{
    if (!_settingView) {
        _settingView = [LiveBottomSettingView bottomSettingView];
        [self.view insertSubview:_settingView aboveSubview:self.talkTableView];
        [_settingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(-8);
            make.top.mas_equalTo(SCREEN_HEIGHT);
            make.width.equalTo(@(Setting_W));
            make.height.equalTo(@(Setting_H));
        }];
        WeakSelf
        _settingView.settingBlock = ^(BottomSettingType type) {
            switch (type) {
                case BottomSettingTypeChangeCamera: {//切换摄像头
                    
                    weakSelf.isFrontCamera = !weakSelf.isFrontCamera;
                    [[SYThunderManagerNew sharedManager] switchFrontCamera:weakSelf.isFrontCamera];
                    break;
                }
                    
                case BottomSettingTypeMirroring: {//镜像
                    
                    weakSelf.isMirror = !weakSelf.isMirror;
                    [[SYThunderManagerNew sharedManager] switchMirror:weakSelf.isMirror];
                }
                    break;
                case BottomSettingTypeGear: {//档位
                    
                    [weakSelf showGearView];
                }
                    break;
                case BottomSettingTypeSkinCare:    //美颜
#if USE_BEATIFY
                    [weakSelf showEffectView];
#endif
                    break;
                default:
                    break;
            }
        };
        
    }
    return _settingView;
}

#pragma mark - 显示码率
- (LiveCodeRateView *)leftCodeRateView
{
    if (!_leftCodeRateView) {
        _leftCodeRateView = [LiveCodeRateView liveCodeRateView];
        [self.view insertSubview:_leftCodeRateView aboveSubview: self.liveType == LiveTypeVideo ? self.bgContentView:self.audioContentView];
        _leftCodeRateView.hidden = YES;
        WeakSelf
        [_leftCodeRateView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(weakSelf.bgContentView.mas_left).offset(8);
            make.top.equalTo(@((Anchor_H + StatusBarHeight + 8)));
            make.size.mas_equalTo(CGSizeMake(CodeView_W, CodeView_H));
        }];
        
    }
    return _leftCodeRateView;
}

- (LiveCodeRateView *)rightCodeRateView
{
    if (!_rightCodeRateView) {
        _rightCodeRateView = [LiveCodeRateView liveCodeRateView];
        [self.view insertSubview:_rightCodeRateView aboveSubview: self.liveType == LiveTypeVideo ? self.bgContentView : self.audioContentView];
        _rightCodeRateView.hidden = YES;
        WeakSelf
        [_rightCodeRateView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(weakSelf.bgContentView.mas_right).offset(-8);
            make.top.equalTo(@((Anchor_H + StatusBarHeight + 8)));
            make.size.mas_equalTo(CGSizeMake(CodeView_W, CodeView_H));
        }];
        
    }
    return _rightCodeRateView;
}

- (LiveCodeRateView *)bottomCodeRateView
{
    if (!_bottomCodeRateView) {
        _bottomCodeRateView = [LiveCodeRateView liveCodeRateView];
        [self.view insertSubview:_bottomCodeRateView aboveSubview:self.liveType == LiveTypeVideo ? self.bgContentView : self.audioContentView];
        _bottomCodeRateView.hidden = YES;
        WeakSelf
        [_bottomCodeRateView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(weakSelf.bgContentView.mas_right).offset(-8);
            make.size.mas_equalTo(CGSizeMake(CodeView_W, CodeView_H));
            if (weakSelf.liveType == LiveTypeVideo) {
                make.bottom.equalTo(weakSelf.toolView.mas_top).offset(-10);
                
            } else if (weakSelf.liveType == LiveTypeAudio) {
                if (weakSelf.isAnchor) {
                    make.bottom.equalTo(weakSelf.toolView.mas_top).offset(-10);
                    
                } else {
                    make.bottom.equalTo(weakSelf.toolView.mas_top).offset(-52);
                    
                }
            }
        }];
        
    }
    return _bottomCodeRateView;
}


#pragma mark - 麦克风控制
- (AudioMicStateController *)audioMicStateController
{
    if (!_audioMicStateController) {
        _audioMicStateController = [[AudioMicStateController alloc] init];
    }
    return _audioMicStateController;
}

#pragma mark - 公聊
- (LivePublicTalkView *)talkTableView
{
    if (!_talkTableView) {
        LivePublicTalkView *talkTableView = [[LivePublicTalkView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        talkTableView.backgroundColor = [UIColor clearColor];
        [self.view insertSubview:talkTableView aboveSubview: self.liveType == LiveTypeVideo ? self.bgContentView : self.audioContentView];
        WeakSelf
        [talkTableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.bottom.mas_equalTo(weakSelf.toolView.mas_top).offset(-10);
            make.height.equalTo(@(PubTalk_H));
        }];
        _talkTableView = talkTableView;
    }
    return _talkTableView;
}


#pragma mark - 底部工具栏 1主播闭麦 2主播pk/观众连麦 3设置 4反馈 5码率 6变声
- (LiveBottonToolView *)toolView
{
    WeakSelf
    if (!_toolView) {
        _toolView = [[LiveBottonToolView alloc] initWithAnchor:self.isAnchor liveType:self.liveType config:self.config];
        _toolView.anchorUid = self.config.anchroMainUid;
        [self.view insertSubview:_toolView aboveSubview:self.liveType == LiveTypeVideo ? self.bgContentView : self.audioContentView];
        _toolView.isCdnModel = self.publishMode == PUBLISH_STREAM_CDN ? YES :NO;
        [_toolView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(@0);
            make.bottom.equalTo(@(-TabbarSafeBottomMargin));
            make.height.equalTo(@(Live_Tool_H));
        }];
        [_toolView setClickToolBlock:^(LiveToolType type,BOOL selected) {
            [weakSelf hiddenMircApplay];
            [weakSelf hiddenUserView];
            switch (type) {
                case LiveToolTypeMicr: {//关闭麦克风
                    // 设置是自己关麦的
                    if (selected) {
                        [weakSelf.audioMicStateController handleMicOffBySelf];
                    }
                    else {
                        [weakSelf.audioMicStateController handleMicOnBySelf];
                    }
                }
                    break;
                case LiveToolTypeLinkmicr: {//主播pk 观众连麦
                    
                    if (!selected) {
                        if (weakSelf.isAnchor) {
                            [weakSelf anchorPK];
                        } else {
                            [weakSelf linkMicr];
                        }
                    }
                }
                    break;
                case LiveToolTypeSetting: {////设置
                    if (weakSelf.settingView.hidden) {
                        [weakSelf showSettingView];
                    } else {
                        [weakSelf hidenSettingView];
                        
                    }
                }
                    break;
                case LiveToolTypeFeedback: {//反馈
                    
                    
                    [weakSelf pushFeedBackViewController];
                    
                }
                    break;
                case LiveToolTypeCodeRate: {//码率
                    if (weakSelf.leftCodeRateView.hidden && weakSelf.rightCodeRateView.hidden && weakSelf.bottomCodeRateView.hidden) {
                        [weakSelf showCodeView];
                    } else {
                        [weakSelf hiddenCodeView];
                    }
                }
                    break;
                case LiveToolTypeAudioWhine: {//变声
                    [weakSelf showAudioWhine];
                }
                    break;
                    
                default:
                    break;
            }
        }];
    }
    return _toolView;
}

//主播pk
- (void)anchorPK
{
    // 显示z主播列表
    [self showUserListView];
    [self.userListView refreshViewWithType:self.liveType  needAnchor:YES isAnchor:self.isAnchor config:self.config userInfoList:self.userInfoList];
}
#pragma mark - 观众连麦

- (void)linkMicr
{
    [self.liveBG connectWithUid:self.config.anchroMainUid roomid:self.config.anchroMainRoomId complete:^(NSError * _Nullable error) {
        // by zhangjianping
        if (!error) {
            [self showLinkHud];
        }
    }];
}



#pragma mark- 刷新主播头像信息
- (void)refreshAnchorViewWithModel:(LiveRoomInfoModel *)model
{
    self.anchorView.roomInfoModel = model;
}

#pragma mark -  通知  待修改为枚举传值
- (void)settingGear:(NSNotification *)note
{
    int mode = 0;
    NSNumber *gear = note.object;
    switch (gear.intValue) {
        case 0:  //流畅
            mode = THUNDERPUBLISH_VIDEO_MODE_FLUENCY;
            break;
        case 1://标清
            mode = THUNDERPUBLISH_VIDEO_MODE_NORMAL;
            
            break;
        case 2: //高清
            mode = THUNDERPUBLISH_VIDEO_MODE_HIGHQULITY;
            break;
        case 3://超清
            mode = THUNDERPUBLISH_VIDEO_MODE_SUPERQULITY;
            break;
        case 4://蓝光
            mode = THUNDERPUBLISH_VIDEO_MODE_BLUERAY_2M;
            break;
        default:
            mode = THUNDERPUBLISH_VIDEO_MODE_FLUENCY;
            break;
    }
    [[SYThunderManagerNew sharedManager] switchPublishMode:mode];
    [self hidenGearView];
    
}
#pragma mark  - 键盘出现

- (void)keyboardWillShow:(NSNotification *)note
{
    NSValue *value = [note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect chatTextFieldFreame = self.chatTextField.frame;
    chatTextFieldFreame.origin.x = 0;
    chatTextFieldFreame.origin.y = SCREEN_HEIGHT - [value CGRectValue].size.height - 44;
    chatTextFieldFreame.size.width = SCREEN_WIDTH;
    chatTextFieldFreame.size.height = 44;
    self.chatTextField.frame = chatTextFieldFreame;
    self.chatTextField.backgroundColor = [UIColor whiteColor];
    self.chatTextField.placeholder = NSLocalizedString(@"Hey~", nil);
    CGRect keyBoardRect=[note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    WeakSelf
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.talkTableView.transform = CGAffineTransformMakeTranslation(0,keyBoardRect.size.height  + PubTalk_H - (Live_Tool_H + TabbarSafeBottomMargin + SCREEN_HEIGHT));
    }];
    
    
    
}

#pragma mark - 键盘消失
- (void)keyboardWillHide:(NSNotification *)note
{
    CGRect chatTextFieldFreame = self.chatTextField.frame;
    chatTextFieldFreame.origin.x = 6;
    chatTextFieldFreame.origin.y = SCREEN_HEIGHT - TabbarSafeBottomMargin - Live_Tool_H;
    chatTextFieldFreame.size.width = 88 * SCREEN_WIDTH/360;
    chatTextFieldFreame.size.height = Live_Tool_H;
    self.chatTextField.frame = chatTextFieldFreame;
    self.chatTextField.backgroundColor = [UIColor clearColor];
    self.chatTextField.placeholder = nil;
    WeakSelf
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.talkTableView.transform = CGAffineTransformIdentity;
    }];
}

#pragma mark - 退出直播

- (void)quit
{
    YYLogDebug(@"[MouseLive-BaseLiveViewController] quit entry");
    [self hideNetAlert];
    if (self.timer) {
        dispatch_cancel(self.timer);
        self.timer = nil;
    }
    
    //关闭音乐 变声恢复初始状态
    if (self.liveType == LiveTypeAudio) {
        
        [[SYThunderManagerNew sharedManager] closeAuidoFile];  // 这里有问题，最好不要写在这里，放到里面
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeWhineView object:@"YES"];
        
    }
    
    [self.audioMicStateController destory];
    
    [self.liveBG leaveRoom];
    [self.userInfoList destory];
    [[LivePresenter shareInstance] destory];
    YYLogDebug(@"[MouseLive-BaseLiveViewController] quit player stop");
    [self.player stop];
    YYLogDebug(@"[MouseLive-BaseLiveViewController] quit hummer leave");
    [[SYHummerManager sharedManager] leaveChatRoomWithCompletionHandler:^(NSError * _Nullable error) {
        YYLogDebug(@"离开主播房间%@",error);
    }];
    //关闭音乐 变声恢复初始状态
    if (self.liveType == LiveTypeAudio) {
        [[SYThunderManagerNew sharedManager] closeAuidoFile];  // 这里有问题，最好不要写在这里，放到里面
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeWhineView object:@"YES"];
    }
    [self.audioMicStateController destory];
    
#if USE_BEATIFY
    [self sy_destroyAllEffects];
#endif
    
    if (self.isResponsBackblock) {
        self.backBlock();
        YYLogDebug(@"[MouseLive-BaseLiveViewController] backBlock");
    } else {
        [self.navigationController popViewControllerAnimated:NO];
        YYLogDebug(@"[MouseLive-BaseLiveViewController] popViewControllerAnimated");
    }
    YYLogDebug(@"[MouseLive-BaseLiveViewController] quit exit");
}

#pragma mark - private

//弹出变声视图 音聊房实现
- (void)showAudioWhine
{
}

//显示连接中状态条 15s后自动消失
- (void)showLinkHud
{
    [self hiddenMircApplay];
    
    self.linkHUD.hidden = NO;
    
    [self startTimer];
    
}

//隐藏连接中状态条
- (void)hidenlinkHud
{
    self.linkHUD.hidden = YES;
    
    [self stopTimer];
}

// 显示网络状态，左右
/**
 1 没有right
 主播 下边
 观众 左边 下边
 */
/**
 2
 --本人是主播 左边 右边
 --观众
 1连麦 自己连麦 左边 右边
 自己没连麦 显示三个
 */
- (void)showCodeView
{
    BOOL leftHide = YES;
    BOOL rightHide = YES;
    BOOL bottomShow = YES;
    if (self.liveType == LiveTypeVideo) {
        self.leftCodeRateView.type = LiveTypeVideo;
        self.rightCodeRateView.type = LiveTypeVideo;
        self.bottomCodeRateView.type = LiveTypeVideo;
        leftHide = self.codeLeftUid.length == 0;
        rightHide = self.codeRightUid.length == 0;
        bottomShow =![self.codeRightUid isEqualToString:LoginUserUidString] && ![self.codeLeftUid isEqualToString:LoginUserUidString];
    } else if (self.liveType == LiveTypeAudio) {
        bottomShow = YES;
        self.bottomCodeRateView.type = LiveTypeAudio;
    }
    self.leftCodeRateView.hidden = leftHide;
    self.rightCodeRateView.hidden = rightHide;
    self.bottomCodeRateView.hidden = !bottomShow;
}

- (void)hiddenCodeView
{
    self.leftCodeRateView.hidden = YES;
    self.rightCodeRateView.hidden = YES;
    self.bottomCodeRateView.hidden = YES;
}

- (void)showGearView
{
    [self hidenSettingView];
    self.gearPickView.hidden = NO;
    WeakSelf
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.gearPickView.transform = CGAffineTransformMakeTranslation(0, - Gear_H);
        
    }];
}

- (void)hidenGearView
{
    self.gearPickView.hidden = YES;
    WeakSelf
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.gearPickView.transform = CGAffineTransformIdentity;
    }];
}

- (void)showSettingView
{
    self.settingView.hidden = NO;
    WeakSelf
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.settingView.transform = CGAffineTransformMakeTranslation(0, - Setting_H - Live_Tool_H - TabbarSafeBottomMargin - 8);
    }];
    
}

- (void)hidenSettingView
{
    self.settingView.hidden = YES;
    WeakSelf
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.settingView.transform = CGAffineTransformIdentity;
    }];
}
//显示连麦弹框
- (void)showMircApplay:(id)model
{
    
    [self.view bringSubviewToFront:self.applyView];
    
    self.applyView.hidden = NO;
    
    self.applyView.model = model;
    
}


//隐藏连麦弹框
- (void)hiddenMircApplay
{
    [self.view sendSubviewToBack:self.applyView];
    if (self.applyView) {
            self.applyView.hidden = YES;
        }
}
//显示用户弹出框
- (void)showUserViewWithModel:(LiveUserModel *)model
{
    [self.view bringSubviewToFront:self.userView];
    self.userView.hidden = NO;
    self.userView.isAnchor = self.isAnchor;
    self.userView.isAdmin = [SYHummerManager sharedManager].isAdmin;
    self.userView.model = model;
}
//隐藏用户弹出框
- (void)hiddenUserView
{
    [self.view sendSubviewToBack:self.userView];
    self.userView.hidden = YES;
    self.userView.model = nil;
}
//显示用户列表
- (void)showUserListView
{
    self.userListView.hidden = NO;
    self.chatTextField.userInteractionEnabled  = ![SYHummerManager sharedManager].isMuted;
    self.userListView.transform = CGAffineTransformMakeTranslation(0, - SCREEN_HEIGHT);
    
}


#pragma mark - 隐藏用户列表
- (void)hidenUserListView
{
    self.chatTextField.userInteractionEnabled  = ![SYHummerManager sharedManager].isMuted;
    self.userListView.hidden = YES;
    self.userListView.transform = CGAffineTransformIdentity;
    
}

- (void)pushFeedBackViewController
{
    PublishViewController *vc = [[PublishViewController alloc]init];
    [vc setBackButton];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self hidenUserListView];
    [self hidenSettingView];
}

#pragma mark - LiveProtocol

#pragma mark -主播成功创建聊天室

- (void)createRoomError:(NSString *)errorMessage
{
    [MBProgressHUD yy_showError:errorMessage];
    YYLogDebug(@"[MouseLive-BaseLiveViewController] createRoomError start");
    [self quit];
    YYLogDebug(@"[MouseLive-BaseLiveViewController] createRoomError stop");

}

//观众成功进入房间 获取聊天室ID 请求用户列表并保存本地
- (void)createRoomSucess:(id)data
{
    //      self.liveRoomInfo = (LiveRoomInfoModel *)data;
    //初始化本地存储对象
    self.userInfoList = [[LiveUserInfoList alloc]initWithLiveType:self.liveType roomid:self.config.ownerRoomId uid:self.config.localUid anchorId:self.liveRoomInfo.ROwner.Uid];
    WeakSelf
    // 获取roominfo
    [self.userInfoList getRoomInfo:^(LiveRoomInfoModel * _Nonnull roomInfo, NSDictionary<NSString *,LiveUserModel *> * _Nonnull userList) {
        weakSelf.liveRoomInfo = roomInfo;
        
        weakSelf.userListView.roomInfoModel = roomInfo;
        if (weakSelf.liveType == LiveTypeAudio) {
            // 设置语音房间属性
            weakSelf.audioContentView.isAnchor = weakSelf.isAnchor;
            weakSelf.audioMicStateController.isAnchor = weakSelf.isAnchor;
            weakSelf.audioMicStateController.anchorUid = weakSelf.liveRoomInfo.ROwner.Uid;
            weakSelf.audioMicStateController.audioContentView = weakSelf.audioContentView;
            weakSelf.liveRoomInfo.ROwner.MicEnable = YES;
            weakSelf.liveRoomInfo.ROwner.SelfMicEnable = YES;
            weakSelf.audioContentView.roomInfoModel = weakSelf.liveRoomInfo;
        }
        // 只有主播自己
        weakSelf.anchorView.peopleCount = 1;
        weakSelf.audioContentView.peopleCount = 1;
        
        [weakSelf.userInfoList userJoin:weakSelf.liveRoomInfo.ROwner.Uid];
        
        //刷新主播头像
        [weakSelf refreshAnchorViewWithModel:weakSelf.liveRoomInfo];
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.config.ownerRoomId = weakSelf.liveRoomInfo.RoomId;
            if (weakSelf.publishMode == PUBLISH_STREAM_CDN) {
                [weakSelf.liveBG joinRoomWithConfig:weakSelf.config pushUrl:weakSelf.url];
            } else {
                [weakSelf.liveBG joinRoomWithConfig:weakSelf.config pushUrl:nil];
            }
        });
    }];
}
#pragma mark - LivePresenterDelegate
#pragma mark - 观众成功进入房间
/**
 1初始化本地存储对象
 2获取房间信息
 3存储房间用户本地列表
 */
- (void)audienceJoinChatRoom:(id)data
{
    //本地用户列表初始化
    self.userInfoList = [[LiveUserInfoList alloc] initWithLiveType:self.liveType roomid:self.config.anchroMainRoomId uid:self.config.localUid anchorId:self.config.anchroMainUid];
    
    id roomId = [data objectForKey:@"RChatId"];
    if (data != nil) {
        WeakSelf
        [[SYHummerManager sharedManager]joinChatRoomWithRoomId:roomId completionHandler:^(NSError * _Nullable error) {
            if (!error) {
                YYLogDebug(@"本人用户 uid:%@, 成功进入房间 roomind:%@", self.config.localUid, roomId);
                [weakSelf.userInfoList getRoomInfo:^(LiveRoomInfoModel * _Nonnull roomInfo, NSDictionary<NSString *,LiveUserModel *> * _Nonnull userListDict) {
                    weakSelf.liveRoomInfo = roomInfo;
                    weakSelf.userListView.roomInfoModel = roomInfo;
                    if (weakSelf.liveType == LiveTypeAudio) {
                        // 设置语音房间属性
                        weakSelf.audioContentView.isAnchor = weakSelf.isAnchor;
                        weakSelf.audioMicStateController.isAnchor = weakSelf.isAnchor;
                        weakSelf.audioMicStateController.anchorUid = weakSelf.liveRoomInfo.ROwner.Uid;
                        weakSelf.audioMicStateController.audioContentView = weakSelf.audioContentView;
                        // 这里需要设置下主播的麦克风情况
                        LiveUserModel *owner = [userListDict objectForKey:weakSelf.liveRoomInfo.ROwner.Uid];
                        weakSelf.liveRoomInfo.ROwner.MicEnable = owner.MicEnable;
                        weakSelf.liveRoomInfo.ROwner.SelfMicEnable = owner.SelfMicEnable;
                        weakSelf.audioContentView.roomInfoModel = weakSelf.liveRoomInfo;
                    }
                    
                    //刷新主播头像
                    [weakSelf refreshAnchorViewWithModel:weakSelf.liveRoomInfo];
                    
                    // 用户数量，应该是包含主播的，算上自己
                    weakSelf.anchorView.peopleCount = userListDict.count + 1;
                    weakSelf.audioContentView.peopleCount = userListDict.count + 1;
                    
                    // 增加自己的uid
                    [weakSelf.userInfoList userJoin:self.config.localUid];
                    
                    /**子类实现 set方法
                     1视频房 接入连麦用户 开始视频直播
                     2语音房 刷新连麦用户头像信息 开始音聊
                     3.获取全员禁言状态修改是否可以聊天
                     */
                    if (weakSelf.publishMode == PUBLISH_STREAM_CDN) {
                        [weakSelf.liveBG setPlayer:self.player];
                        [weakSelf.liveBG joinRoomWithConfig:self.config pullUrl:self.url];
//                        [weakSelf.player start];
                        
                    } else if (weakSelf.publishMode == PUBLISH_STREAM_RTC) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf startUpLiveWithMircUserListArray:[userListDict allValues]];
                                if ([SYHummerManager sharedManager].isAllMuted || [SYHummerManager sharedManager].isMuted) {
                                    weakSelf.chatTextField.userInteractionEnabled = NO;
                                    weakSelf.toolView.talkButtonTitle = NSLocalizedString(@"Banned",nil);//@"禁言中"
                                }
                        });
                    }
                }];
                
                [BaseConfigManager sy_logWithFormat:@"成功进入房间%@",roomId];
            }
            else {
                YYLogError(@"[MouseLive-BaseLiveViewController] SYHummerManager joinChatRoomWithRoomId error start");
                [weakSelf quit];
                YYLogError(@"[MouseLive-BaseLiveViewController] SYHummerManager joinChatRoomWithRoomId error stop");
                [MBProgressHUD yy_showError:@"进入房间失败（Hummer失败）"];
            }
        }];
    }
}

- (void)liveViewRoomInfo:(LiveRoomInfoModel *)roomInfo UserListDataSource:(NSArray <LiveUserModel *> *)data
{
    self.liveRoomInfo = roomInfo;
}


#pragma mark - LiveBGDelegate
- (void)TokenError
{
}

- (void)didJoinRoomError
{
    [MBProgressHUD yy_showError:NSLocalizedString(@"WS disconnect", nil)];
    
    YYLogError(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didJoinRoomError  start");
    //退出房间
    [self quit];
    
    YYLogError(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didJoinRoomError  stop");

}

// 网络错误
- (void)didNetError:(NSError *)error
{
    [MBProgressHUD yy_showError:NSLocalizedString(@"WS disconnect", nil)];
    YYLogError(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didNetError  start");
    //退出房间
    [self quit];
    YYLogError(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didNetError  stop");

}

// 服务器关闭
- (void)didNetClose
{
    [MBProgressHUD yy_showError:NSLocalizedString(@"WS disconnect", nil)];
    YYLogDebug(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didNetClose  start");

    //退出房间
    [self quit];
    
    YYLogDebug(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didNetClose  stop");

}

// 用户接受连麦
- (void)didInviteAcceptWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    [self hidenlinkHud];
    
}

// 接受到被连麦的请求 主播弹框提示
- (void)didBeInvitedWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    WeakSelf
    //同房间 观众连麦
    if ([roomid isEqualToString:self.config.ownerRoomId]) {
        [weakSelf.userInfoList getUserInfoWithUid:uid complete:^(LiveUserModel * _Nonnull model) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showMircApplay:model];
            });
        }];
    } else {
        // 如果不是自己的房间，就需要获取其他房间的用户信息
        [self.userInfoList getOtherRoomUserInfoWithUid:uid complete:^(LiveUserModel * _Nonnull model) {
            dispatch_async(dispatch_get_main_queue(), ^{
                LiveAnchorModel *anchorModel = [[LiveAnchorModel alloc]init];
                anchorModel.AId = model.Uid;
                anchorModel.AName = model.NickName;
                anchorModel.ACover = model.Cover;
                [weakSelf showMircApplay:anchorModel];
            });
        }];
    }
}

// 用户取消连麦（主播取消连麦）
- (void)didInviteRefuseWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    [self hidenlinkHud];
    //@"主播拒绝了你的连麦申请"
    [MBProgressHUD yy_showSuccess:NSLocalizedString(@"You're rejected by the owner.", nil)  toView:self.view];
}

//主播接到连麦请求 弹出提示框 长时间不处理 用户连接超时 主播接到cancel事件 隐藏弹出框
- (void)didBeInviteCancelWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    //
    if (self.isAnchor) {
        [self hiddenMircApplay];
    }
}

// 用户连麦超时
- (void)didInviteTimeOutWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    [self hidenlinkHud];
}

// 用户连麦中
- (void)didInviteRunningWithUid:(NSString *)uid roomid:(NSString *)roomid
{
     //观众端显示 @"对面主播正在连麦中，请稍后再试"
       [self hidenlinkHud];
       if (self.liveType == LiveTypeAudio) {
          [MBProgressHUD yy_showSuccess:NSLocalizedString(@"Seats are full.", nil)  toView:self.view];
       } else {
          [MBProgressHUD yy_showSuccess:NSLocalizedString(@"The remote user is not available for connection.", nil)  toView:self.view];
       }
}

// 用户进入 刷弹幕
- (void)didUserJoin:(NSDictionary<NSString *, NSString *> *)userList
{
    NSArray<NSString *>* uidKeys = [userList allKeys];
    
    for (NSString *uid in uidKeys) {
        NSString *roomid = userList[uid];
        [self handleUserJoinWithUid:uid roomid:roomid];
    }
}

// 用户退出
- (void)didUserLeave:(NSDictionary<NSString *, NSString *> *)userList
{
    NSArray<NSString *>* uidKeys = [userList allKeys];
    for (NSString *uid in uidKeys) {
        NSString *roomid = userList[uid];
        [self handleUserLeaveWithUid:uid roomid:roomid];
        //隐藏对方头像
        if ([uid isEqualToString:self.currentVideoMircUid]) {
            if (self.headerView) {
                self.headerView.hidden = YES;
                YYLogDebug(@"[MouseLive-BaseLiveViewController]  headerView hidden %d didUserLeave %@ currentMircUid %@",self.headerView.hidden,uid,self.currentVideoMircUid);
            }
        }
    }
}
/// 处理用户进入
/// @param uid 进入用户 uid
/// @param roomid 进入用户 roomid
- (void)handleUserJoinWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    if (![self.userInfoList userAlreadyExistWithUid:uid]) {
        // 用户数目 ++
        if (self.liveType == LiveTypeVideo) {
            self.anchorView.peopleCount++;
            YYLogDebug(@"[MouseLive BaseLiveViewController] handleUserJoinWithUid peopleCount = %ld",self.anchorView.peopleCount);
        } else if (self.liveType == LiveTypeAudio) {
             self.audioContentView.peopleCount++;
            YYLogDebug(@"[MouseLive BaseLiveViewController] handleUserJoinWithUid peopleCount = %ld",self.audioContentView.peopleCount);
        }
    }
    WeakSelf
    [self.userInfoList getUserInfoWithUid:uid complete:^(LiveUserModel * _Nonnull userModel) {
        NSDictionary *messageDict = @{
            @"NickName":userModel.NickName,
            @"Uid" :userModel.Uid,
            @"message": NSLocalizedString(@"joined", nil) // @"来了"
        };
        NSAttributedString *messageString = [weakSelf fectoryChatMessageWithMessageString:[NSString yy_stringFromJsonObject:messageDict] isjoinOrLeave:YES];
        [weakSelf.talkTableView.dataArray addObject: messageString];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [weakSelf.talkTableView refreshTalkView];
        });
    
        [weakSelf.userListView refreshViewWithType:weakSelf.liveType needAnchor:NO isAnchor:weakSelf.isAnchor config:weakSelf.config userInfoList:weakSelf.userInfoList];

    }];
}

/// 处理用户离开
/// @param uid 离开用户 uid
/// @param roomid 离开用户 roomid
- (void)handleUserLeaveWithUid:(NSString *)uid roomid:(NSString *)roomid
{
    if ([self.userInfoList userAlreadyExistWithUid:uid]) {
        
        if (self.liveType == LiveTypeVideo) {
            
            self.anchorView.peopleCount--;
            
            YYLogDebug(@"[MouseLive BaseLiveViewController] handleUserJoinWithUid peopleCount = %ld",self.anchorView.peopleCount);
        } else if (self.liveType == LiveTypeAudio) {
            self.audioContentView.peopleCount--;
            YYLogDebug(@"[MouseLive BaseLiveViewController] handleUserJoinWithUid peopleCount = %ld",self.audioContentView.peopleCount);
        }
        
    } else {
        //用户查询不到不做处理
        return;
    }
    if ([roomid isEqualToString:self.config.ownerRoomId]) {
        WeakSelf
        [self.userInfoList getUserInfoWithUid:uid complete:^(LiveUserModel * _Nonnull userModel) {
            NSDictionary *messageDict = @{
                @"NickName":userModel.NickName,
                @"Uid" :userModel.Uid,
                @"message": NSLocalizedString(@"left", nil) // @"离开"
            };
            NSAttributedString *messageString = [weakSelf fectoryChatMessageWithMessageString:[NSString yy_stringFromJsonObject:messageDict] isjoinOrLeave:YES];
            [weakSelf.talkTableView.dataArray addObject: messageString];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [weakSelf.talkTableView refreshTalkView];
            });
            if (userModel) {
                //更新本地存储列表
                [weakSelf.userInfoList userLeave:userModel.Uid];
            }
            //刷新列表
            [weakSelf.userListView refreshViewWithType:weakSelf.liveType needAnchor:NO isAnchor:weakSelf.isAnchor config:weakSelf.config userInfoList:weakSelf.userInfoList];
            
        }];
        //改变底部状态栏  自己可以连麦了
        if (self.liveType == LiveTypeAudio) {
             [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeToolButtonState object:@{@"uid":uid ,@"state":@"OFF"}];
        }
    }
}

//子类实现
- (void)didChatLeaveWithUid:(NSString *)uid
{
    YYLogDebug(@"%@",uid);
}

//主播挂断 观众退出房间
- (void)didCloseRoom
{
    // TODO: 2020/05/06 19:40:40:696  GetRoomInfo----[apiGetRoomInfo][ERR]:mongo: no documents in result
    // zhangjianping 主播自己也可能是离开了
    //if (!self.isAnchor) {
    [MBProgressHUD yy_showSuccess:NSLocalizedString(@"Broadcast ended.", nil)];//房主直播已结束

    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyRefreshNewAndDelOld object:self.liveRoomInfo.RoomId];
    YYLogDebug(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didCloseRoom  start");

        [self quit];
    
    YYLogDebug(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didCloseRoom  stop");
    

       
    //}
}

// 自己被踢出 从直播房间中踢出
- (void)didKickedSelf
{
    //@"您被踢出直播间"
    [MBProgressHUD yy_showSuccess:NSLocalizedString(@"You are kicked out", nil)];
    YYLogDebug(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didKickedSelf  start");

    [self quit];
    
    YYLogDebug(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didKickedSelf  stop");

}

- (void)didPublishStreamToCDNError
{
    [MBProgressHUD yy_showError:@"CDN 推流失败"];
    
    YYLogDebug(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didPublishStreamToCDNError  start");

    [self quit];
    
    YYLogDebug(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didPublishStreamToCDNError  stop");

}
/// 自己被封了
- (void)didSelfBanned
{
    [MBProgressHUD yy_showError:@"您已被封号"];
    YYLogDebug(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didSelfBanned  start");

    [self quit];
    
    YYLogDebug(@"[MouseLive-BaseLiveViewController] LiveBGDelegate didSelfBanned  stop");


}

/// thunder 网络已经断开
- (void)didThunderNetClose
{
//  [MBProgressHUD yy_showError:@"Thunder 网络已经断开"];
//  [self quit];
}

/// 网络已经连接
- (void)didNetConnected
{
    //隐藏网络提示框
    [self.netAlertView removeFromSuperview];
    self.netAlertView = nil;
    
    self.shouldJion = NO;
    self.shouldReConnected = YES;

    [[LivePresenter shareInstance] fetchRoomInfoWithType:self.liveType config:self.config success:^(int taskId, id  _Nullable respObjc) {
        YYLogDebug(@"LivePresenter---getRoomInfo success");
WeakSelf
        [self.userInfoList setRoomInfo:respObjc complete:^(LiveRoomInfoModel * _Nonnull roomInfoModel, NSDictionary<NSString *,LiveUserModel *> * _Nonnull userListDict) {
            if (self.liveType == LiveTypeAudio) {
                weakSelf.audioContentView.peopleCount = userListDict.count;
                YYLogDebug(@"[MouseLive BaseLiveViewController] didNetConnected peopleCount = %ld",weakSelf.anchorView.peopleCount);
                [weakSelf startUpLiveWithMircUserListArray:[userListDict allValues]];
            } else {
                weakSelf.anchorView.peopleCount = userListDict.count;
                YYLogDebug(@"[MouseLive BaseLiveViewController] didNetConnected peopleCount=%ld",weakSelf.audioContentView.peopleCount);

            }

        }];
    } failure:^(int taskId, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
        YYLogDebug(@"LivePresenter---getRoomInfo error %@",errorMsg);
    }];
}

/// 网络连接中
- (void)didnetConnecting
{
    [self netAlertView];
}

#pragma makr -- 显示网络断开提示
- (void)showNetAlert
{
    YYLogDebug(@"[MouseLive-ios] showNetAlert--entry");

    if (!self.isVisible) {
        YYLogDebug(@"[MouseLive-ios] showNetAlert--show");
        self.netAlert = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Reconnecting to internet, please wait.", nil) preferredStyle:UIAlertControllerStyleAlert];
        
        [self presentViewController:self.netAlert animated:YES completion:nil];
        self.isVisible = YES;
    }
    
    YYLogDebug(@"[MouseLive-ios] showNetAlert--exit");
}

- (void)hideNetAlert
{
    YYLogDebug(@"[MouseLive-ios] hideNetAlert--entry");

    if (self.isVisible) {
        YYLogDebug(@"[MouseLive-ios] hideNetAlert--hide");
        [self.netAlert dismissViewControllerAnimated:YES completion:nil];
        self.isVisible = NO;
    }
    
    YYLogDebug(@"[MouseLive-ios] hideNetAlert--exit");
}
#pragma mark - SYHummerManagerObserver

// 接受广播消息
- (void)didReceivedBroadcastFrom:(NSString *)uid message:(NSString *)message
{
    [self.talkTableView.dataArray addObject:[self fectoryChatMessageWithMessageString:message isjoinOrLeave:NO]];
    [self.talkTableView refreshTalkView];
}

// 返回当前有多少人
- (void)didChangeMemberCount:(NSInteger)count
{
    //    self.anchorView.peopleCount = count;
    //    self.audioContentView.peopleCount = count;
}

/**刷弹幕*/
- (void)reloadTableViewWithDict:(NSDictionary *)messageDict isJoinOrLeave:(BOOL)state
{
    YYLogDebug(@"[MouseLive-App] BaseLiveViewController reloadTableViewWithDict, messageDict:%@, state:%d", messageDict, state);
    NSAttributedString *messageString = [self fectoryChatMessageWithMessageString:[NSString yy_stringFromJsonObject:messageDict]isjoinOrLeave:state];
    
    YYLogDebug(@"[MouseLive-App] BaseLiveViewController reloadTableViewWithDict, messageString:%@", messageString);
    WeakSelf
    [self.talkTableView.dataArray addObject: messageString];
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.talkTableView refreshTalkView];
    });
}

// 禁言/解禁   弹幕 XX被禁言  XX被解禁 黄色字体
- (void)didMutedWithArray:(NSArray<SYUser *> *)user muted:(BOOL)muted
{
    //缓存用户 发送禁言解禁弹幕
    WeakSelf
    [self.userInfoList getUserList:^(NSDictionary<NSString *,LiveUserModel *> * _Nonnull userList) {
        for (SYUser *userModel in user) {
            LiveUserModel *model = (LiveUserModel *)[userList objectForKey:[NSString stringWithFormat:@"%lld", userModel.hummerUser.ID]];
            if (model) {
                model.isMuted = muted;
                [weakSelf.userInfoList setUserInfo:model];
            }
            [weakSelf muteMessgeWithModel:model mute:muted];
        }
    }];
    //刷新UI
    //刷新成员列表
    [self.userListView refreshViewWithType:self.liveType needAnchor:NO isAnchor:self.isAnchor config:self.config userInfoList:self.userInfoList];
    // 如果是自己
    if ([SYHummerManager sharedManager].isMuted) {
        [self muteMessgeWithModel:LOCAL_USER mute:muted];
        self.toolView.talkButtonTitle = NSLocalizedString(@"Banned", nil);
        self.chatTextField.userInteractionEnabled = NO;
    } else {
        self.toolView.talkButtonTitle = NSLocalizedString(@"Hey~", nil);
        self.chatTextField.userInteractionEnabled = YES;
    }
    
}
/** 禁言消息封装*/
- (void)muteMessgeWithModel:(LiveUserModel *)model mute:(BOOL)muted
{
    NSDictionary *messageDict = @{
        @"NickName": model.NickName,
        @"Uid" : model.Uid,
        @"message":muted ? NSLocalizedString(@"is banned", nil) : NSLocalizedString(@"is unbanned", nil) ,// @"被禁言" : @"被解禁",
        @"type":@"Notice"
    };
    [self reloadTableViewWithDict:messageDict isJoinOrLeave:NO];
}
// 全体禁言/解禁  暂时不做
- (void)didAllMuted:(BOOL)muted
{
    WeakSelf
    // 才设置缓存
    [self.userInfoList getUserList:^(NSDictionary<NSString *,LiveUserModel *> * _Nonnull userList) {
        // 如果全员禁言/解禁，都设置
        NSArray<LiveUserModel *>* list = [userList allValues];
        for (LiveUserModel *model in list) {
            //非主播全部设置为禁言
            if (!model.isAnchor) {
                model.isMuted = muted;
                [weakSelf.userInfoList setUserInfo:model];
            }
        }
    }];
    
    //UI
    //刷新成员列表
    [self.userListView refreshViewWithType:self.liveType needAnchor:NO isAnchor:self.isAnchor config:self.config userInfoList:self.userInfoList];
    
    if (self.isAnchor) {
        self.toolView.talkButtonTitle = NSLocalizedString(@"Hey~", nil);
        self.chatTextField.userInteractionEnabled = YES;
    }
    else {
        if (muted) {
            self.toolView.talkButtonTitle = NSLocalizedString(@"Banned", nil);
            self.chatTextField.userInteractionEnabled = NO;
        } else {
            self.toolView.talkButtonTitle = NSLocalizedString(@"Hey~", nil);;
            self.chatTextField.userInteractionEnabled = YES;
        }
    }
}

// 全体禁麦/开麦
- (void)didAllMicOff:(BOOL)micOff
{
    [self.audioMicStateController handleDidAllMicOff:micOff];
}

// 提升管理员，通过判断 isAdmin 判断是否是自己管理员 XX被提升为管理员
- (void)didAddRoleWithUid:(NSString *)uid
{
    [self.userInfoList getUserInfoWithUid:uid complete:^(LiveUserModel * _Nonnull model) {
        model.isAdmin = YES;
        [self.userInfoList setUserInfo:model];
    }];
    
    [self.userListView refreshViewWithType:self.liveType needAnchor:NO isAnchor:self.isAnchor config:self.config userInfoList:self.userInfoList];
    
    // 修改某人是管理员
    // 如果是自己的话，直接使用 hummer 获取
    WeakSelf
    [self.userInfoList getUserInfoWithUid:uid complete:^(LiveUserModel * _Nonnull user) {
        user.isAdmin = YES;
        [weakSelf.userInfoList setUserInfo:user];
        NSDictionary *messageDict = @{
            @"NickName": user.NickName,
            @"Uid" : user.Uid,
            @"message": NSLocalizedString(@"is admin now", nil), // @"已是管理员",
            @"type":@"Notice"
        };
        [weakSelf reloadTableViewWithDict:messageDict isJoinOrLeave:NO];
    }];
}

// 撤销管理员 XX被降级
- (void)didRemoveRoleWithUid:(NSString *)uid
{
    [self.userInfoList getUserInfoWithUid:uid complete:^(LiveUserModel * _Nonnull model) {
        model.isAdmin = NO;
        [self.userInfoList setUserInfo:model];
    }];
    
    [self.userListView refreshViewWithType:self.liveType needAnchor:NO isAnchor:self.isAnchor config:self.config userInfoList:self.userInfoList];
    
    // 修改某人是管理员
    // 如果是自己的话，直接使用 hummer 获取
    WeakSelf
    [self.userInfoList getUserInfoWithUid:uid complete:^(LiveUserModel * _Nonnull user) {
        user.isAdmin = NO;
        [weakSelf.userInfoList setUserInfo:user];
        NSDictionary *messageDict = @{
            @"NickName": user.NickName,
            @"Uid" : user.Uid,
            @"message": NSLocalizedString(@"is not admin now",  nil),// @"被降级", //已不是管理员
            @"type":@"Notice"
        };
        [weakSelf reloadTableViewWithDict:messageDict isJoinOrLeave:NO];
    }];
}
// 接受被踢出消息 XX被提出房间
- (void)didKickedWithArray:(NSArray<SYUser *> *)user
{
    WeakSelf
    for (SYUser *userModel in user) {
        [self.userInfoList getUserInfoWithUid:[NSString stringWithFormat:@"%lld", userModel.hummerUser.ID] complete:^(LiveUserModel * _Nonnull model) {
            NSDictionary *messageDict = @{
                @"NickName": model.NickName ? model.NickName :@"",
                @"Uid" : model.Uid ? model.Uid :@"",
                @"message":NSLocalizedString(@"is kicked", nil),
                @"type":@"Notice"
            };
            YYLogDebug(@"[MouseLive-BaseLiveViewController] didKickedWithArray %@",messageDict);
            [weakSelf reloadTableViewWithDict:messageDict isJoinOrLeave:NO];
            //删除用户
            if (model) {
                [weakSelf.userInfoList userLeave:model.Uid];
            }
        }];
    }
}

//销毁房间
- (void)didDismissByOperator
{
    YYLogDebug(@"[MouseLive-BaseLiveViewController] SYHummerManagerObserver didDismissByOperator start");

    [self quit];
    
    YYLogDebug(@"[MouseLive-BaseLiveViewController] SYHummerManagerObserver didDismissByOperator stop");

}

#pragma mark - UITextFieldDelegate 聊天

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    if (self.chatTextField.text.length == 0) {
        [textField resignFirstResponder];
    } else {
        NSDictionary *userDict  = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kUserInfo];
        NSString *userName = [userDict objectForKey:kNickName];
        NSNumber *uid = [userDict objectForKey:kUid];
        NSDictionary *messageDict = @{
            @"NickName":userName,
            @"Uid" :uid,
            @"message":textField.text,
            @"type":@"Msg"
        };
        WeakSelf
        self.chatTextField.text = nil;
        NSMutableString *sendString = [[NSMutableString alloc]initWithString:[NSString yy_stringFromJsonObject:messageDict]];
        [[SYHummerManager sharedManager]sendBroadcastMessage:sendString completionHandler:^(NSError * _Nullable error) {
            if (!error) {
                [weakSelf.talkTableView.dataArray addObject:[self fectoryChatMessageWithMessageString:sendString isjoinOrLeave:NO]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.talkTableView refreshTalkView];
                });
                YYLogDebug(@"发送消息成功");
                [BaseConfigManager sy_logWithFormat:@"发送消息成功"];
            } else {
                YYLogDebug(@"发送消息失败");
                [BaseConfigManager sy_logWithFormat:@"发送消息失败"];
            }
        }];
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

#pragma mark- 弹幕消息封装
/**
 1：msg 人黄，字白（自己+主播全黄色 ）
 2：主播通知 黄字
 3：进出房间 人白 字白
 4：顶部通知 白字
 */
- (NSAttributedString *)fectoryChatMessageWithMessageString:(NSString *)message isjoinOrLeave:(BOOL)state
{
    NSDictionary *messageDict = [message yy_jsonObjectFromString];
    NSString *messageType = [messageDict objectForKey:@"type"];
    
    NSNumber *localUid = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kUserInfo] objectForKey:kUid];
    //黄色名字(人员进入退出白色) 自己发的显示 我：xx
    NSAttributedString *nameString = [[NSAttributedString alloc]initWithString:[[messageDict objectForKey:kUid] isEqual:localUid] ? NSLocalizedString(@"Talk_Me", nil):[NSString stringWithFormat:@"%@   ",[messageDict objectForKey:kNickName]] attributes:@{NSForegroundColorAttributeName:state ? [UIColor whiteColor] : [UIColor sl_colorWithHexString:@"#FFDA81"]}];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithAttributedString:nameString];
    UIColor *messageTextColor = [UIColor whiteColor];
    
    if ([messageType isEqualToString:@"Msg"]) {
        //自己发言或者是主播发言橙色突出字体
        if ([[messageDict objectForKey:kUid] isEqual:localUid] || [[messageDict objectForKey:kUid] isEqual:@(self.config.anchroMainUid.longLongValue)]) {
            messageTextColor = [UIColor sl_colorWithHexString:@"#FFDA81"];
            
        } else {
            //其他人 黄+白
            messageTextColor = [UIColor whiteColor];
        }
    } else if ([messageType isEqualToString:@"Notice"]) {
        //主播通知 黄色字体
        messageTextColor = [UIColor sl_colorWithHexString:@"#FFDA81"];
        
    }
    
    if (state) {
        messageTextColor = [UIColor whiteColor];
    }
    
    NSAttributedString *messageString = [[NSAttributedString alloc]initWithString:[messageDict objectForKey:kmessage] attributes:@{NSForegroundColorAttributeName:messageTextColor}];
    [attributedString appendAttributedString:messageString];
    [attributedString addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]} range:NSMakeRange(0, attributedString.mutableString.length)];
    return [[NSAttributedString alloc]initWithAttributedString:attributedString];
}

#pragma mark - 显示码率
// 如果视频有人进入，会返回左边和右边的 uid，只有在 chatJoin 后才会返回，didChatLeaveWithUid 是不会返回
- (void)didShowCanvasWith:(NSString *)leftUid rightUid:(NSString *)rightUid
{
    [MBProgressHUD yy_hideHUDForView:self.view];
    self.codeLeftUid = leftUid;
    self.codeRightUid = rightUid;
    //默认显示码块
    [self showCodeView];
    //主播可以设置清晰度
    if ([LOCAL_USER.Uid isEqualToString:leftUid]) {
        self.settingView.isMircPeople = YES;
    }
    if (rightUid.length) {
        //是否可以设置清晰度
        if ([LOCAL_USER.Uid isEqualToString:rightUid]) {
            self.settingView.isMircPeople = YES;
        }
        //显示对方头像
        WeakSelf
        [self.userInfoList getUserInfoWithUid:rightUid complete:^(LiveUserModel * _Nonnull model) {
            weakSelf.headerView.hidden = NO;
            YYLogDebug(@"[MouseLive-BaseLiveViewController] 1 headerView hidden %d",weakSelf.headerView.hidden);
            weakSelf.headerView.model = model;
            YYLogDebug(@"[MouseLive-BaseLiveViewController] headerView hidden %@",model.NickName);

        }];
    } else {
        //隐藏对方头像
        self.headerView.hidden = YES;
        YYLogDebug(@"[MouseLive-BaseLiveViewController] 2 headerView hidden %d",self.headerView.hidden);

        
    }
}

// 反馈网络状态
- (void)didUpdateNetworkQualityStatus:(NetworkQualityStauts *)status
{
    // 刷新网络状态
    
    WeakSelf
    if (!self.bottomCodeRateView.hidden) {
        self.bottomCodeRateView.uid = LoginUserUidString;
        self.bottomCodeRateView.qualityModel = status;
        [self.userInfoList getUserInfoWithUid:LoginUserUidString complete:^(LiveUserModel * _Nonnull userModel) {
            weakSelf.bottomCodeRateView.userDetailString = [NSString stringWithFormat:@"%@\n%@",userModel.Uid,userModel.NickName];
        }];
    }
    if (!self.leftCodeRateView.hidden) {
        self.leftCodeRateView.uid = self.codeLeftUid;
        self.leftCodeRateView.qualityModel = status;
        [self.userInfoList getUserInfoWithUid:self.codeLeftUid complete:^(LiveUserModel * _Nonnull userModel) {
            weakSelf.leftCodeRateView.userDetailString = [NSString stringWithFormat:@"%@\n%@",userModel.Uid,userModel.NickName];
        }];
    }
    if (!self.rightCodeRateView.hidden) {
        self.rightCodeRateView.uid = self.codeRightUid;
        self.rightCodeRateView.qualityModel = status;
        [self.userInfoList getUserInfoWithUid:self.codeRightUid complete:^(LiveUserModel * _Nonnull userModel) {
            weakSelf.rightCodeRateView.userDetailString = [NSString stringWithFormat:@"%@\n%@",userModel.Uid,userModel.NickName];
        }];
    }
}

#pragma mark - SYAppStatusManagerDelegate

//- (void)SYAppDidBecomeActive:(nonnull SYAppStatusManager *)manager
//{
//    NSDictionary *params =  @{
//        kUid:@(self.config.localUid.longLongValue),
//        kRoomId:@(self.config.ownerRoomId.longLongValue),
//        kRType:@(self.liveType),
//    };
//    self.liveManager.params = params;
//
//    WeakSelf
//    [self.liveManager fetchRoomInfoWithCompletionHandler:^(NSDictionary * _Nullable respDictionary, NSError * _Nullable error) {
//        if (respDictionary) {
//            [weakSelf.userInfoList setRoomInfo:respDictionary complete:^(LiveRoomInfoModel * _Nonnull roomInfoModel, NSDictionary<NSString *,LiveUserModel *> * _Nonnull userList) {
//            }];
//        }
//    }];
//}


#pragma mark - LivePresenterDelegate
//主播已经停播

- (void)liveStatusIsStop
{
    [self didCloseRoom];
}

 //视频房才会响应的方法
- (void)resetLiveConfig:(LiveDefaultConfig * _Nullable)config
{
    if (self.shouldReConnected) {
        self.config = config;
        if (self.publishMode != PUBLISH_STREAM_CDN) {
            [self.liveBG reconnectWithConfig:self.config];
        }
        else {
            [self.player stop];
            [self.player start];
        }
    }
}
//刷新页面
- (void)refreshLiveStatusWithLinkUid:(NSString * _Nullable)uid
{
    if (self.liveType == LiveTypeVideo) {
        if (self.publishMode == PUBLISH_STREAM_RTC) {
            //主播
            if ([LivePresenter shareInstance].isOwner || [LivePresenter shareInstance].isWheat) {
                if ([LivePresenter shareInstance].isRunningMirc) {
                    //改变底部状态栏
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeToolButtonState object:@{@"uid":uid ,@"state":@"ON"}];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyshowHungUpButton object:@"1"];
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeToolButtonState object:@{@"uid":@"",@"state":@"OFF"}];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyshowHungUpButton object:@"0"];
                }
            }
            
        } else if (self.publishMode == PUBLISH_STREAM_CDN) {
            self.toolView.isCdnModel = YES;
        }
    }
}

//请求出错
- (void)requestError:(NSString * _Nullable)errorMessage
{
    YYLogDebug(@"GetRoomInfo----%@",errorMessage);
    [self didCloseRoom];
}

- (void)dealloc
{
    YYLogDebug(@"[MouseLive-App] BaseLiveViewController dealloc entry");
    [HttpService sy_httpRequestCancelWithArray:self.taskArray];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //移除代理
    // 由于 self.liveBG @property (nonatomic, strong)  非空的
    self.liveBG = nil;
    
    // 这 5 个是 http 请求的，都要移除掉， zhangjianping
    // SYVideoOrAudioManager
    
    // HomePresenter
    
    // HomeViewController
    
    // LiveUserInfoList
    
    // LivePresenter
    
    YYLogDebug(@"[MouseLive-App] BaseLiveViewController dealloc exit");
}

#if USE_BEATIFY
#pragma mark - Effect
- (SYEffectView *)effectView
{
    if (!_effectView) {
        SYEffectView *view = [SYEffectView loadNibView];
        view.hidden = YES;
        _effectView = view;
    }
    return _effectView;
}

- (void)addEffectView
{
    [self.view addSubview:self.effectView];
    [self.effectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    
    [self.effectView setData:[self sy_getEffectsData]];
}

- (void)showEffectView
{
    [self.effectView showEffectView];
}

#pragma mark - ThunderVideoCaptureFrameObserver
- (ThunderVideoCaptureFrameDataType)needThunderVideoCaptureFrameDataType
{
    return THUNDER_VIDEO_CAPTURE_DATATYPE_TEXTURE;
//    return THUNDER_VIDEO_CAPTURE_DATATYPE_PIXELBUFFER;
}

- (CVPixelBufferRef)onVideoCaptureFrame:(EAGLContext *)glContext PixelBuffer:(CVPixelBufferRef)pixelBuf
{
    if (!pixelBuf) {
        return pixelBuf;
    }
    CVPixelBufferRef outPixelBuf = [self sy_renderPixelBufferRef:pixelBuf context:glContext];
    return outPixelBuf;
}

- (BOOL)onVideoCaptureFrame:(EAGLContext *)context PixelBuffer:(CVPixelBufferRef)pixelBuffer SourceTextureID:(unsigned int)srcTextureID DestinationTextureID:(unsigned int)dstTextureID TextureFormat:(int)textureFormat TextureTarget:(int)textureTarget TextureWidth:(int)width TextureHeight:(int)height
{
    if (pixelBuffer) {
        [self sy_renderPixelBufferRef:pixelBuffer context:context sourceTextureID:srcTextureID destinationTextureID:dstTextureID textureFormat:textureFormat textureTarget:textureTarget textureWidth:width textureHeight:height];
    }
    return YES;
}

/// 注册视频预处理
- (void)registerVideoCaptureFrameObserver
{
    // 先初始化 thunder
    [SYThunderEvent sharedManager];
    [[SYThunderManagerNew sharedManager] registerVideoCaptureFrameObserver:self];
    [self sy_setDefaultBeautyEffect];
    self.effectView.delegate = self;
}

- (void)destroyEffects
{
    [self sy_destroyAllEffects];
    [self hidenSettingView];
    [self.effectView hiddenEffectView];
    // 重新设置初始数据
    [self.effectView setData:[self sy_getEffectsData]];
}


#endif

@end

