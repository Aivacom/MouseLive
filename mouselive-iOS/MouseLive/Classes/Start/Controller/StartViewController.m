//
//  StartViewController.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/11.
//  Copyright © 2020 sy. All rights reserved.
//

#import "StartViewController.h"
#import "AudioLiveViewController.h"
#import "VideoLiveViewController.h"
//#import "KTVLiveViewController.h"
#import "SYHummerManager.h"
#import "LivePresenter.h"
#import "SYAppId.h"
#import "PushModeView.h"

//开播类型
typedef enum {
    OPlayerTypeVideo = 10,
    OPlayerTypeVoice,
    OPlayerTypeOnline,
    OPlayerTypeSports,
}OPlayerType;

//视频直播模式
 typedef enum {
    VideoPlayerModeRTC = 1,
    VideoPlayerModeCDN
}VideoPlayerMode;

@interface StartViewController ()<LivePresenterDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoView;

@property (nonatomic, weak) IBOutlet UIView *voiceView;

//在线KTV
@property (nonatomic, weak) IBOutlet UIView *onlineView;

@property (nonatomic, weak) IBOutlet UIView *sportsView;

//赛事解说
@property (nonatomic, weak) IBOutlet UIButton *startBtn;

@property (nonatomic, weak) IBOutlet UILabel *videoLB;

@property (nonatomic, weak) IBOutlet UILabel *videoSubLB;

@property (nonatomic, weak) IBOutlet UILabel *voiceLB;

@property (nonatomic, weak) IBOutlet UILabel *voiceSubLB;

@property (weak, nonatomic) IBOutlet UILabel *onlineLB;

@property (weak, nonatomic) IBOutlet UILabel *onlineSubLB;

@property (weak, nonatomic) IBOutlet UILabel *sportLB;

@property (weak, nonatomic) IBOutlet UILabel *sportSubLB;

@property (weak, nonatomic) IBOutlet UIImageView *videoImageView;

@property (weak, nonatomic) IBOutlet UIImageView *audioImageView;

@property (strong, nonatomic) PushModeView *modeView;

@property (nonatomic, assign)NSInteger selectIndex;

@property (nonatomic,strong) LivePresenter *presenter;

@property (nonatomic,assign) OPlayerType playerType;

@property (nonatomic,assign) VideoPlayerMode modeType;

@property (nonatomic,strong)LiveDefaultConfig *config;


@end

@implementation StartViewController

- (PushModeView *)modeView
{
    if (!_modeView) {
        _modeView = [PushModeView pushModeView];
        [self.view addSubview:_modeView];
        WeakSelf
        [_modeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(weakSelf.view);
            make.size.mas_equalTo(CGSizeMake(weakSelf.view.frame.size.width, weakSelf.view.frame.size.height));
        }];        
        _modeView.modeBlock = ^(NSInteger tag) {
            if (tag == 1) {
                weakSelf.modeType = VideoPlayerModeRTC;
            } else if (tag == 2) {
                weakSelf.modeType = VideoPlayerModeCDN;
            }
            weakSelf.modeView.hidden = YES;
            [weakSelf openVideoController];
        };
        _modeView.hidden = YES;
    }
    return _modeView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [LivePresenter shareInstance].delegate = self;
    [self updateUIState];
 
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setUp];
}

- (void)setUp
{
    self.selectIndex = 0;
    self.playerType = OPlayerTypeVideo;
    self.modeType = VideoPlayerModeRTC;
    self.view.backgroundColor = [UIColor sl_colorWithHexString:COLOR_Background];
    [self updateUIState];
    self.onlineView.layer.contents = (id)[UIImage imageNamed:@"publish_ placeholder"].CGImage;
    self.sportsView.layer.contents = (id)[UIImage imageNamed:@"publish_ placeholder"].CGImage;
    [UIView yy_maskViewToBounds:self.videoView radius:8.0f];
    [UIView yy_maskViewToBounds:self.voiceView radius:8.0f];
    [UIView yy_maskViewToBounds:self.onlineView radius:8.0f];
    [UIView yy_maskViewToBounds:self.sportsView radius:8.0f];
    [UIView yy_maskViewToBounds:self.startBtn radius:8.0f];
    
    
}

- (IBAction)itemClicked:(UITapGestureRecognizer *)sender
{
    UIView *tapView = sender.view;
    OPlayerType type = (OPlayerType)tapView.tag;
    switch (type) {
        case OPlayerTypeVideo: {
            self.selectIndex = 0;
            self.playerType = OPlayerTypeVideo;
            
        }
            break;
        case OPlayerTypeVoice: {
            self.selectIndex = 1;
            self.playerType = OPlayerTypeVoice;
            
        }
            break;
        case OPlayerTypeOnline: {
            self.selectIndex = 2;
            self.playerType = OPlayerTypeOnline;
            
        }
            break;
        case OPlayerTypeSports: {
            self.selectIndex = 3;
            self.playerType = OPlayerTypeSports;
            
        }
            break;
        default:
            break;
    }
    [self updateUIState];
    
    
}

- (void)updateUIState
{
    self.videoLB.alpha = (_selectIndex == self.videoView.tag - 10)? 1 : 0.5;
    self.videoSubLB.alpha = (_selectIndex == self.videoView.tag - 10)? 1 : 0.5;
    
    self.voiceLB.alpha = (_selectIndex == self.voiceView.tag - 10)? 1 : 0.5;
    self.voiceSubLB.alpha = (_selectIndex == self.voiceView.tag - 10)? 1 : 0.5;
    
//    self.onlineLB.alpha = (_selectIndex == self.onlineView.tag - 10)? 1 : 0.5;
//    self.onlineSubLB.alpha = (_selectIndex == self.onlineView.tag - 10)? 1 : 0.5;
//
//    self.onlineSubLB.alpha = (_selectIndex == self.onlineView.tag - 10)? 1 : 0.5;
//    self.onlineSubLB.alpha = (_selectIndex == self.onlineView.tag - 10)? 1 : 0.5;
    
    self.videoImageView.alpha = (_selectIndex == self.voiceView.tag - 10)? 0.5 : 1;
    self.audioImageView.alpha = (_selectIndex == self.voiceView.tag - 10)? 1 : 0.5;
    
    self.videoView.layer.contents = (_selectIndex == self.videoView.tag - 10)?(id)[UIImage imageNamed:@"publish_ placeholder_selected"].CGImage :(id)[UIImage imageNamed:@"publish_ placeholder_normal"].CGImage;
    self.voiceView.layer.contents = (_selectIndex == self.voiceView.tag - 10)?(id)[UIImage imageNamed:@"publish_ placeholder_selected"].CGImage :(id)[UIImage imageNamed:@"publish_ placeholder_normal"].CGImage;
    self.onlineView.layer.contents = (_selectIndex == self.onlineView.tag - 10)?(id)[UIImage imageNamed:@"publish_ placeholder_selected"].CGImage :(id)[UIImage imageNamed:@"publish_ placeholder_normal"].CGImage;
    self.sportsView.layer.contents = (_selectIndex == self.sportsView.tag - 10)?(id)[UIImage imageNamed:@"publish_ placeholder_selected"].CGImage :(id)[UIImage imageNamed:@"publish_ placeholder_normal"].CGImage;
    
    self.videoView.layer.cornerRadius = (_selectIndex == self.videoView.tag - 10) ? 8 : 0;
    self.videoView.layer.borderWidth = (_selectIndex == self.videoView.tag - 10) ? 2 : 0;
    self.videoView.layer.borderColor = (_selectIndex == self.videoView.tag - 10) ? [UIColor sl_colorWithHexString:@"#0DBE9E"].CGColor : [UIColor whiteColor].CGColor;
    self.videoView.layer.masksToBounds = (_selectIndex == self.videoView.tag - 10) ? YES :NO;
    
    self.voiceView.layer.cornerRadius = (_selectIndex == self.voiceView.tag - 10) ? 8 : 0;
    self.voiceView.layer.borderWidth = (_selectIndex == self.voiceView.tag - 10) ? 2 : 0;
    self.voiceView.layer.borderColor = (_selectIndex == self.voiceView.tag - 10) ? [UIColor sl_colorWithHexString:@"#0DBE9E"].CGColor : [UIColor whiteColor].CGColor;
    self.voiceView.layer.masksToBounds = (_selectIndex == self.voiceView.tag - 10) ? YES :NO;
    
//    self.onlineView.layer.cornerRadius = (_selectIndex == self.onlineView.tag - 10) ? 8 : 0;
//    self.onlineView.layer.borderWidth = (_selectIndex == self.onlineView.tag - 10) ? 2 : 0;
//    self.onlineView.layer.borderColor = (_selectIndex == self.onlineView.tag - 10) ? [UIColor sl_colorWithHexString:@"#0DBE9E"].CGColor : [UIColor whiteColor].CGColor;
//    self.onlineView.layer.masksToBounds = (_selectIndex == self.onlineView.tag - 10) ? YES :NO;
//
//    self.sportsView.layer.cornerRadius = (_selectIndex == self.sportsView.tag - 10) ? 8 : 0;
//    self.sportsView.layer.borderWidth = (_selectIndex == self.sportsView.tag - 10) ? 2 : 0;
//    self.sportsView.layer.borderColor = (_selectIndex == self.sportsView.tag - 10) ? [UIColor sl_colorWithHexString:@"#0DBE9E"].CGColor : [UIColor whiteColor].CGColor;
//    self.sportsView.layer.masksToBounds = (_selectIndex == self.sportsView.tag - 10) ? YES :NO;
    
}

- (void)openVideoController
{
    NSDictionary *userDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kUserInfo];
    LiveDefaultConfig *config = [[LiveDefaultConfig alloc]init];
    config.ownerRoomId = [NSString stringWithFormat:@"%@",[userDict objectForKey:kUid]];
    config.localUid = [NSString stringWithFormat:@"%@",[userDict objectForKey:kUid]];
    config.anchroMainUid = [NSString stringWithFormat:@"%@",[userDict objectForKey:kUid]];
    self.config = config;
    [self createChatRoom];
    
}

- (void)openAudioController
{
    NSDictionary *userDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kUserInfo];
    LiveDefaultConfig *config = [[LiveDefaultConfig alloc]init];
    config.ownerRoomId = [NSString stringWithFormat:@"%@",[userDict objectForKey:kUid]];
    config.localUid = [NSString stringWithFormat:@"%@",[userDict objectForKey:kUid]];
    
    config.anchroMainUid = [NSString stringWithFormat:@"%@",[userDict objectForKey:kUid]];
    self.config = config;
    [self createChatRoom];
    
}

//在线KTV
- (void)openOnlineController
{
//    KTVLiveViewController *vc = [[KTVLiveViewController alloc]init];
//    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)backAction:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//开播
- (IBAction)startLive:(UIButton *)sender
{
    
    switch (self.selectIndex) {
        case 0: //视频直播
            self.modeView.hidden = NO;
            break;
        case 1: //音频直播
            [self openAudioController];
            break;
        case 2: //唱歌娱乐
//            [self openOnlineController];
            break;
        case 3://球赛解说
            break;
        default:
            break;
    }
}
#pragma mark -主播创建聊天室
- (void)createChatRoom
{
    NSNumber *playerType = @(0);
    if (self.playerType == OPlayerTypeVideo) {
        playerType = @(1);
    } else if (self.playerType == OPlayerTypeVoice) {
        playerType = @(2);
    }
    
    NSDictionary *params = @{
        kUid:@([self.config.localUid integerValue]),
        kRType: playerType,
        kRPublishMode: @(self.modeType), // zhangjianping   1.rtc  2.cdn
//        pullurl
//        pushurl
    };
    
    
    LiveType type = LiveTypeVideo;
    if ([playerType isEqualToNumber:@(0)]) {
        type = LiveTypeVideo;
    } else if ([playerType isEqualToNumber:@(1)]) {
        type = LiveTypeAudio;
    }
    [[LivePresenter shareInstance] fetchChatRoomWithType:type params:params];
    
}

#pragma mark- 成功获取roomid
- (void)successChatRoom:(id)data withType:(LiveType)type
{
    [[LivePresenter shareInstance] destory];
    PublishMode mode = PUBLISH_STREAM_RTC;
    if (self.modeType == VideoPlayerModeCDN) {
       mode = PUBLISH_STREAM_CDN;
    }
    WeakSelf
//    self.isFirstShow = NO;
    YYLogDebug(@"%@",data);
    switch (self.playerType) {
        case OPlayerTypeVideo: {
            
            VideoLiveViewController *vc = [[VideoLiveViewController alloc]initWithAnchor:YES config:self.config pushMode:mode];
             vc.liveRoomInfo = (LiveRoomInfoModel *)data;
             vc.url = vc.liveRoomInfo.RUpStream;
             vc.isResponsBackblock = YES;
             vc.backBlock = ^{
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
                 YYLogDebug(@"[MouseLive-StartViewController] backBlock");
            };
            self.config.ownerRoomId = ((LiveRoomInfoModel *)data).RoomId;
            [self.navigationController pushViewController:vc animated:YES];
            
        }
            break;
        case OPlayerTypeVoice: {
            AudioLiveViewController *vc = [[AudioLiveViewController alloc]initWithAnchor:YES config:self.config pushMode:mode];
            vc.liveRoomInfo = (LiveRoomInfoModel *)data;
            vc.isResponsBackblock = YES;
            vc.backBlock = ^{
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
                YYLogDebug(@"[MouseLive-StartViewController] backBlock");
            };
            self.config.ownerRoomId = ((LiveRoomInfoModel *)data).RoomId;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        default:
            break;
    }
}

- (void)createRoomError:(NSString *)errorMessage
{
    [MBProgressHUD yy_showError:errorMessage];
}


@end
