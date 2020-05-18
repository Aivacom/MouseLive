//
//  AudioMicStateController.m
//  MouseLive
//
//  Created by 张建平 on 2020/3/27.
//  Copyright © 2020 sy. All rights reserved.
//

#import "AudioMicStateController.h"
#import "SYThunderManagerNew.h"
#import "SYHummerManager.h"
#import "TaskQueue.h"

typedef enum : NSUInteger {
    AudioMicStateDidAllMicOff, // 处理全员禁麦/开麦
    AudioMicStateDidMicOn, // 某人打开麦克风
    AudioMicStateDidMicOff, // 某人关闭麦克风
    AudioMicStateDidMicOffSelfByAnchor, // 主播关闭本人的麦克风
    AudioMicStateDidMicOnSelfByAnchor, // 主播打开本人的麦克风
    AudioMicStateDidMicOffByAnchor, // 主播关闭其他人麦克风
    AudioMicStateDidMicOnByAnchor, // 主播打开其他人麦克风
    AudioMicStateMicOffByAnchor, // 主播主动关闭某人麦克风，在主播端
    AudioMicStateMicOnByAnchor, // 主播主动打开某人麦克风，在主播端
    AudioMicStateMicOffBySelf, // 连麦者自己闭麦
    AudioMicStateMicOnBySelf, // 连麦者自己开麦
} AudioMicStateType;

@interface AudioMicStateController() <TaskQueueDelegate>

@property (nonatomic, strong) TaskQueue* taskQueue;

@end

@implementation AudioMicStateController

- (instancetype)init
{
    if  (self = [super init]) {
        self.taskQueue = [[TaskQueue alloc] initWithName:@"AudioMicStateController"];
        [self.taskQueue start];
    }
    return self;
}

- (void)destory
{
    [self.taskQueue stop];
}

- (void)executeWithReq:(NSNumber *)req object:(id)object
{
    NSDictionary *resp = (NSDictionary *)object;
    int stateType = [[resp objectForKey:@"type"] intValue];
    switch (stateType) {
        case AudioMicStateDidAllMicOff:
            [self handleDidAllMicOff_Internal:[[resp objectForKey:@"micOff"] boolValue]];
            break;
        case AudioMicStateDidMicOn:
            [self handleDidMicOnWithUid_Internal:[resp objectForKey:@"uid"]];
            break;
        case AudioMicStateDidMicOff:
            [self handleDidMicOffWithUid_Internal:[resp objectForKey:@"uid"]];
            break;
        case AudioMicStateDidMicOffSelfByAnchor:
            [self handleDidMicOffSelfByAnchor_Internal];
            break;
        case AudioMicStateDidMicOnSelfByAnchor:
            [self handleDidMicOnSelfByAnchor_Internal];
            break;
        case AudioMicStateDidMicOffByAnchor:
            [self handleDidMicOffByAnchorWith_Internal:[resp objectForKey:@"uid"]];
            break;
        case AudioMicStateDidMicOnByAnchor:
            [self handleDidMicOnByAnchorWith_Internal:[resp objectForKey:@"uid"]];
            break;
        case AudioMicStateMicOffByAnchor:
            [self handleMicOffWithUid_Internal:[resp objectForKey:@"uid"]];
            break;
        case AudioMicStateMicOnByAnchor:
            [self handleMicOnWithUid_Internal:[resp objectForKey:@"uid"]];
            break;
        case AudioMicStateMicOffBySelf:
            [self handleMicOffBySelf_Internal];
            break;
        case AudioMicStateMicOnBySelf:
            [self handleMicOnBySelf_Internal];
            break;
        default:
            break;
    }
}

/// 处理全员禁麦/开麦
/// @param micOff yes - 禁麦； no - 开麦
- (void)handleDidAllMicOff:(BOOL)micOff
{
    YYLogDebug(@"[AudioMicStateController] handleDidAllMicOff micOff:%d", micOff);
    NSDictionary *req = @{@"type":@(AudioMicStateDidAllMicOff), @"micOff":@(micOff)};
    [self.taskQueue addTaskWithObject:req delegate:self];
}

/// 某人打开麦克风
/// @param uid 用户 id
- (void)handleDidMicOnWithUid:(NSString *)uid
{
    YYLogDebug(@"[AudioMicStateController] handleDidMicOnWithUid uid:%@", uid);
    NSDictionary *req = @{@"type":@(AudioMicStateDidMicOn), @"uid":uid};
    [self.taskQueue addTaskWithObject:req delegate:self];
}

/// 某人关闭麦克风
/// @param uid 用户 id
- (void)handleDidMicOffWithUid:(NSString *)uid
{
    YYLogDebug(@"[AudioMicStateController] handleDidMicOffWithUid uid:%@", uid);
    NSDictionary *req = @{@"type":@(AudioMicStateDidMicOff), @"uid":uid};
    [self.taskQueue addTaskWithObject:req delegate:self];
}

/// 主播关闭本人的麦克风
- (void)handleDidMicOffSelfByAnchor
{
    YYLogDebug(@"[AudioMicStateController] handleDidMicOffSelfByAnchor");
    NSDictionary *req = @{@"type":@(AudioMicStateDidMicOffSelfByAnchor)};
    [self.taskQueue addTaskWithObject:req delegate:self];
}

/// 主播打开本人的麦克风
- (void)handleDidMicOnSelfByAnchor
{
    YYLogDebug(@"[AudioMicStateController] handleDidMicOnSelfByAnchor");
    NSDictionary *req = @{@"type":@(AudioMicStateDidMicOnSelfByAnchor)};
    [self.taskQueue addTaskWithObject:req delegate:self];
}

/// 主播关闭其他人麦克风
/// @param uid 用户 id
- (void)handleDidMicOffByAnchorWith:(NSString *)uid
{
    YYLogDebug(@"[AudioMicStateController] handleDidMicOffByAnchorWith uid:%@", uid);
    NSDictionary *req = @{@"type":@(AudioMicStateDidMicOffByAnchor), @"uid":uid};
    [self.taskQueue addTaskWithObject:req delegate:self];
}


/// 主播打开其他人麦克风
/// @param uid 用户 id
- (void)handleDidMicOnByAnchorWith:(NSString *)uid
{
    YYLogDebug(@"[AudioMicStateController] handleDidMicOnByAnchorWith uid:%@", uid);
    NSDictionary *req = @{@"type":@(AudioMicStateDidMicOnByAnchor), @"uid":uid};
    [self.taskQueue addTaskWithObject:req delegate:self];
}

/// 主播主动关闭某人，在主播方
/// @param uid 关闭麦克风的 uid
- (void)handleMicOffWithUid:(NSString *)uid
{
    YYLogDebug(@"[AudioMicStateController] handleMicOffWithUid uid:%@", uid);
    NSDictionary *req = @{@"type":@(AudioMicStateMicOffByAnchor), @"uid":uid};
    [self.taskQueue addTaskWithObject:req delegate:self];
}

/// 主播主动打开某人，在主播方
/// @param uid 打开麦克风的 uid
- (void)handleMicOnWithUid:(NSString *)uid
{
    YYLogDebug(@"[AudioMicStateController] handleMicOnWithUid uid:%@", uid);
    NSDictionary *req = @{@"type":@(AudioMicStateMicOnByAnchor), @"uid":uid};
    [self.taskQueue addTaskWithObject:req delegate:self];
}

/// 连麦者自己闭麦
- (void)handleMicOffBySelf
{
    YYLogDebug(@"[AudioMicStateController] handleMicOffBySelf");
    NSDictionary *req = @{@"type":@(AudioMicStateMicOffBySelf)};
    [self.taskQueue addTaskWithObject:req delegate:self];
}


/// 连麦者自己开麦
- (void)handleMicOnBySelf
{
    YYLogDebug(@"[AudioMicStateController] handleMicOnBySelf");
    NSDictionary *req = @{@"type":@(AudioMicStateMicOnBySelf)};
    [self.taskQueue addTaskWithObject:req delegate:self];
}

#pragma mark - 真正的操作

- (void)handleDidAllMicOff_Internal:(BOOL)micOff
{
    YYLogDebug(@"[AudioMicStateController] handleDidAllMicOff_Internal entry, micOff:%d", micOff);
    if (!self.isAnchor) {
        YYLogDebug(@"[AudioMicStateController] handleDidAllMicOff_Internal is viewer");
        if (micOff) {
            // 需要刷新头像下的 mic 图片为开麦图像
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyAllMicEnable object:@"NO"];
            
            YYLogDebug(@"[AudioMicStateController] handleDidAllMicOff_Internal kNotifyAllMicEnable, no");
            
            // 如果全员闭麦
            [[SYThunderManagerNew sharedManager] disableLocalAudio:YES haveVideo:NO];
            
            LiveUserModel *model = [self.audioContentView searchLiveUserWithUid:LoginUserUidString];
            if (model) {
                // 如果在麦上
                
                // 按钮要修改闭麦按钮，不能点击
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeAudioMicButtonState object:@"AllMicOff"];
                
                YYLogDebug(@"[AudioMicStateController] handleDidAllMicOff_Internal kNotifyChangeAudioMicButtonState, AllMicOff");
            }
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyAllMicEnable object:@"YES"];
            
            YYLogDebug(@"[AudioMicStateController] handleDidAllMicOff_Internal kNotifyAllMicEnable, yes");
            
            LiveUserModel *model = [self.audioContentView searchLiveUserWithUid:LoginUserUidString];
            if (model) {
                // 如果在麦上
                if (!self.isMicOffBySelf) {
                    [[SYThunderManagerNew sharedManager] disableLocalAudio:NO haveVideo:NO];
                    
                    // 需要刷新头像下的 mic 图片为开麦图像
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":LoginUserUidString,@"MicEnableByAnchor":@"1",@"SelfMicEnable":@"1"}];
                    
                    YYLogDebug(@"[AudioMicStateController] handleDidAllMicOff_Internal, kNotifyisMicEnable, local, MicEnableByAnchor:1, SelfMicEnable:1");
                    
                    // 按钮要修改开麦按钮，可以点击
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeAudioMicButtonState object:@"YES"];
                    
                    YYLogDebug(@"[AudioMicStateController] handleDidAllMicOff_Internal, kNotifyChangeAudioMicButtonState, yes");
                }
                else {
                    // 按钮要修改开麦按钮，可以点击
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeAudioMicButtonState object:@"NO"];
                }
            }
        }
    }
    else {
        YYLogDebug(@"[AudioMicStateController] handleDidAllMicOff_Internal is anchor");
        if (micOff) {
            // 需要刷新头像下的 mic 图片为开麦图像
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyAllMicEnable object:@"NO"];
            
            YYLogDebug(@"[AudioMicStateController] handleDidAllMicOff_Internal kNotifyAllMicEnable, no");
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyAllMicEnable object:@"YES"];
            
            YYLogDebug(@"[AudioMicStateController] handleDidAllMicOff_Internal kNotifyAllMicEnable, yes");
        }
    }
    YYLogDebug(@"[AudioMicStateController] handleDidAllMicOff_Internal exit");
}

/// 某人打开麦克风
/// @param uid 用户 id
- (void)handleDidMicOnWithUid_Internal:(NSString *)uid
{
    YYLogDebug(@"[AudioMicStateController] handleDidMicOnWithUid_Internal entry, uid:%@", uid);

    // 非本人开麦用户，需要刷新头像下的 mic 图片为开麦图像
    if ([uid isEqualToString: self.anchorUid]) {
        YYLogDebug(@"[AudioMicStateController] handleDidMicOnWithUid_Internal uid is anchor");

        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":uid,@"MicEnableByAnchor":@"1",@"SelfMicEnable":@"1"}];

        YYLogDebug(@"[AudioMicStateController] handleDidMicOnWithUid_Internal, kNotifyisMicEnable,  MicEnableByAnchor:1, SelfMicEnable:1");
    }
    else {
        YYLogDebug(@"[AudioMicStateController] handleDidMicOnWithUid_Internal uid is not anchor");

        dispatch_async(dispatch_get_main_queue(), ^{
            LiveUserModel *model = [self.audioContentView searchLiveUserWithUid:uid];
            if (model) {
                YYLogDebug(@"[AudioMicStateController] handleDidMicOnWithUid_Internal find model");
                if (model.MicEnable) {
                    YYLogDebug(@"[AudioMicStateController] handleDidMicOnWithUid_Internal model is not mic off by anchor");

                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":uid,@"MicEnableByAnchor":@"1",@"SelfMicEnable":@"1"}];

                    YYLogDebug(@"[AudioMicStateController] handleDidMicOnWithUid_Internal, kNotifyisMicEnable,  MicEnableByAnchor:1, SelfMicEnable:1");
                }
            }
        });
    }

    YYLogDebug(@"[AudioMicStateController] handleDidMicOnWithUid_Internal exit");
}


/// 某人关闭麦克风
/// @param uid 用户 id
- (void)handleDidMicOffWithUid_Internal:(NSString *)uid
{
    YYLogDebug(@"[AudioMicStateController] handleDidMicOffWithUid_Internal entry, uid:%@", uid);

    // 非本人闭麦用户，需要刷新头像下的 mic 图片为闭麦图像
    if ([uid isEqualToString: self.anchorUid]) {
        YYLogDebug(@"[AudioMicStateController] handleDidMicOffWithUid_Internal uid is anchor");

        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":uid,@"MicEnableByAnchor":@"1",@"SelfMicEnable":@"0"}];

        YYLogDebug(@"[AudioMicStateController] handleDidMicOffWithUid_Internal, kNotifyisMicEnable,  MicEnableByAnchor:1, SelfMicEnable:0");
    }
    else {
        YYLogDebug(@"[AudioMicStateController] handleDidMicOffWithUid_Internal uid is not anchor");

        dispatch_async(dispatch_get_main_queue(), ^{
            LiveUserModel *model = [self.audioContentView searchLiveUserWithUid:uid];
            if (model) {
                YYLogDebug(@"[AudioMicStateController] handleDidMicOffWithUid_Internal find model");
                if (model.MicEnable) {
                    YYLogDebug(@"[AudioMicStateController] handleDidMicOffWithUid_Internal model is not mic off by anchor");

                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":uid,@"MicEnableByAnchor":@"1",@"SelfMicEnable":@"0"}];

                    YYLogDebug(@"[AudioMicStateController] handleDidMicOffWithUid_Internal, kNotifyisMicEnable,  MicEnableByAnchor:1, SelfMicEnable:0");
                }
            }
        });
    }

    YYLogDebug(@"[AudioMicStateController] handleDidMicOffWithUid_Internal exit");
}


/// 主播关闭本人的麦克风
- (void)handleDidMicOffSelfByAnchor_Internal
{
    YYLogDebug(@"[AudioMicStateController] handleDidMicOffSelfByAnchor_Internal entry");
    
    // 主播关闭麦克风
    [[SYThunderManagerNew sharedManager] disableLocalAudio:YES haveVideo:NO];
    
    // 需要刷新头像下的 mic 图片为闭麦图像，自己改成黄色闭麦
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":LoginUserUidString,@"MicEnableByAnchor":@"0",@"SelfMicEnable":@"2"}];
    
    YYLogDebug(@"[AudioMicStateController] handleDidMicOffSelfByAnchor_Internal, kNotifyisMicEnable, local,  MicEnableByAnchor:0, SelfMicEnable:2");
    
    // 按钮要修改闭麦按钮，不能点击
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeAudioMicButtonState object:@"AllMicOff"];
    
    YYLogDebug(@"[AudioMicStateController] handleDidMicOffSelfByAnchor_Internal kNotifyChangeAudioMicButtonState, AllMicOff");
    
    YYLogDebug(@"[AudioMicStateController] handleDidMicOffSelfByAnchor_Internal exit");
}


/// 主播打开本人的麦克风
- (void)handleDidMicOnSelfByAnchor_Internal
{
    YYLogDebug(@"[AudioMicStateController] handleDidMicOnSelfByAnchor_Internal entry");
    
    if (!self.isMicOffBySelf) {
        
        YYLogDebug(@"[AudioMicStateController] handleDidMicOnSelfByAnchor_Internal, is not mic off by self");
        
        // 如果连麦，并且自己没有闭麦，就打开
        if (self.isLinkWithAnchor) {
            YYLogDebug(@"[AudioMicStateController] handleDidMicOnSelfByAnchor_Internal isLinkWithAnchor, start local audio");
            [[SYThunderManagerNew sharedManager] disableLocalAudio:NO haveVideo:NO];
        }

        // 需要刷新头像下的 mic 图片为开麦图像，主播已经放权由用户操作了
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":LoginUserUidString,@"MicEnableByAnchor":@"1",@"SelfMicEnable":@"1"}];
        
        YYLogDebug(@"[AudioMicStateController] handleDidMicOnSelfByAnchor_Internal, kNotifyisMicEnable, local,  MicEnableByAnchor:1, SelfMicEnable:1");
        
        // 按钮要修改开麦按钮，可以点击
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeAudioMicButtonState object:@"YES"];
        
        YYLogDebug(@"[AudioMicStateController] handleDidMicOnSelfByAnchor_Internal kNotifyChangeAudioMicButtonState, YES");
    }
    else {
        // 需要刷新头像下的 mic 图片，这里都要设置成不是主播操作了，因为主播已经把设置权限还给了用户，用户的 mic 显示就按照原来的显示即可
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":LoginUserUidString,@"MicEnableByAnchor":@"1",@"SelfMicEnable":@"0"}];
        
        YYLogDebug(@"[AudioMicStateController] handleDidMicOnSelfByAnchor_Internal, kNotifyisMicEnable, local,  MicEnableByAnchor:1, SelfMicEnable:0");
        
        // 按钮要修改开麦按钮，可以点击
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyChangeAudioMicButtonState object:@"NO"];
        
        YYLogDebug(@"[AudioMicStateController] handleDidMicOnSelfByAnchor_Internal kNotifyChangeAudioMicButtonState, NO");
    }
    
    YYLogDebug(@"[AudioMicStateController] handleDidMicOnSelfByAnchor_Internal exit");
}

/// 主播关闭其他人麦克风
/// @param uid 用户 id
- (void)handleDidMicOffByAnchorWith_Internal:(NSString *)uid
{
    YYLogDebug(@"[AudioMicStateController] handleDidMicOffByAnchorWith_Internal entry, uid:%@", uid);
    
    // 需要刷新头像下的 mic 图片为闭麦图像，自己改成黄色闭麦
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":uid,@"MicEnableByAnchor":@"0",@"SelfMicEnable":@"2"}];
    
    YYLogDebug(@"[AudioMicStateController] handleDidMicOffByAnchorWith_Internal, kNotifyisMicEnable,  MicEnableByAnchor:0, SelfMicEnable:2");
    
    YYLogDebug(@"[AudioMicStateController] handleDidMicOffByAnchorWith_Internal exit");
}


/// 主播打开其他人麦克风
/// @param uid 用户 id
- (void)handleDidMicOnByAnchorWith_Internal:(NSString *)uid
{
    YYLogDebug(@"[AudioMicStateController] handleDidMicOnByAnchorWith_Internal entry, uid:%@", uid);
    
    // 需要刷新头像下的 mic 图片，这里都要设置成不是主播操作了，因为主播已经把设置权限还给了用户，用户的 mic 显示就按照原来的显示即可
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":uid,@"MicEnableByAnchor":@"1",@"SelfMicEnable":@"2"}];
    
    YYLogDebug(@"[AudioMicStateController] handleDidMicOnByAnchorWith_Internal, kNotifyisMicEnable,  MicEnableByAnchor:1, SelfMicEnable:2");
    
    YYLogDebug(@"[AudioMicStateController] handleDidMicOnByAnchorWith_Internal exit");
}

/// 主播主动关闭某人，在主播方
/// @param uid 关闭麦克风的 uid
- (void)handleMicOffWithUid_Internal:(NSString *)uid
{
    YYLogDebug(@"[AudioMicStateController] handleMicOffWithUid_Internal uid:%@", uid);
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":uid,@"MicEnableByAnchor":@"0",@"SelfMicEnable":@"2",@"AnchorLocalLock":@"1"}];
    
    YYLogDebug(@"[AudioMicStateController] handleMicOffWithUid_Internal, kNotifyisMicEnable,  MicEnableByAnchor:0, SelfMicEnable:2, AnchorLocalLock:1");
}

/// 主播主动打开某人，在主播方
/// @param uid 打开麦克风的 uid
- (void)handleMicOnWithUid_Internal:(NSString *)uid
{
    YYLogDebug(@"[AudioMicStateController] handleMicOnWithUid_Internal uid:%@", uid);
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":uid,@"MicEnableByAnchor":@"1",@"SelfMicEnable":@"2",@"AnchorLocalLock":@"0"}];
    
    YYLogDebug(@"[AudioMicStateController] handleMicOnWithUid_Internal, kNotifyisMicEnable,  MicEnableByAnchor:1, SelfMicEnable:2, AnchorLocalLock:0");
}

/// 连麦者自己闭麦
- (void)handleMicOffBySelf_Internal
{
    YYLogDebug(@"[AudioMicStateController] handleMicOffBySelf_Internal");
    
    WeakSelf
    [self.liveBG disableLocalAudio:YES complete:^(NSError * _Nullable error) {
        weakSelf.isMicOffBySelf = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":LoginUserUidString,@"SelfMicEnable":@"0", @"MicEnableByAnchor":@"1"}];
    }];

    
    YYLogDebug(@"[AudioMicStateController] handleMicOffBySelf_Internal, kNotifyisMicEnable, local MicEnableByAnchor:1, SelfMicEnable:0");
}


/// 连麦者自己开麦
- (void)handleMicOnBySelf_Internal
{
    YYLogDebug(@"[AudioMicStateController] handleMicOnBySelf_Internal");
    
    WeakSelf
    [self.liveBG disableLocalAudio:NO complete:^(NSError * _Nullable error) {
        weakSelf.isMicOffBySelf = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyisMicEnable object:@{@"uid":LoginUserUidString,@"SelfMicEnable":@"1", @"MicEnableByAnchor":@"1"}];
    }];

    YYLogDebug(@"[AudioMicStateController] handleMicOnBySelf_Internal, kNotifyisMicEnable, local MicEnableByAnchor:1, SelfMicEnable:1");
}

@end
