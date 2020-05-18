//
//  LiveCollectionCell.h
//  MouseLive
//
//  Created by 张建平 on 2020/3/2.
//  Copyright © 2020 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveRoomInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

//extern NSString * const LiveCellTitle;          // 房间 title
//extern NSString * const LiveCellRoomId;          // 房间 id
//extern NSString * const LiveCellTitle;          // 房间 title
//extern NSString * const LiveCellTitle;          // 房间 title

@interface LiveCollectionCell : UICollectionViewCell

@property (nonatomic,strong)LiveRoomInfoModel *roomModel;

- (void)click;



@end

NS_ASSUME_NONNULL_END
