//
//  LiveUserListView.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/5.
//  Copyright © 2020 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LivePresenter.h"
#import "LiveDefaultConfig.h"
#import "LiveUserInfoList.h"
#import "LiveRoomInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ClickCellBlock)(BOOL isAnchor, id model);
typedef void (^AllMuteBlock)(BOOL);

@interface LiveUserListView : UIView
@property (nonatomic, copy)ClickCellBlock clickBlock;
@property (nonatomic, copy)AllMuteBlock allMuteBlock; // 是否全部禁言
@property (nonatomic, weak)LiveRoomInfoModel* roomInfoModel;

+ (instancetype)liveUserListView;
- (void)refreshViewWithType:(LiveType)type needAnchor:(BOOL)needAnchor isAnchor:(BOOL)isAnchor config:(LiveDefaultConfig *)config userInfoList:(LiveUserInfoList*)userInfoList;

@end

NS_ASSUME_NONNULL_END
