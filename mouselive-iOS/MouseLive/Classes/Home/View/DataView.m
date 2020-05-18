//
//  DataView.m
//  MouseLive
//
//  Created by 张建平 on 2020/2/29.
//  Copyright © 2020 sy. All rights reserved.
//

#import "DataView.h"
#import "FSScrollContentView.h"
#import "LiveHomeView.h"
#import "OtherView.h"
#import "Masonry.h"
#import "SYCommonMacros.h"
#import "YYCGUtilities.h"
#import "GobalViewBound.h"

@interface DataView() <FSPageContentViewDelegate,FSSegmentTitleViewDelegate>

@property (nonatomic, strong) FSPageContentView *pageContentView;
@property (nonatomic, strong) FSSegmentTitleView *titleView;

@property (nullable, nonatomic, strong) NSArray *pageTile;

@property (nonatomic, assign) int titleHeight;

@property (nonatomic, strong)NSMutableArray *childVC;

@end

@implementation DataView
- (NSMutableArray *)childVC
{
    if (!_childVC) {
        _childVC = [[NSMutableArray alloc]init];
    }
    return _childVC;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {

        self.titleHeight = [GobalViewBound sharedInstance].dataViewTitleHeight;
        self.pageTile = @[NSLocalizedString(@"Video", nil), NSLocalizedString(@"Audio", nil), NSLocalizedString(@"KTV", nil), NSLocalizedString(@"Commentary", nil)];
        
        self.titleView = [[FSSegmentTitleView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), self.titleHeight) titles:self.pageTile delegate:self indicatorType:FSIndicatorTypeCustom];
        self.titleView.titleSelectFont = [UIFont fontWithName:FONT_Semibold size:16.0];
        
        self.titleView.selectIndex = 0;
        self.titleView.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.titleView];
        [self.titleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(0);
            make.right.equalTo(self).offset(0);
            make.width.equalTo(@(frame.size.width));
            make.height.equalTo(@(self.titleHeight));
        }];
        
        LiveHomeView *live = [[LiveHomeView alloc]initWithFrame:CGRectMake(0, self.titleHeight, self.frame.size.width, self.frame.size.height - [GobalViewBound sharedInstance].tarBarHeight) role:LiveHomeViewRole_Live];
        [self.childVC addObject:live];

        LiveHomeView *voice = [[LiveHomeView alloc]initWithFrame:CGRectMake(0, self.titleHeight, self.frame.size.width, self.frame.size.height - [GobalViewBound sharedInstance].tarBarHeight) role:LiveHomeViewRole_Voice];
        [self.childVC addObject:voice];
        
        OtherView *other = [[OtherView alloc] init];
        [self.childVC addObject:other];

        other = [[OtherView alloc] init];
        [self.childVC addObject:other];

        CGRect pageFrame = CGRectMake(0, self.titleHeight, self.frame.size.width, self.frame.size.height - [GobalViewBound sharedInstance].tarBarHeight);
        self.pageContentView = [[FSPageContentView alloc]initWithFrame:pageFrame childVCs:self.childVC parentVC:self delegate:self];
        self.pageContentView.contentViewCurrentIndex = 0;
        [self addSubview:self.pageContentView];

        [self.pageContentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(self.titleHeight);
            make.height.equalTo(@(self.frame.size.height - [GobalViewBound sharedInstance].tarBarHeight));
            make.width.equalTo(@(self.frame.size.width));
        }];
    }
    return self;
}

#pragma mark --
- (void)FSSegmentTitleView:(FSSegmentTitleView *)titleView startIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex
{
    self.pageContentView.contentViewCurrentIndex = endIndex;
    if (endIndex == 0 || endIndex == 1) {
        LiveHomeView *view = self.childVC[endIndex];
        [view refreshView];
    }
}

- (void)FSContenViewDidEndDecelerating:(FSPageContentView *)contentView startIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex
{
    self.titleView.selectIndex = endIndex;
}

#pragma mark HomeDataProtocol


@end
