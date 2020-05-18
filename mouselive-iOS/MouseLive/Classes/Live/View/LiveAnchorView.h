//
//  LiveAnchorView.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/2.
//  Copyright © 2020 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveRoomInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

//开播模式
typedef enum {
    PushModeType_RTC,//点击头像
    PushModeType_CDN //点击列表
}PushModeType;

//点击类型
typedef enum {
    IconClikTypeUserHeader,//点击头像
    IconClikTypeListBtn //点击列表
}IconClikType;

typedef void (^IconClickBlock)(IconClikType type,BOOL selected);

@interface LiveAnchorView : UIView
/** 主播 */
@property (nonatomic, strong) LiveRoomInfoModel *roomInfoModel;

@property (nonatomic, assign) PushModeType pushMode;

@property (nonatomic, assign) NSInteger peopleCount;

@property (nonatomic, copy) void(^quitBlock)(void);

@property (nonatomic, copy) IconClickBlock iconClickBlock;

+ (instancetype)liveAnchorView;


@end

NS_ASSUME_NONNULL_END
