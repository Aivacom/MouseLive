//
//  HomeViewController.m
//  MouseLive
//
//  Created by 张建平 on 2020/2/27.
//  Copyright © 2020 sy. All rights reserved.
//

// TODO: 这段主界面我一定要重新写，做成可以定制化的，嵌套多个 table 和 collection 的，用 swift 写

#import "HomeViewController.h"
#import "Masonry.h"
#import "SYCommonMacros.h"
#import "YYCGUtilities.h"
#import "GobalViewBound.h"
#import "BannerTableViewCell.h"
#import "DataTableViewCellHeader.h"
#import "AFNetworkReachabilityManager.h"
#import "LivePresenter.h"


typedef NS_ENUM(NSUInteger, TableViewCellType) {
    TableViewCellType_BannerCell = 0,
    TableViewCellType_DataCell,
};

static NSString *g_BannerCell = @"BannerCell";
static NSString *g_DataCellHeader = @"DataCellHeader";

@interface HomeViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, assign) int dataCellHeaderHeight;

@property (nonatomic, assign) int dataCellHeight;

@property (nonatomic, strong) NSMutableArray *taskArray;

@property (nonatomic, strong) UIAlertController *alertVC;


@end

@implementation HomeViewController
- (void)afNetworkStatusChanged:(NSNotification *)notify
{
    NSNumber *ReachabilityNotificationStatus = (NSNumber *)[notify.userInfo objectForKey:AFNetworkingReachabilityNotificationStatusItem];
    //首次登陆成功后断网
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kloginSucess]) {
         if ([ReachabilityNotificationStatus isEqualToNumber:@0] || [ReachabilityNotificationStatus isEqualToNumber:@3]) {
               [self showAlert];
         } else {
             [self dismissViewControllerAnimated:YES completion:nil];
             //连接网络后刷新列表
               [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyRefreshNew object:nil];
         }
    }
}

- (void)dealloc
{
    YYLogDebug(@"[MouseLive-App] HomeViewController dealloc");
    [HttpService sy_httpRequestCancelWithArray:self.taskArray];
}

//登陆失败弹框提示
- (void)showAlert
{
    
    self.alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"The network is abnormal, please check the network connection",nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:self.alertVC animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dataCellHeaderHeight = SCREEN_HEIGHT + (50 - [GobalViewBound sharedInstance].dataViewTitleHeight + 9) - [GobalViewBound sharedInstance].tarBarHeight - [GobalViewBound sharedInstance].statusBarHeight;
    self.dataCellHeight = 0;
    [self initView];
    
}

- (void)initView
{
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(0);
        make.top.equalTo(self.view).offset(- StatusBarHeight);
        make.left.right.mas_equalTo(0);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate

// cell高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // indexPath.section 可以判断是那个 section
    switch (indexPath.section) {
        case TableViewCellType_BannerCell:
            return BannerCellHeight;
        case TableViewCellType_DataCell:
            return self.dataCellHeight;
        default:
            break;
    }
    return 0;
}

// Header高度
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case  TableViewCellType_BannerCell:
            return 0;

        case TableViewCellType_DataCell:
            // 返回 header 的高
            return self.dataCellHeaderHeight;

        default:
            break;
    }
    
    // 如果没有就返回 0， 代表没有
    return 0;
}

// 选中了某个cell
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    BannerTableViewCell *cell = (BannerTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
//    NSLog(@"选中 cell = %d", cell.index);
}


#pragma mark - UITableViewDataSource

// Section数量
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}


// 对应Section中cell的个数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case  TableViewCellType_BannerCell:     // 数字组
            return 1;
            
        case TableViewCellType_DataCell:     // 字母组
            return 0;
            
        default:
            break;
    }
    
    return 0;
}

- (UIView *)dataCellHeader:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    DataTableViewCellHeader *view = (DataTableViewCellHeader *)[tableView dequeueReusableCellWithIdentifier:g_DataCellHeader];
    if (!view) {
        view = [[DataTableViewCellHeader alloc] init];
    }
    [view initViewWithFrame:CGRectMake(0, 0,SCREEN_WIDTH, self.dataCellHeaderHeight)];
    return view;
}

// 返回 header cell 的 view
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case  TableViewCellType_BannerCell:     // 数字组
            return nil;
                
        case TableViewCellType_DataCell:     // 字母组
            // 如果是 header，创建 header 并返回
            return [self dataCellHeader:tableView viewForHeaderInSection:section];

        default:
            break;
    }

    
    return nil;
}

- (UITableViewCell *)banner:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BannerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:g_BannerCell forIndexPath:indexPath];
    
    return cell;
}

- (UITableViewCell *)firstCell:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (UITableViewCell *)defaultCell:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

// 创建 cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    // 设置cell相关属性
    switch (indexPath.section) {
        case TableViewCellType_BannerCell:
            cell = [self banner:tableView cellForRowAtIndexPath:indexPath];
            break;
            
        case TableViewCellType_DataCell:
            cell = [self firstCell:tableView cellForRowAtIndexPath:indexPath];
            break;
            
        default:
            cell = [self defaultCell:tableView cellForRowAtIndexPath:indexPath];
            break;
    }

    // 去掉选择后高亮
    if (cell) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // 返回cell
   return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.tableView) {
        CGFloat offY = scrollView.contentOffset.y;
        if (offY >= BannerCellHeight) {
            // 禁止向上滑
            scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, BannerCellHeight);
        }
    }
}

#pragma mark - 懒加载

- (UITableView *)tableView
{
    if (_tableView == nil) {
        // 实例化一个UITableView
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [GobalViewBound sharedInstance].screenWidth, [GobalViewBound sharedInstance].screenHeight) style:UITableViewStylePlain];
        
        // 注册一个cell
        [_tableView registerClass:[BannerTableViewCell class] forCellReuseIdentifier:g_BannerCell];
        
        [_tableView registerClass:[DataTableViewCellHeader class] forHeaderFooterViewReuseIdentifier:g_DataCellHeader];
        
        /** 去除tableview 右侧滚动条 */
        _tableView.showsVerticalScrollIndicator = NO;
        
        /** 去掉分割线 */
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        // 设置代理
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    
    return _tableView;
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(afNetworkStatusChanged:) name:AFNetworkingReachabilityDidChangeNotification object:nil];

}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -- get / set
- (NSMutableArray *)taskArray
{
    if (!_taskArray) {
        _taskArray = [[NSMutableArray alloc] init];
    }
    return _taskArray;
}

@end
