//
//  ErrorResponse.h
//  MouseLive
//
//  Created by 张建平 on 2020/3/3.
//  Copyright © 2020 sy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Error : NSObject

@property (nonatomic) int code;
@property (nonatomic) NSString* msg;

@end

NS_ASSUME_NONNULL_END
