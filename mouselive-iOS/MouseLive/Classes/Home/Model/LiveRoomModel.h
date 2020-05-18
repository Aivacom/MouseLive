//
//  LiveRoomModel.h
//  MouseLive
//
//  Created by 张建平 on 2020/3/23.
//  Copyright © 2020 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveRoomInfoModel.h"
#import "LiveUserModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LiveRoomModel : NSObject

@property (nonatomic, strong) LiveRoomInfoModel* RoomInfo;
@property (nonatomic, strong) NSArray<LiveUserModel*>* UserList;

@end

NS_ASSUME_NONNULL_END
