//
//  LiveAnchorModel.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/3.
//  Copyright © 2020 sy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveAnchorModel : NSObject

/** 主播头像 */
@property (nonatomic, copy  ) NSString   *ACover;

/** 主播名 */
@property (nonatomic, copy  ) NSString   *AName;

/** 直播房间号码 */
@property (nonatomic, copy) NSString *ARoom;
/** 主播uid */
@property (nonatomic, copy) NSString *AId;

@end

NS_ASSUME_NONNULL_END
