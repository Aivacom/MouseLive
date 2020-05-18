//
//  OtherView.m
//  MouseLive
//
//  Created by 张建平 on 2020/2/29.
//  Copyright © 2020 sy. All rights reserved.
//

#import "OtherView.h"
#import "Masonry.h"

@interface OtherView()

@property (nonatomic, strong) UILabel* titleLabel;

@end

@implementation OtherView

- (instancetype)init
{
    if (self = [super init]) {
        self.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.titleLabel];
//        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(self).offset(200);
//            make.left.equalTo(self).offset(100);
//            make.height.equalTo(@(50));
//            make.width.equalTo(@(200));
//        }];
    }
    return self;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"===待开发...";
        _titleLabel.textColor = [UIColor blackColor] ;
        [_titleLabel setTextAlignment:NSTextAlignmentCenter];
        [_titleLabel setFont:[UIFont systemFontOfSize:24]];
    }
    return _titleLabel;
}

@end
