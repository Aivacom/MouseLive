//
//  SettingViewController.m
//  MouseLive
//
//  Created by 张建平 on 2020/2/27.
//  Copyright © 2020 sy. All rights reserved.
//

#import "SettingViewController.h"
#import "Masonry.h"
#import "SYCommonMacros.h"
#import "YYCGUtilities.h"
#import "GobalViewBound.h"
#import "LiveUserModel.h"
#import "LogoUIView.h"


#define     VIEW_WIDTH      [UIScreen mainScreen].bounds.size.width
#define     VIEW_HEIGHT     [UIScreen mainScreen].bounds.size.height

@interface SettingViewController ()

@property (nonatomic, strong) LogoUIView *logoView;
@property (nonatomic, strong) UILabel *uidLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *headerImageView;

@end

@implementation SettingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initView];
}

- (void)initView
{
    self.view.backgroundColor = [UIColor whiteColor];
    self.logoView.hidden = NO;
    [self.headerImageView yy_setImageWithURL:[NSURL URLWithString:LOCAL_USER.Cover] placeholder:PLACEHOLDER_IMAGE];
    self.nameLabel.text = LOCAL_USER.NickName;
    self.uidLabel.text = [@"UID:" stringByAppendingString:LOCAL_USER.Uid];
    //    [self.view addSubview:self.titleLabel];
    //    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.top.equalTo(self.view).offset(300);
    //        make.left.equalTo(self.view).offset(100);
    //        make.height.equalTo(@(50));
    //        make.width.equalTo(@(200));
    //    }];
}

- (UIImageView *)headerImageView
{
    if (!_headerImageView) {
        _headerImageView = [[UIImageView alloc]init];
        [self.view addSubview:_headerImageView];
        [_headerImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(50);
            make.top.mas_equalTo(self.logoView.mas_bottom).offset(60);
            make.size.mas_equalTo(CGSizeMake(80, 80));
        }];
    }
    return _headerImageView;
}
- (UILabel *)uidLabel
{
    if (!_uidLabel) {
        _uidLabel = [[UILabel alloc] init];
        [self.view addSubview:_uidLabel];
        [_uidLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.nameLabel);
            make.top.mas_equalTo(self.nameLabel.mas_bottom).offset(5);
        }];
        _uidLabel.textColor = [UIColor lightGrayColor] ;
        [_uidLabel setTextAlignment:NSTextAlignmentCenter];
        [_uidLabel setFont:[UIFont systemFontOfSize:14]];
    }
    return _uidLabel;
}
- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        [self.view addSubview:_nameLabel];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.headerImageView.mas_right).offset(10);
            make.top.mas_equalTo(self.headerImageView).offset(20);
        }];
        _nameLabel.textColor = [UIColor blackColor] ;
        [_nameLabel setTextAlignment:NSTextAlignmentCenter];
        [_nameLabel setFont:[UIFont systemFontOfSize:17]];
    }
    return _nameLabel;
}

- (LogoUIView *)logoView
{
    if (!_logoView) {
        _logoView = [[LogoUIView alloc]init];
        [self.view addSubview:_logoView];
        [_logoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.mas_equalTo(0);
            make.height.mas_equalTo(BannerCellHeight);
        }];
    }
    return _logoView;
}
@end
