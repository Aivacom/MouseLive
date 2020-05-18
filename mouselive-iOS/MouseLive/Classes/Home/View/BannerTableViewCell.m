//
//  BannerTableViewCell.m
//  MouseLive
//
//  Created by 张建平 on 2020/2/28.
//  Copyright © 2020 sy. All rights reserved.
//

#import "BannerTableViewCell.h"
#import "Masonry.h"
#import "SYCommonMacros.h"
#import "YYCGUtilities.h"
#import "GobalViewBound.h"
#import "LogoUIView.h"

@interface BannerTableViewCell() 

@property (nonatomic, strong) LogoUIView* logoView;

@end

@implementation BannerTableViewCell

- (void)pushData:(id _Nullable)data;
{
    
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setFrame:(CGRect)frame
{
    frame.size.width = SCREEN_WIDTH;
    
    [self addSubview:self.logoView];
    [self.logoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(0);
        make.left.equalTo(self).offset(0);
        make.bottom.equalTo(self).offset(0);
        make.right.equalTo(self).offset(0);
    }];
    
    self.backgroundColor = [UIColor whiteColor];
    [super setFrame:frame];
}

- (void)withByData:(NSDictionary *)data
{

}

#pragma mark - action


#pragma mark - get / set

- (LogoUIView *)logoView
{
    if (!_logoView) {
        _logoView = [[LogoUIView alloc] init];
    }
    return _logoView;
}


@end
