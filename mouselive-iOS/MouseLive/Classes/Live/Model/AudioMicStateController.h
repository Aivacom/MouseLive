//
//  AudioMicStateController.h
//  MouseLive
//
//  Created by 张建平 on 2020/3/27.
//  Copyright © 2020 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioContentView.h"
#import "LiveBG.h"

NS_ASSUME_NONNULL_BEGIN

@interface AudioMicStateController : NSObject

@property (nonatomic, assign) BOOL isAnchor; // 本人是否是主播
@property (nonatomic, assign) BOOL isLinkWithAnchor;  // 本人是否是在连麦中。暂时没用
// 音频房是否是本人操作开麦/闭麦
@property (nonatomic, assign) BOOL isMicOffBySelf;
@property (nonatomic, weak) AudioContentView* audioContentView;
@property (nonatomic, weak) LiveBG* liveBG;
@property (nonatomic, copy) NSString* anchorUid;  // 主播


/// 处理全员禁麦/开麦
/// @param micOff yes - 禁麦； no - 开麦
- (void)handleDidAllMicOff:(BOOL)micOff;

/// 某人打开麦克风
/// @param uid 用户 id
- (void)handleDidMicOnWithUid:(NSString*)uid;

/// 某人关闭麦克风
/// @param uid 用户 id
- (void)handleDidMicOffWithUid:(NSString*)uid;


/// 主播关闭本人的麦克风
- (void)handleDidMicOffSelfByAnchor;


/// 主播打开本人的麦克风
- (void)handleDidMicOnSelfByAnchor;

/// 主播关闭其他人麦克风
/// @param uid 用户 id
- (void)handleDidMicOffByAnchorWith:(NSString*)uid;


/// 主播打开其他人麦克风
/// @param uid 用户 id
- (void)handleDidMicOnByAnchorWith:(NSString*)uid;


/// 主播主动关闭某人，在主播方
/// @param uid 关闭麦克风的 uid
- (void)handleMicOffWithUid:(NSString*)uid;

/// 主播主动打开某人，在主播方
/// @param uid 打开麦克风的 uid
- (void)handleMicOnWithUid:(NSString*)uid;


/// 连麦者自己闭麦
- (void)handleMicOffBySelf;


/// 连麦者自己开麦
- (void)handleMicOnBySelf;

- (void)destory;

@end

NS_ASSUME_NONNULL_END
