//
//  LiveBottonToolView.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/3.
//  Copyright © 2020 sy. All rights reserved.
//

#import "LiveBottonToolView.h"
#import "SYHummerManager.h"
#define  TOOL_W 36
@interface LiveBottonToolView()
/** 工具背景*/
@property (nonatomic, weak) UIView *rightBgView;

/** 公聊区背景*/
@property (nonatomic, weak) UIView *talkBgView;
/** 公聊区*/
@property (nonatomic, strong)UIButton *talkButton;
/** 底部工具*/
/**麦克风按钮*/
@property (nonatomic, strong)UIButton *mircButton;
/**连麦按钮*/
@property (nonatomic, strong)UIButton *linkButton;
/**设置按钮*/
@property (nonatomic, strong)UIButton *settingButton;
/**变声按钮*/
@property (nonatomic, strong)UIButton *whineButton;

@property (nonatomic, strong)NSArray *tools;
@property (nonatomic, assign)BOOL isAnchor;
@property (nonatomic, assign)LiveType liveType;
@property (nonatomic, strong)LiveDefaultConfig *config;

@end

@implementation LiveBottonToolView

- (instancetype)initWithAnchor:(BOOL)isAnchor liveType:(LiveType)type config:(nonnull LiveDefaultConfig *)config
{
    if (self = [super init]) {
//        //改变底部状态栏  自己可以连麦了
//
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refreshLinkButtonState:) name:kNotifyChangeToolButtonState object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refreshAudioToolButtonState:) name:kNotifyChangeAudioToolButtonState object:nil];
        //全员禁麦
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refreshAudioMicButtonState:) name:kNotifyChangeAudioMicButtonState object:nil];
        self.config = config;
        self.isAnchor = isAnchor;
        self.liveType = type;
        [self refreshView];
        if (self.liveType == LiveTypeAudio) {
            [self setupAudioToos];
        } else {
            [self setupVideoTools];
        }
        
    }
    return self;
}


- (void)refreshAudioToolButtonState:(NSNotification *)notification
{
    //no 不显示两个button yes 显示两个button
    NSString *state = notification.object;
    if ([state isEqualToString:@"YES"]) {
        self.mircButton.hidden = NO;
        self.whineButton.hidden = NO;
    } else {
        self.mircButton.hidden = YES;
        self.whineButton.hidden = YES;
    }
}

- (void)refreshAudioMicButtonState:(NSNotification *)notification
{
    // TODO: zhangjianping 切换图片
    NSString *state = notification.object;
    if ([state isEqualToString:@"YES"]) {
        [self.mircButton setImage:[UIImage imageNamed:@"micr_silence"] forState:UIControlStateNormal];
        
        // 开麦，换图片，按钮可以点击
        self.mircButton.selected = NO;
        self.mircButton.userInteractionEnabled = YES;
    }
    else if ([state isEqualToString:@"NO"]) {
        [self.mircButton setImage:[UIImage imageNamed:@"micr_silence"] forState:UIControlStateNormal];
        // 闭麦，换图片，按钮可以点击
        self.mircButton.selected = YES;
        self.mircButton.userInteractionEnabled = YES;
    }
    else if ([state isEqualToString:@"AllMicOff"]) {
        if (!self.isAnchor) {
            // 不是主播
            // 换图片 -- 全部闭麦的图片，按钮不能点击 -- 这里要看下
            [self.mircButton setImage:[UIImage imageNamed:@"audioMicrTool_close"] forState:UIControlStateNormal];
            self.mircButton.userInteractionEnabled = NO;
            self.mircButton.selected = NO;
        }
    }
}

- (void)refreshLinkButtonState:(NSNotification *)notification
{
//    OFF 主播挂断可以连麦了 on 主播正在和别人连麦
    NSString *state = [notification.object objectForKey:@"state"];
    NSString *uid = [notification.object objectForKey:@"uid"];
    NSString *currentMirUid = [notification.object objectForKey:@"currentMirUid"];
    NSLog(@"%@",LoginUserUidString);
    //被连者是主播 证明是自己连的麦
    if (self.liveType == LiveTypeVideo) {
        if (self.isAnchor) {
            //主播pk中
            if ([state isEqualToString:@"ON"]) {
                //主播断开pk 3个按钮
                //改变按钮状态
                self.localRuningMirc = YES;
                self.linkButton.selected = YES;
                self.linkButton.userInteractionEnabled = NO;
            } else if (([state isEqualToString:@"OFF"])) {
                //改变为5个按钮
                self.localRuningMirc = YES;
                self.linkButton.selected = NO;
                self.linkButton.userInteractionEnabled = YES;
            }
        } else {
            //观众连麦中
            if ([state isEqualToString:@"ON"]) {
                if ([uid isEqualToString:LoginUserUidString]) {
                    //更新布局 5个按钮
                    self.localRuningMirc = YES;
                    self.mircEnable = YES;
                    self.linkButton.selected = YES;
                    self.linkButton.userInteractionEnabled = NO;
                    //关闭连麦按钮事件
                    
                } else {
                    //2个按钮
                    self.mircEnable = NO;
                    
                }
            } else if ([state isEqualToString:@"OFF"]) {
                //观众下麦 3个按钮
                //更新布局
                if ( ![currentMirUid isEqualToString:LoginUserUidString] || [uid isEqualToString:currentMirUid]) {
                    //当前连麦者不是自己，或者离开连麦的不是自己
                self.localRuningMirc = NO;
                self.mircEnable = YES;
                //观众连麦按钮复位
                self.mircButton.selected = NO;
                self.linkButton.selected = NO;
                self.linkButton.userInteractionEnabled = YES;
                } else {
                    //2个按钮
                    self.mircEnable = NO;
                }
            }
        }
        [self refreshVideoToolView];
    } else if (self.liveType == LiveTypeAudio) {
        if ([state isEqualToString:@"ON"]) {
            //自己在连麦状态
            if ([uid isEqualToString:LoginUserUidString]) {
                self.mircButton.hidden = NO;
                self.whineButton.hidden = NO;
                
                // 刚进入房间时候，判断全员是否禁麦
                if ([SYHummerManager sharedManager].isAllMicOff) {
                    [self.mircButton setImage:[UIImage imageNamed:@"audioMicrTool_close"] forState:UIControlStateNormal];
                    
                    // TODO: 如果全员禁麦了, 观众进来
                    // 显示闭麦按钮，要黄色的，并且不能点击
                    self.mircButton.userInteractionEnabled = NO; // 不让点击
                    self.mircButton.selected = NO;
                }
            }
            
        } else if ([state isEqualToString:@"OFF"]) {
            //自己在连麦状态
            if ([uid isEqualToString:LoginUserUidString]) {
                self.mircButton.hidden = YES;
                self.whineButton.hidden = YES;
            }
        }
    }
}


- (void)refreshView
{
    if (self.liveType == LiveTypeVideo) {
        
        self.tools = @[@"micr_silence", @"audience_mirc", @"live_tool_setting",@"live_tool_feedback", @"live_tool_code"];
    } else {
        self.tools =@[ @"micr_silence", @"audio_ whine",@"live_tool_feedback", @"live_tool_code"];
    }
}




- (UIView *)talkBgView
{
    if (!_talkBgView) {
        UIView *talkBgView = [[UIView alloc]init];
        talkBgView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
        _talkBgView = talkBgView;
        [self addSubview:_talkBgView];
    }
    return _talkBgView;
}

- (UIView *)rightBgView
{
    if (!_rightBgView) {
        UIView *rightBgView = [[UIView alloc]init];
        _rightBgView = rightBgView;
        [self addSubview:_rightBgView];
    }
    return _rightBgView;
}


- (UIButton *)talkButton
{
    if (!_talkButton) {
        _talkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_talkButton setTitle:NSLocalizedString(@"Hey~", nil) forState:UIControlStateNormal];
        [_talkButton setTitleColor:[UIColor colorWithRed:255 green:255 blue:255 alpha:0.8] forState:UIControlStateNormal];
        _talkButton.titleLabel.font = [UIFont fontWithName:FONT_Regular size:14.0f];
        [_talkButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [_talkButton addTarget:self action:@selector(talkAction) forControlEvents:UIControlEventTouchUpInside];
        [self.talkBgView addSubview:_talkButton];
    }
    return _talkButton;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.talkBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@-13);
        make.left.equalTo(@6);
        make.height.equalTo(@36);
        make.width.equalTo(@(88 * SCREEN_WIDTH/360));
    }];
    [UIView yy_maskViewToBounds:self.talkBgView radius:18.0f];
    
    [self.talkButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@15);
        make.right.equalTo(@-15);
        make.top.equalTo(@0);
        make.height.equalTo(@36);
    }];
    
    CGFloat margin = 8;
    CGFloat W = (self.tools.count - 1)* (TOOL_W + margin) + TOOL_W;
    [self.rightBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.talkBgView);
        make.width.mas_equalTo(W);
        make.height.equalTo(@36);
        make.right.equalTo(self).offset(-8);
    }];
    
    if (self.liveType == LiveTypeAudio) {
        //语音房布局
        UIButton *codeButton = [self.rightBgView.subviews lastObject];
        UIButton *feedbackButton = [self.rightBgView.subviews objectAtIndex:2];
        [codeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.mas_equalTo(0);
            make.right.mas_equalTo(-8);
            make.width.mas_equalTo(TOOL_W);
        }];
        [feedbackButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.mas_equalTo(0);
            make.right.mas_equalTo(codeButton.mas_left).offset(-8);
            make.width.mas_equalTo(TOOL_W);
        }];
        [self.whineButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.mas_equalTo(0);
            make.right.mas_equalTo(feedbackButton.mas_left).offset(-8);
            make.width.mas_equalTo(TOOL_W);
        }];
        [self.mircButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.mas_equalTo(0);
            make.right.mas_equalTo(self.whineButton.mas_left).offset(-8);
            make.width.mas_equalTo(TOOL_W);
        }];
    } else if (self.liveType == LiveTypeVideo) {
        //视频房 布局
        UIButton *codeButton = [self.rightBgView.subviews lastObject];
        UIButton *feedbackButton = [self.rightBgView.subviews objectAtIndex:3];
        [codeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.mas_equalTo(0);
            make.right.mas_equalTo(-8);
            make.width.mas_equalTo(TOOL_W);
        }];
        [feedbackButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.mas_equalTo(0);
            make.right.mas_equalTo(codeButton.mas_left).offset(-8);
            make.width.mas_equalTo(TOOL_W);
        }];
        [self.settingButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.mas_equalTo(0);
            make.right.mas_equalTo(feedbackButton.mas_left).offset(-8);
            make.width.mas_equalTo(TOOL_W);
        }];
        
        [self.linkButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.mas_equalTo(0);
            make.right.mas_equalTo(self.settingButton.mas_left).offset(-8);
            make.width.mas_equalTo(TOOL_W);
        }];
        
        [self.mircButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.mas_equalTo(0);
            make.right.mas_equalTo(self.linkButton.mas_left).offset(-8);
            make.width.mas_equalTo(TOOL_W);
        }];
    }
}
/**
 语音房
 */
- (void)setupAudioToos
{
    [self.rightBgView addSubview:self.mircButton];
    [self.rightBgView addSubview:self.whineButton];
    NSArray *imageNames = @[@"live_tool_feedback", @"live_tool_code"];
    for (int i = 0; i < 2; i++) {
        UIButton *toolBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        toolBtn.backgroundColor = [UIColor clearColor];
        [toolBtn setImage:[UIImage imageNamed:imageNames[i]] forState:UIControlStateNormal];
        toolBtn.tag = i + 3;
        [toolBtn addTarget:self action:@selector(audioToolclick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.rightBgView addSubview:toolBtn];
    }
    
}
/**
 视频房底部按钮
 */
- (void)setupVideoTools
{
    [self.rightBgView addSubview:self.mircButton];
    [self.rightBgView addSubview:self.linkButton];
    [self.rightBgView addSubview:self.settingButton];
    NSArray *imageNames = @[@"live_tool_feedback", @"live_tool_code"];
    for (int i = 0; i < 2; i++) {
        UIButton *toolBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        toolBtn.backgroundColor = [UIColor clearColor];
        [toolBtn setImage:[UIImage imageNamed:imageNames[i]] forState:UIControlStateNormal];
        toolBtn.tag = i + 4;
        [toolBtn addTarget:self action:@selector(videoToolclick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.rightBgView addSubview:toolBtn];
    }
}

/**音频房按钮被点击*/
- (void)audioToolclick:(UIButton *)button
{
    button.selected = !button.selected;
    switch (button.tag) {
        case 1:
            self.clickToolBlock(LiveToolTypeMicr, button.selected);
            break;
        case 2:
            self.clickToolBlock(LiveToolTypeAudioWhine, button.selected);
            
            break;
        case 3:
            self.clickToolBlock(LiveToolTypeFeedback, button.selected);
            
            break;
        case 4:
            self.clickToolBlock(LiveToolTypeCodeRate, button.selected);
            break;
        default:
            break;
    }
    
}
/**视频房按钮被点击*/
- (void)videoToolclick:(UIButton *)button
{
    if (![button isEqual:self.linkButton]) {
        button.selected = !button.selected;
    }
    if (self.clickToolBlock) {
        self.clickToolBlock(button.tag, button.selected);
    }
}

- (void)talkAction
{
    self.talkButton.userInteractionEnabled = NO;
    [self.talkButton performSelector:@selector(setUserInteractionEnabled:) withObject:@YES afterDelay:1];
}


//禁言
- (void)shutupAction
{
    self.talkButton.userInteractionEnabled = NO;
    [self.talkButton setTitle:NSLocalizedString(@"Banned", nil) forState:UIControlStateNormal];
    [self.talkButton setTitleColor:[UIColor colorWithRed:255 green:255 blue:255 alpha:0.8] forState:UIControlStateNormal];
    
}

//解禁言
- (void)notShutupAction
{
    _talkButton.userInteractionEnabled = YES;
    [_talkButton setTitle:NSLocalizedString(@"Hey~", nil) forState:UIControlStateNormal];
    [_talkButton setTitleColor:[UIColor colorWithRed:255 green:255 blue:255 alpha:0.8] forState:UIControlStateNormal];
    
}

- (void)setTalkButtonTitle:(NSString *)talkButtonTitle
{
    [self.talkButton setTitle:talkButtonTitle forState:UIControlStateNormal];
}

/**
 音频房
 观众未连麦时隐藏前两个按钮
 */
- (void)refreshAudioToolView
{
    if (!self.isAnchor && !self.localRuningMirc) {
        self.mircButton.hidden = YES;
        self.whineButton.hidden = YES;
    } else {
        self.mircButton.hidden  = NO;
        self.whineButton.hidden = NO;
    }
}
/**
 视频房
 自己是否在连麦中
 1连麦中显示5个按钮
 2非连麦中显示 按照自己是否可以连麦进行设置
 */
//主播在连麦 或pk中观众不可以连麦
/**
 视频房
 1.进入房间会设置一次
 2.接收到主播断开连麦的通知后设置一次
 yes 自己可以连麦显示三个按钮
 no  自己不可以连麦显示连个按钮
 */
- (void)refreshVideoToolView
{
    if (self.liveType == LiveTypeVideo) {
        if (self.mircEnable) {
            //自己中在连麦中
            if (self.localRuningMirc) {
                self.mircButton.hidden = NO;
                self.linkButton.hidden = NO;
                self.settingButton.hidden = NO;
                [self.mircButton mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.width.mas_equalTo(TOOL_W);
                }];
                [self.linkButton mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.width.mas_equalTo(TOOL_W);
                }];
                [self.settingButton mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.width.mas_equalTo(TOOL_W);
                }];
            } else {
                //1隐藏前两个按钮
                self.mircButton.hidden = YES;
                self.settingButton.hidden = YES;
                self.linkButton.hidden = NO;
                [self.linkButton mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.width.mas_equalTo(TOOL_W);
                }];
                //改变宽度
                [self.mircButton mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.width.mas_equalTo(0);
                }];
                [self.settingButton mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.width.mas_equalTo(0);
                }];
            }
        } else {
            if (!self.isAnchor) {
                //隐藏前三个按钮
                self.mircButton.hidden = YES;
                self.linkButton.hidden = YES;
                self.settingButton.hidden = YES;
                [self.mircButton mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.width.mas_equalTo(0);
                }];
                [self.linkButton mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.width.mas_equalTo(0);
                }];
                [self.settingButton mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.width.mas_equalTo(0);
                }];
            }
        }
    }
}

- (UIButton *)whineButton
{
    if (!_whineButton) {
        _whineButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _whineButton.backgroundColor = [UIColor clearColor];
        [_whineButton setImage:[UIImage imageNamed:@"audio_ whine"] forState:UIControlStateNormal];
        [_whineButton setImage:[UIImage imageNamed:@"audio_ whine_s"] forState:UIControlStateSelected];
        _whineButton.tag = 2;
        [_whineButton addTarget:self action:@selector(audioToolclick:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _whineButton;
}

- (UIButton *)settingButton
{
    if (!_settingButton) {
        _settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _settingButton.backgroundColor = [UIColor clearColor];
        [_settingButton setImage:[UIImage imageNamed:@"live_tool_setting"] forState:UIControlStateNormal];
        [_settingButton setImage:[UIImage imageNamed:@"live_tool_setting_s"] forState:UIControlStateSelected];
        _settingButton.tag = 3;
        if (self.liveType == LiveTypeVideo) {
            [_settingButton addTarget:self action:@selector(videoToolclick:) forControlEvents:UIControlEventTouchUpInside];
            
        } else if (self.liveType == LiveTypeAudio) {
            [_settingButton addTarget:self action:@selector(audioToolclick:) forControlEvents:UIControlEventTouchUpInside];
        }
      
    }
    return _settingButton;
}

- (UIButton *)linkButton
{
    if (!_linkButton) {
        _linkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _linkButton.backgroundColor = [UIColor clearColor];
        //pk
        if (self.isAnchor) {
            [_linkButton setImage:[UIImage imageNamed:@"live_tool_pk"] forState:UIControlStateNormal];
            [_linkButton setImage:[UIImage imageNamed:@"live_tool_pk_s"] forState:UIControlStateSelected];
        } else {
            //连麦
            [_linkButton setImage:[UIImage imageNamed:@"audience_mirc"] forState:UIControlStateNormal];
            [_linkButton setImage:[UIImage imageNamed:@"audience_mirc_s"] forState:UIControlStateSelected];
        }
        _linkButton.tag = 2;
        if (self.liveType == LiveTypeVideo) {
            [_linkButton addTarget:self action:@selector(videoToolclick:) forControlEvents:UIControlEventTouchUpInside];
            
        } else if (self.liveType == LiveTypeAudio) {
            [_linkButton addTarget:self action:@selector(audioToolclick:) forControlEvents:UIControlEventTouchUpInside];
        }
       
    }
    return _linkButton;
}

- (UIButton *)mircButton
{
    if (!_mircButton) {
        _mircButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _mircButton.backgroundColor = [UIColor clearColor];
        [_mircButton setImage:[UIImage imageNamed:@"micr_silence"] forState:UIControlStateNormal];
        [_mircButton setImage:[UIImage imageNamed:@"micr_silence_s"] forState:UIControlStateSelected];
        _mircButton.tag = 1;
        if (self.liveType == LiveTypeVideo) {
            [_mircButton addTarget:self action:@selector(videoToolclick:) forControlEvents:UIControlEventTouchUpInside];
            
        } else if (self.liveType == LiveTypeAudio) {
            [_mircButton addTarget:self action:@selector(audioToolclick:) forControlEvents:UIControlEventTouchUpInside];
        }
       
    }
    return _mircButton;
}

- (void)setIsCdnModel:(BOOL)isCdnModel
{
    _isCdnModel = isCdnModel;
    if (self.liveType == LiveTypeVideo) {
        if (_isCdnModel) {
            if (!self.isAnchor) {
                 self.mircButton.hidden = YES;
                 self.settingButton.hidden = YES;
            }
            self.linkButton.hidden = YES;
            [self.linkButton mas_updateConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(0);
            }];
           
        } else {
            self.linkButton.hidden = NO;
            [self.linkButton mas_updateConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(TOOL_W);
            }];
            self.mircButton.hidden = NO;
            self.settingButton.hidden = NO;
        }
    }
}
@end
