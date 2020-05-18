//
//  LiveHomeView.m
//  MouseLive
//
//  Created by 张建平 on 2020/2/29.
//  Copyright © 2020 sy. All rights reserved.
//

#import "LiveHomeView.h"
#import "LiveCollectionCell.h"
#import "Masonry.h"
#import "SYCommonMacros.h"
#import "YYCGUtilities.h"
#import "GobalViewBound.h"
#import "HttpService.h"
#import <MJRefresh.h>
#import "HomePresenter.h"

NSString *g_Cell = @"LiveCell";

@interface LiveHomeView() <UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource,HomeDataProtocol>

@property (nonatomic, strong) UICollectionView* collectionView;
@property (nonatomic, strong) id response;
@property (nonatomic) LiveHomeViewRole role;
@property (nonatomic) NSMutableDictionary *requestActionDic;
@property (nonatomic, strong)HomePresenter *presenter;
@property (nonatomic, strong) NSMutableArray<LiveRoomInfoModel *> *dataArray;

@end

@implementation LiveHomeView


- (instancetype)initWithFrame:(CGRect)frame role:(LiveHomeViewRole)role
{
    if (self = [super initWithFrame:frame]) {
        BOOL loginSucess = [[NSUserDefaults standardUserDefaults] objectForKey:kloginSucess];
        //登录成功才刷新列表
        if (loginSucess) {
            [self.presenter fetchDataWithType:(LiveType)role + 1];
        }
        self.role = role;
        [self initView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNew:) name:kNotifyRefreshNew object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewAndDelOld:) name:kNotifyRefreshNewAndDelOld object:nil];
    }
    return self;
}

- (void)refreshViewAndDelOld:(NSNotification *)notifation
{
    // 删除房间号
    NSString *roomid = (NSString *)notifation.object;
    if (roomid) {
        for (LiveRoomInfoModel* model in self.dataArray) {
            if ([model.RoomId isEqualToString:roomid]) {
                [self.dataArray removeObject:model];
                break;
            }
        }
        [self.collectionView reloadData];
    }
}

- (void)refreshNew:(NSNotification *)notifation
{
    [_collectionView.mj_header beginRefreshing];
}

- (void)initView
{
    // 添加collectionView
    [self addSubview:self.collectionView];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(0);
        make.left.equalTo(self).offset(0);
        make.height.equalTo(@(self.frame.size.height));
        make.width.equalTo(@(self.frame.size.width));
    }];
}

#pragma mark - UICollectionViewDelegateFlowLayout

// 返回cell的尺寸大小
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    // 每行 2 个
    return CGSizeMake((SCREEN_WIDTH - 24) / 2 , (SCREEN_WIDTH - 24) / 2 + 23);      // 让每个cell尺寸都不一样
}

// 返回cell之间行间隙
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 8;
}


// 返回cell之间列间隙
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 8;
}


// 设置上左下右边界缩进
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(8, 8, 8, 8);
}


#pragma mark - UICollectionViewDataSource

// 返回Section个数
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


// 返回cell个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    
    return self.dataArray.count;
}


// 返回cell内容
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    // 创建cell (重用)
    LiveCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:g_Cell forIndexPath:indexPath];
    LiveRoomInfoModel *model = self.dataArray[indexPath.row];
    cell.roomModel = model;
    return cell;
}

#pragma mark - UICollectionViewDelegate

// 选中某个cell
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    LiveCollectionCell *cell = (LiveCollectionCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell click];
}

#pragma mark - request
//- (void)sendLiveListRequest {
//    [HttpService getLiveList:nil onComplete:^(LiveListResponse* resp) {
//        if (resp.error.code == 0) {
//            self.response = resp;
//            [self refreshView];
//        }
//    }];
//}
//
//- (void)sendVoiceListRequest {
//}
//
//- (void)sendLogin {
//    LoginUserRequest* req = [[LoginUserRequest alloc] init];
//    req.uid = @"fsafsa";
//
//    [HttpService login:req onComplete:^(LiveListResponse* resp) {
//        if (resp.error.code == 0) {
//
//            // TODO: 获取 uid + roomid
//            self.response = resp;
//            [self refreshView];
//        }
//    }];
//}
//
//- (void)sendRequest {
//    // 如果是第一次登陆，走另外一个请求
//    NSString* uid = [NSUserDefaults standardUserDefaults].uid;
//    if ([uid  isEqual: @""]) {
//        // 发送登陆请求
//        return;
//    }
//
//    SEL reqAction;
//    [(NSValue*)[self.requestActionDic objectForKey:@(self.role)] getValue:&reqAction];
//
//    if ([self respondsToSelector:reqAction]) {
//        [self performSelector:reqAction withObject:nil];
//    }
//}

#pragma mark - 懒加载

- (void)refreshView
{
    [self.presenter fetchDataWithType:(LiveType)(self.role + 1)];
}

- (void)addRefresh
{
    __weak __typeof(self) weakSelf = self;
    
    // 下拉刷新
    _collectionView.mj_header= [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf.presenter fetchDataWithType:(LiveType)(weakSelf.role + 1)];
    }];
    
    // 上拉刷新
    _collectionView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        [weakSelf.presenter fetchMoreDataWithType:(LiveType)(weakSelf.role + 1)];
    }];
    
}

- (UICollectionView *)collectionView
{
    if (_collectionView == nil) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.frame collectionViewLayout:flowLayout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.showsVerticalScrollIndicator = NO;
        [_collectionView registerClass:[LiveCollectionCell class] forCellWithReuseIdentifier:g_Cell];
        
        [self addRefresh];
    }
    
    return _collectionView;
}

- (NSValue *)createActionWithSelector:(SEL)action
{
    return [NSValue valueWithBytes:&action objCType:@encode(SEL)];
}

- (NSDictionary *)requestActionDic
{
    if (!_requestActionDic) {
        _requestActionDic = [[NSMutableDictionary alloc] init];
//        [_requestActionDic setObject:[self createActionWithSelector:@selector(sendLiveListRequest)] forKey:@(LiveHomeViewRole_Live)];
//        [_requestActionDic setObject:[self createActionWithSelector:@selector(sendVoiceListRequest)] forKey:@(LiveHomeViewRole_Voice)];
    }
    return _requestActionDic;
}

- (HomePresenter *)presenter
{
    if (!_presenter) {
        _presenter = [[HomePresenter alloc]init];
        [_presenter attachView:self];
        
    }
    return _presenter;
}

- (void)homeViewDataSource:(NSArray<LiveRoomInfoModel *> *)data withType:(LiveType)type
{
    [_collectionView.mj_header endRefreshing];
    [_collectionView.mj_footer endRefreshing];
    self.dataArray = [data mutableCopy];
    [self.collectionView reloadData];
    
}
- (void)showIndicator
{
    
}
- (void)hideIndicator
{
    [_collectionView.mj_header endRefreshing];
    [_collectionView.mj_footer endRefreshing];
}
- (void)showEmptyView
{
   [_collectionView.mj_header endRefreshing];
    [_collectionView.mj_footer endRefreshing];
}
@end
