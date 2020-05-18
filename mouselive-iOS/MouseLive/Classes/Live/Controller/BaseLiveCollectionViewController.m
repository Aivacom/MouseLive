//
//  BaseLiveCollectionViewController.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/12.
//  Copyright © 2020 sy. All rights reserved.
//

#import "BaseLiveCollectionViewController.h"
#import "LiveFlowLayout.h"
#import "NLinRefreshGifHeader.h"
#import <IQKeyboardManager.h>
#import "LiveUserView.h"
#import "LiveUserListView.h"
#import "ApplyAlertView.h"



@interface BaseLiveCollectionViewController ()

/**观众列表*/
@property (nonatomic, weak)LiveUserListView *userListView;
//申请连麦
@property (nonatomic, strong)ApplyAlertView *applyView;
@end

@implementation BaseLiveCollectionViewController

static NSString * const reuseIdentifier = @"Cell";


- (void)viewWillAppear: (BOOL)animated
{
    //关闭自动键盘
    [IQKeyboardManager sharedManager].enable = NO;
    [IQKeyboardManager sharedManager].toolbarTintColor = [UIColor blackColor];
    [IQKeyboardManager sharedManager].shouldShowToolbarPlaceholder = YES;
    self.navigationController.navigationBar.hidden = YES;
}


- (instancetype)init
{
    return [super initWithCollectionViewLayout:[[LiveFlowLayout alloc] init]];
}

- (LiveDefaultConfig *)config
{
    if (!_config) {
        _config = [[LiveDefaultConfig alloc]init];
    }
    return _config;
}

- (LiveUserListView *)userListView
{
    if (!_userListView) {
        LiveUserListView *userListView = [LiveUserListView liveUserListView];
        [self.collectionView addSubview:userListView];
        _userListView = userListView;
        [userListView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(@0);
            make.centerY.equalTo(@(SCREEN_HEIGHT/2 + USERLIST_H /2));
            make.width.equalTo(@(SCREEN_WIDTH));
            make.height.equalTo(@(USERLIST_H));
        }];

        _userListView.transform = CGAffineTransformMakeTranslation(0, - USERLIST_H);


    }
    return _userListView;
}
- (ApplyAlertView *)applyView
{
    if (!_applyView) {
        _applyView = [ApplyAlertView applyAlertView];
        [self.collectionView addSubview:_applyView];
        [_applyView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(@0);
            make.centerY.equalTo(@-100);
            make.width.equalTo(@(USERVIEW_W));
            make.height.equalTo(@(ApplyView_H));
        }];
        _applyView.transform = CGAffineTransformMakeScale(0.3, 0.3);
        typeof (self) weakSelf = self;
        [_applyView setCloseBlock:^{
            [UIView animateWithDuration:0.5 animations:^{
                weakSelf.applyView.transform = CGAffineTransformMakeScale(0.3, 0.3);
            } completion:^(BOOL finished) {
                [weakSelf.applyView removeFromSuperview];
                weakSelf.applyView = nil;
            }];
        }];

    }
    return _applyView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.contentInset = UIEdgeInsetsMake(- StatusBarHeight, 0, 0, 0);
    [self registerCell];
    NLinRefreshGifHeader *header = [NLinRefreshGifHeader headerWithRefreshingBlock:^{
        [self.collectionView.mj_header endRefreshing];
        self.currentIndex ++;
        if (self.currentIndex == self.lives.count) {
            self.currentIndex = 0;
        }
        [self.collectionView reloadData];
    }];
    header.automaticallyChangeAlpha = YES;
    header.stateLabel.hidden = NO;
    [header setTitle:@"下拉切换另一个主播" forState:MJRefreshStatePulling];
    [header setTitle:@"下拉切换另一个主播" forState:MJRefreshStateIdle];
    self.collectionView.mj_header = header;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hiddenUserList) name:kNotifyClickUser object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clickUserList:) name:kNotifyClickUserList object:nil];
}

#pragma mark - 注册cell
- (void)registerCell
{
    [self.collectionView registerClass:[UITableViewCell class] forCellWithReuseIdentifier:reuseIdentifier];

}
#pragma mark -  隐藏观众列表页
- (void)hiddenUserList
{
    [self hidenUserListView];
}
//#pragma mark -  点击了列表
//- (void)clickUserList:(NSNotification *)notify{
//    NSString *typeStr = notify.object;
//    [UIView animateWithDuration:0.3 animations:^{
//        self.userListView.transform = CGAffineTransformMakeTranslation(0, - USERLIST_H);
//        if ([typeStr isEqualToString:@"userList" ]) {
//            [self.userListView refreshViewWithType:self.liveType anchor:NO];
//        }else{
//            [self.userListView refreshViewWithType:self.liveType anchor:self.isAnchor];
//        }
//    }];
//}
#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{

    return 1;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    
    return cell;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [UIView animateKeyframesWithDuration:0.1 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
        [scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    } completion:nil];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self hidenUserListView];
}

#pragma mark - 隐藏用户列表
- (void)hidenUserListView
{
    [UIView animateWithDuration:0.3 animations:^{
          self.userListView.transform = CGAffineTransformIdentity;
          [self.userListView removeFromSuperview];
          self.userListView = nil;
      }];
}

@end
