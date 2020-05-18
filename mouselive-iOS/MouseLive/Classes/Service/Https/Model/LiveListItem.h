//
//  LiveListItem.h
//  MouseLive
//
//  Created by 张建平 on 2020/3/3.
//  Copyright © 2020 sy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveListItem : NSObject

@property (nonatomic, copy) NSString* imageUrl;
@property (nonatomic, copy) NSString* userName;
@property (nonatomic, copy) NSString* roomName;
@property (nonatomic) int viewerCount;
@property (nonatomic, copy) NSString* roomId;
@property (nonatomic, copy) NSString* pullUrl;

@end

NS_ASSUME_NONNULL_END
