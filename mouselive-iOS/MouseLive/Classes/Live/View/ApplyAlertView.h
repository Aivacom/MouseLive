//
//  LiveUserView.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/5.
//  Copyright © 2020 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveUserModel.h"
#import "VideoLiveViewController.h"

typedef NS_ENUM(NSInteger, ApplyActionType) {
    ApplyActionTypeAgree,
    ApplyActionTypeReject
};

typedef void (^ApplyAlertBlock)(ApplyActionType type, NSString *uid, UIButton *button);
NS_ASSUME_NONNULL_BEGIN

@interface ApplyAlertView : UIView
+ (instancetype)applyAlertView;

@property(nonatomic,strong)id model;
@property(nonatomic, copy) ApplyAlertBlock applyBlock;
@property(nonatomic, assign)LiveType livetype;

@end

NS_ASSUME_NONNULL_END
