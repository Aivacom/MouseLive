//
//  LiveHomeView.h
//  MouseLive
//
//  Created by 张建平 on 2020/2/29.
//  Copyright © 2020 sy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LiveHomeViewRole) {
    LiveHomeViewRole_Live = 0,
    LiveHomeViewRole_Voice = 1,
};

@interface LiveHomeView : UIView

- (instancetype)initWithFrame:(CGRect)frame role:(LiveHomeViewRole)role;
- (void)refreshView;
@end

NS_ASSUME_NONNULL_END
