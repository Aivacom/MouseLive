//
//  AudioContentView.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/6.
//  Copyright © 2020 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveUserModel.h"
#import "RoomOwnerModel.h"
#import "LiveRoomInfoModel.h"

typedef void(^AudioAllMicOffBlock)(BOOL);
typedef void(^CloseMicBlock)(LiveUserModel *model);
typedef void (^RunningMusicBlock)(BOOL isOn);
typedef void (^AudioIconClickBlock) (BOOL selected);


@interface AudioContentView : UIView
@property (nonatomic, weak) IBOutlet UICollectionView *contentView;

@property (nonatomic, copy) void(^quitBlock)(void);
@property (nonatomic, copy) AudioIconClickBlock iconClickBlock;



/**上麦人员数据源*/
@property (nonatomic, strong)NSMutableArray<LiveUserModel *> *dataArray;
/**主播数据模型*/
@property (nonatomic, strong) LiveRoomInfoModel *roomInfoModel;
@property (nonatomic, assign) NSInteger peopleCount;
@property (nonatomic, copy)CloseMicBlock closeOtherMicBlock; // 请其他人下麦
@property (nonatomic, copy)AudioAllMicOffBlock allMicOffBlock; // 全部禁麦
@property (nonatomic, copy)RunningMusicBlock musicBlock; // 全部禁麦
@property (nonatomic) BOOL volumShowState;
@property (nonatomic) BOOL isAnchor;
/**是否在播放音乐*/
@property (nonatomic, assign)BOOL isRunningMusic;

+ (AudioContentView *)audioContentView;

- (void)refreshView;

- (LiveUserModel *)searchLiveUserWithUid:(NSString *)uid;
@end


