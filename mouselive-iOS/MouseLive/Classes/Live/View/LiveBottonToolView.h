//
//  LiveBottonToolView.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/3.
//  Copyright © 2020 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveProtocol.h"
#import "LiveDefaultConfig.h"

typedef NS_ENUM(NSUInteger, LiveToolType) {
    LiveToolTypeMicr     = 1,      //麦克风  0
    LiveToolTypeLinkmicr = 2,  //主播pk 观众连麦
    LiveToolTypeSetting  = 3,   //设置   2
    LiveToolTypeFeedback = 4,  //反馈   3
    LiveToolTypeCodeRate = 5,  //码率
    LiveToolTypeAudioWhine = 6,//音频变声  1
};

NS_ASSUME_NONNULL_BEGIN

@interface LiveBottonToolView : UIView
- (instancetype)initWithAnchor:(BOOL)isAnchor liveType:(LiveType)type config:(LiveDefaultConfig *)config;
/** 点击工具栏  */
@property(nonatomic, copy)void (^clickToolBlock)(LiveToolType type,BOOL selected);

@property(nonatomic, copy) NSString *talkButtonTitle;
/**主播uid*/
@property(nonatomic, copy) NSString *anchorUid;

/**音聊房自己是否正在连麦中*/
@property(nonatomic, assign) BOOL localRuningMirc;

/**自己是否可以连麦 主播在连麦中不可以显示连麦按钮*/
@property(nonatomic, assign) BOOL mircEnable;
/**是否是cdn模式 是 可以连麦和PK 否 不可以连麦和PK*/
@property(nonatomic, assign) BOOL isCdnModel;
//刷新视频工具栏
- (void)refreshVideoToolView;
//刷新音频工具栏
- (void)refreshAudioToolView;
@end

NS_ASSUME_NONNULL_END
