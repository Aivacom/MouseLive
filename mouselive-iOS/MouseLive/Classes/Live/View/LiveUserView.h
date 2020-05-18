//
//  LiveUserView.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/5.
//  Copyright © 2020 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveUserModel.h"
#import "BaseLiveViewController.h"
typedef NS_ENUM(NSInteger,ManagementUserType){
    ManagementUserTypeAddAdmin,//升管
    ManagementUserTypeRemoveAdmin, // 降管
    ManagementUserTypeMute, // 禁言
    ManagementUserTypeUnmute, //解禁
    ManagementUserTypeKick,//剔出
    ManagementUserTypeOpenMirc, // 开麦
    ManagementUserTypeCloseMirc,//闭麦
    ManagementUserTypeDownMirc//下麦
};
typedef void (^ManagementUserBlock)(LiveUserModel * _Nullable userModel, ManagementUserType type,UIButton *sender);
NS_ASSUME_NONNULL_BEGIN

@interface LiveUserView : UIView
/***/
@property (nonatomic,assign)LiveType type;
@property (nonatomic, strong)LiveUserModel *model;
@property (nonatomic, assign) BOOL isAnchor;  // 当前操作的人是否主播，如果不是主播，不能操作全部禁言+管理员操作
@property (nonatomic, assign) BOOL isAdmin; // 当前操作的人是否管理员
+ (instancetype)userView;

@property(nonatomic, copy) void(^closeBlock)(void);
@property(nonatomic, copy) ManagementUserBlock managementBlock;


@end

NS_ASSUME_NONNULL_END
