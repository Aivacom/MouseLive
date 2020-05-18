//
//  RoomOwnerModel.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/16.
//  Copyright © 2020 sy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RoomOwnerModel : NSObject

@property (nonatomic,copy)NSString *Uid;
@property (nonatomic,copy)NSString *NickName;
@property (nonatomic,copy)NSString *Cover;

// 当前用户和谁连麦，如果是和主播连麦，就是主播 uid
@property (nonatomic, copy) NSString *LinkUid;

// 当前用户和谁连麦，如果是和主播连麦，就是主播 roomid
@property (nonatomic, copy) NSString *LinkRoomId;

/**主播是否正在连麦或pk*/
@property (nonatomic,assign)BOOL isRuningMirc;

@property (nonatomic,assign)BOOL MicEnable;  // 主播把其他人禁麦/开麦

@property (nonatomic, assign) BOOL SelfMicEnable; // 用户自己开麦/闭麦，默认是开麦

@end

NS_ASSUME_NONNULL_END
