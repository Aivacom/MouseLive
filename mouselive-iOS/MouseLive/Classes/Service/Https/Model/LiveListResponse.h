//
//  LiveListResponse.h
//  MouseLive
//
//  Created by 张建平 on 2020/3/3.
//  Copyright © 2020 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ErrorResponse.h"
#import "LiveLIstItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface LiveListResponse : NSObject

@property (nonatomic, readonly) Error* error;
@property (nonatomic, readonly) NSMutableArray<LiveListItem *> *Item;


+ (LiveListResponse *)test;

@end

NS_ASSUME_NONNULL_END
