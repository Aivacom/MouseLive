//
//  DataTableViewCellHeader.m
//  MouseLive
//
//  Created by 张建平 on 2020/2/28.
//  Copyright © 2020 sy. All rights reserved.
//

#import "DataTableViewCellHeader.h"
#import "Masonry.h"
#import "SYCommonMacros.h"
#import "YYCGUtilities.h"
#import "GobalViewBound.h"
#import "DataView.h"

@interface DataTableViewCellHeader() 

@property (nonatomic, strong) DataView *bgView;

@end


@implementation DataTableViewCellHeader

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)initViewWithFrame:(CGRect)frame
{
    self.frame = frame;
    [self addSubview:self.bgView];
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(0);
        make.right.equalTo(self).offset(0);
        make.height.equalTo(@(frame.size.height));
        make.width.equalTo(@(frame.size.width));
    }];
}



#pragma mark - get / set

- (UIView *)bgView
{
    if (!_bgView) {
        _bgView = [[DataView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        _bgView.backgroundColor = [UIColor whiteColor];
    }
    return _bgView;
}

@end
