//
//  LiveUserListView.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/5.
//  Copyright © 2020 sy. All rights reserved.
//

#import "LiveUserListView.h"
#import "LiveAnchorListTableViewCell.h"
#import "SYHummerManager.h"


@interface LiveUserListView()<UITableViewDelegate, UITableViewDataSource,LiveProtocol>
/** 全员禁言*/
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *shutupBtn;
/** 用户列表*/
@property (nonatomic, weak) IBOutlet UITableView *userTableView;
@property (nonatomic, strong) NSArray *anchorDataArray;
@property (nonatomic, strong) NSArray *userDataArray;

@property (nonatomic, strong)LivePresenter *presenter;
@property (nonatomic, assign)LiveType liveType;

// 需要的是主播列表，还是观众列表
@property (nonatomic, assign)BOOL needAnchor;

@end
static  NSString *reuseIdentifier = @"LiveAnchorListTableViewCell";
@implementation LiveUserListView
//- (LivePresenter *)presenter
//{
//    if (!_presenter) {
//        _presenter = [[LivePresenter alloc]init];
//        [_presenter attachView:self];
//    }
//    return _presenter;
//}

+ (instancetype)liveUserListView
{
    return [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil].lastObject;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.userTableView.delegate = self;
    self.userTableView.dataSource = self;
    self.userTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.userTableView registerNib:[UINib nibWithNibName:NSStringFromClass([LiveAnchorListTableViewCell class]) bundle:nil] forCellReuseIdentifier:reuseIdentifier];
    [self.shutupBtn setTitle:NSLocalizedString(@"Ban All",nil) forState:UIControlStateNormal];
    [self.shutupBtn setTitle:NSLocalizedString(@"Unban All",nil) forState:UIControlStateSelected];

    self.userTableView.rowHeight = 68.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.needAnchor) {
        return self.anchorDataArray.count;
    } else {
        return self.userDataArray.count;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LiveAnchorListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (self.needAnchor) {
        [cell configCellWithModel:self.anchorDataArray[indexPath.row]];
    } else {
        [cell configCellWithModel:self.userDataArray[indexPath.row]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id model = nil;
    if (self.needAnchor) {
        //主播pk
        model = self.anchorDataArray[indexPath.row];
        
    } else {
        //观众列表管理
        model = self.userDataArray[indexPath.row];
    }
 
    if (self.clickBlock) {
        
        self.clickBlock(self.needAnchor, model);
    }
    
}

- (void)refreshViewWithType:(LiveType)type needAnchor:(BOOL)needAnchor isAnchor:(BOOL)isAnchor config:(LiveDefaultConfig *)config userInfoList:(LiveUserInfoList *)userInfoList
{

    self.needAnchor = needAnchor;
    WeakSelf
    if (needAnchor) {
        [userInfoList getAnchorList:^(NSDictionary<NSString *,LiveAnchorModel *> * _Nonnull data) {
            NSMutableArray *dataArr = [[NSMutableArray alloc] init];
            [dataArr addObjectsFromArray:[data allValues]];
            LiveAnchorModel *selfAnthor = nil;
            for (LiveAnchorModel *anthor in dataArr) {
                if (anthor.AId == config.localUid) {
                    selfAnthor = anthor;
                    
                }
            }
            if (selfAnthor) {
                [dataArr removeObject:selfAnthor];
            }
            [self liveViewAnchorListDataSource: dataArr];
        }];
    } else {
        [userInfoList getUserList:^(NSDictionary<NSString *,LiveUserModel *> * _Nonnull data) {
            [self liveViewRoomInfo:nil UserListDataSource:[weakSelf sort:[data allValues] isAnchor:isAnchor config:config]];
        }];
    }
    self.liveType = type;
    if (self.needAnchor) {
        self.shutupBtn.hidden = YES;
        //@"在线主播"
        self.titleLabel.text = NSLocalizedString(@"Broadcasters",nil);
    }
    else {
        //@"在线观众"
        self.titleLabel.text = NSLocalizedString(@"Audience",nil);
        
        if (isAnchor) {
            self.shutupBtn.hidden = NO;
        }
        else {
            self.shutupBtn.hidden = YES;
        }
    }
    self.shutupBtn.selected = [SYHummerManager sharedManager].isAllMuted;
}

#pragma mark - LiveProtocol

- (NSArray <LiveUserModel *> *)sort:(NSArray <LiveUserModel *> *)data isAnchor:(BOOL)isAnchor config:(LiveDefaultConfig *)config
{

    NSMutableArray <LiveUserModel *>* main = [[NSMutableArray <LiveUserModel *> alloc] init];
    NSMutableArray <LiveUserModel *> *second = [[NSMutableArray <LiveUserModel *> alloc] init];
    
    LiveUserModel *anchorModel = [[LiveUserModel alloc] init];
    anchorModel.isAnchor = YES;
    anchorModel.Cover = self.roomInfoModel.ROwner.Cover;
    anchorModel.isAdmin = YES;
    anchorModel.NickName = self.roomInfoModel.ROwner.NickName;
    anchorModel.Uid = self.roomInfoModel.ROwner.Uid;
    anchorModel.roomId = self.roomInfoModel.RoomId;
    
    if (data.count > 0) {
        LiveUserModel *selfModel = nil;
        
        for (LiveUserModel* m in data) {
            if (![m.Uid isEqualToString:config.localUid]) {
                if ([m.Uid isEqualToString:config.anchroMainUid]) {
                    // 主播
                    continue;
                }
                else {
                    if (m.isAdmin) {
                        // 管理员
                        [main addObject:m];
                    }
                    else {
                        // 观众
                        [second addObject:m];
                    }
                }
            }
            else {
                selfModel = m;
                selfModel.isMuted = [SYHummerManager sharedManager].isMuted;
                selfModel.isAdmin = [SYHummerManager sharedManager].isAdmin;
            }
        }
        
        [main addObjectsFromArray:second];
        
        if (isAnchor) {
            LiveUserModel *model = LOCAL_USER;
            model.isAnchor = YES;
            [main insertObject:model atIndex:0];
        }
        else {
            if (!selfModel) {
                selfModel = LOCAL_USER;
                selfModel.isMuted = [SYHummerManager sharedManager].isMuted;
                selfModel.isAdmin = [SYHummerManager sharedManager].isAdmin;
            }
            [main insertObject:selfModel atIndex:0];
            [main insertObject:anchorModel atIndex:0];
        }
    }
    else {
        if (isAnchor) {
            LiveUserModel *model = LOCAL_USER;
            model.isAnchor = YES;
            [main insertObject:model atIndex:0];
        }
    }
    
    return [main copy];
}

- (void)liveViewRoomInfo:(LiveRoomInfoModel *)roomInfo UserListDataSource:(NSArray <LiveUserModel *> *)data
{
    self.userDataArray = data;
    [self.userTableView reloadData];
    
}
- (void)liveViewAnchorListDataSource:(NSArray<LiveAnchorModel *> *)data
{
    self.anchorDataArray = data;
    [self.userTableView reloadData];
}


- (IBAction)allMuteBtnClick:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (self.allMuteBlock) {
        self.allMuteBlock(![SYHummerManager sharedManager].isAllMuted);
    }
    for (LiveUserModel *model in self.userDataArray) {
        if (!model.isAnchor) {
            model.isMuted = sender.selected;
        }
    }
    [self.userTableView reloadData];
}


@end
