//
//  HomePresenter.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/16.
//  Copyright © 2020 sy. All rights reserved.
//

#import "HomePresenter.h"

@interface HomePresenter()
@property (nonatomic, weak) id<HomeDataProtocol> attachView;
@property (nonatomic, assign) NSInteger Offset;
@property (nonatomic, strong) NSMutableArray *taskArray;

@end

@implementation HomePresenter

- (void)attachView:(id<HomeDataProtocol>)view
{
    self.Offset = 0;
    self.attachView = view;
}

- (void)dealloc
{
    YYLogDebug(@"[MouseLive-App] HomePresenter dealloc");
    [HttpService sy_httpRequestCancelWithArray:self.taskArray];
}

- (void)fetchDataWithType:(LiveType)type
{
    id uid = [[NSUserDefaults standardUserDefaults]objectForKey:kUserInfo][kUid];
    if (!uid) {
        uid = @0;
    }
    
    NSDictionary *params = @{
        kUid:uid,
        kRType:@(type),
        kOffset:@(0),   // zhangjianping 写默认 0
        kLimit:@20
    };
    
    [self.attachView showIndicator];
    
    
    int taskId = [HttpService sy_httpRequestWithType:SYHttpRequestKeyType_RoomList params:params success:^(int taskId, id  _Nullable respObjc) {
        [self.taskArray removeObject:@(taskId)];
        [self.attachView hideIndicator];
        if (![respObjc objectForKey:kData]) {
            return;
        }
        if ( [[respObjc objectForKey:kData][kRoomList] isKindOfClass:[NSNull class]]) {
        [self.attachView homeViewDataSource:@[] withType:type];
            return;
        }
        if ([[respObjc objectForKey:kCode] isEqual:@(ksuccessCode.longLongValue)]) {
            NSArray *RoomListArray = [respObjc objectForKey:kData][kRoomList];
            NSArray *dataArray = [LiveRoomInfoModel mj_objectArrayWithKeyValuesArray:RoomListArray];
            [self.attachView homeViewDataSource:dataArray withType:type];
        }
        
    } failure:^(int taskId, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
        [self.attachView hideIndicator];
        [self.taskArray removeObject:@(taskId)];
    }];
    
    [self.taskArray addObject:@(taskId)];
}

- (void)fetchMoreDataWithType:(LiveType)type
{
    self.Offset += 21;
    [self fetchDataWithType:type];
}

#pragma mark - get / set
- (NSMutableArray *)taskArray
{
    if (!_taskArray) {
        _taskArray = [[NSMutableArray alloc] init];
    }
    return _taskArray;
}

@end
