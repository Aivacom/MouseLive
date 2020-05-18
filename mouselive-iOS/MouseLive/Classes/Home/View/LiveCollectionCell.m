//
//  LiveCollectionCell.m
//  MouseLive
//
//  Created by 张建平 on 2020/3/2.
//  Copyright © 2020 sy. All rights reserved.
//

#import "LiveCollectionCell.h"
#import "Masonry.h"
#import "SYCommonMacros.h"
#import "YYCGUtilities.h"
#import <UIImage+YYWebImage.h>
#import "LiveListItem.h"
//#import <UIImageView+YYWebImage.h>
#import "VideoLiveViewController.h"
#import "AudioLiveViewController.h"
#import "HomeViewController.h"
#import "LivePresenter.h"
#import "SYAppId.h"

@interface LiveCollectionCell() <LivePresenterDelegate>

@property (nonatomic, strong) UILabel* userNameLabel;
@property (nonatomic, strong) UILabel *roomNameLabel;
@property (nonatomic, strong) UILabel *viewerCountLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *peopleIcon;

@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *roomName;
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, assign) int viewerCount;
@property (nonatomic, copy) NSString *roomType;
@property (nonatomic, strong) LivePresenter *presenter;
@property (nonatomic, strong) UIViewController *targetVc;
@property (nonatomic, strong)LiveDefaultConfig *config;

@end


@implementation LiveCollectionCell


- (void)pushData:(id _Nullable)data;
{
    LiveListItem *item = (LiveListItem *)data;
    self.userName = item.userName;
    self.roomName = item.roomName;
    self.imageUrl = item.imageUrl;
    self.viewerCount = item.viewerCount;
    
    self.userNameLabel.text = self.userName;
    self.viewerCountLabel.text = [NSString stringWithFormat:@"%d", self.viewerCount];
    self.roomName = @"精彩直播等你来";
    self.roomNameLabel.text = self.roomName;
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame: frame]) {
        self.backgroundColor = [UIColor whiteColor];
        
        [self addSubview:self.imageView];
        [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(0);
            make.bottom.equalTo(self).offset(-23);
            make.left.equalTo(self).offset(0);
            make.right.equalTo(self).offset(0);
        }];
        
        UIView *titileBGView = [[UIView alloc] init];
        //设置view 背景渐变颜色
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[(__bridge id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0].CGColor, (__bridge id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6].CGColor];
        gradientLayer.locations = @[@0.0, @1.0];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(0, 1.0);
        gradientLayer.frame = CGRectMake(0, 0, (SCREEN_WIDTH - 24)/2, 30);
        [titileBGView.layer addSublayer:gradientLayer];
        [self addSubview:titileBGView];
        
        
        [titileBGView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@30);
            make.bottom.equalTo(self.imageView);
            make.left.equalTo(self.imageView);
            make.right.equalTo(self.imageView);
        }];
        
        [titileBGView addSubview:self.userNameLabel];
        [self.userNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.top.equalTo(@0);
            make.width.equalTo(@((SCREEN_WIDTH - 24)/4));
            make.left.equalTo(titileBGView).offset(4);
        }];
        [titileBGView addSubview:self.peopleIcon];
        [self.peopleIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(-4);
            make.centerY.equalTo(@0);
            make.size.mas_equalTo(CGSizeMake(10, 10));
        }];
        
        [titileBGView addSubview:self.viewerCountLabel];
        [self.viewerCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(@0);
            make.right.equalTo(self.peopleIcon.mas_left).offset(-2);
        }];
        
        [self addSubview:self.roomNameLabel];
        [self.roomNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.imageView.mas_bottom).offset(3);
            make.bottom.equalTo(@0);
            make.left.mas_equalTo(self.imageView.mas_left).offset(4);
            make.right.mas_equalTo(self.imageView.mas_right).offset(-4);
        }];
    }
    return self;
}

#pragma mark - action
- (void)click
{
    // TODO: for test. 跳转到 start 页面
    
    NSObject *target = self;
    while (target) {
        target = ((UIResponder *)target).nextResponder;
        if ([target isKindOfClass:[UIViewController class]]) {
            break;
        }
    }
    LiveDefaultConfig *config = [[LiveDefaultConfig alloc]init];
    config.localUid = [NSString stringWithFormat:@"%@", [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kUserInfo] objectForKey:kUid]];
    config.ownerRoomId = _roomModel.RoomId;
    config.anchroMainRoomId = _roomModel.RoomId;
    config.anchroMainUid = _roomModel.ROwner.Uid;
    self.roomType = _roomModel.RType;
    self.config = config;
    
    UIViewController *viewController = (UIViewController *)target;
    self.targetVc = viewController;
    [self checkRoomInfoSucess];
}


- (void)checkRoomInfoSucess
{
    [LivePresenter shareInstance].delegate = self;
    [[LivePresenter shareInstance] fetchRoomInfoWithType:[self.roomType isEqualToString:@"1"] ? LiveTypeVideo : LiveTypeAudio config:self.config success:nil failure:nil];
}

#pragma mark - LivePresenterDelegate 跳转页面
- (void)liveViewRoomInfo:(LiveRoomInfoModel *)roomInfo UserListDataSource:(NSArray<LiveUserModel *> *)data
{
  
    [[LivePresenter shareInstance] destory];
    YYLogDebug(@"[MouseLive LiveCollectionCell] LivePresenter delegate == nil");
    if ([roomInfo.RType isEqualToString:self.roomType]) {
        UIViewController *pushvc = nil;
        //视频聊天室
        if ([roomInfo.RType isEqualToString:@"1"]) {
            PublishMode mode = PUBLISH_STREAM_RTC;
            if (roomInfo.RPublishMode == 2) {
                mode = PUBLISH_STREAM_CDN;
            }
            VideoLiveViewController *vc = [[VideoLiveViewController alloc] initWithAnchor:NO config:self.config pushMode:mode];
            vc.liveRoomInfo = roomInfo;
            vc.url = roomInfo.RDownStream;
            pushvc = vc;
            [self.targetVc.navigationController pushViewController:pushvc animated:YES];
        } else if ([roomInfo.RType isEqualToString:@"2"]) {
            //音频聊天室
            AudioLiveViewController *vc = [[AudioLiveViewController alloc] initWithAnchor:NO config:self.config pushMode:PUBLISH_STREAM_RTC];
            vc.liveRoomInfo = roomInfo;
            pushvc = vc;
            [self.targetVc.navigationController pushViewController:pushvc animated:YES];
        }
    }else{
        [MBProgressHUD yy_showError:@"无效的房间信息"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyRefreshNew object:self.roomType];
    }
}

#pragma mark - set / get
//- (LivePresenter *)presenter
//{
//    if (!_presenter) {
//        _presenter = [[LivePresenter alloc]init];
//        [_presenter attachView:self];
//    }
//    return _presenter;
//}

- (UIImageView *)peopleIcon
{
    if (!_peopleIcon) {
        _peopleIcon = [[UIImageView alloc]init];
        _peopleIcon.image = [UIImage imageNamed:@"home_pepple_count"];
    }
    return _peopleIcon;
}

- (UILabel *)userNameLabel
{
    if (!_userNameLabel) {
        _userNameLabel = [[UILabel alloc] init];
        _userNameLabel.text = self.userName;
        _userNameLabel.textColor = [UIColor sl_red:255 green:255 blue:255 alpha:0.7];
        [_userNameLabel setTextAlignment:NSTextAlignmentLeft];
        [_userNameLabel setFont:[UIFont fontWithName:FONT_Regular size:12.0f]];
    }
    return _userNameLabel;
}

- (UILabel *)roomNameLabel
{
    if (!_roomNameLabel) {
        _roomNameLabel = [[UILabel alloc] init];
        _roomNameLabel.textColor = COLOR_TEXT_BLACK;
        [_roomNameLabel setTextAlignment:NSTextAlignmentLeft];
        [_roomNameLabel setFont:[UIFont fontWithName:FONT_Regular size:16.0f]];
    }
    return _roomNameLabel;
}

- (UILabel *)viewerCountLabel
{
    if (!_viewerCountLabel) {
        _viewerCountLabel = [[UILabel alloc] init];
        _viewerCountLabel.textColor = [UIColor sl_red:255 green:255 blue:255 alpha:0.7];
        _viewerCountLabel.text = [NSString stringWithFormat:@"%d", self.viewerCount];
        [_viewerCountLabel setTextAlignment:NSTextAlignmentRight];
        [_viewerCountLabel setFont:[UIFont fontWithName:FONT_Semibold size:14.0f]];
    }
    
    return _viewerCountLabel;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        UIImage *im = [UIImage imageNamed:@"home_live_ placeholder"];
        _imageView = [[UIImageView alloc] initWithImage:im];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
    }
    return _imageView;
}

- (void)setRoomModel:(LiveRoomInfoModel *)roomModel
{
    _roomModel = roomModel;
    [self.imageView yy_setImageWithURL:[NSURL URLWithString:roomModel.RCover] placeholder:[UIImage imageNamed:@"home_live_ placeholder"]];
    self.roomNameLabel.text = roomModel.RName;
    self.viewerCountLabel.text = [NSString stringWithFormat:@"%@", roomModel.RCount];
    self.userNameLabel.text = roomModel.ROwner.NickName;
    
}
@end
