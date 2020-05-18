//
//  HomeDataProtocol.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/16.
//  Copyright © 2020 sy. All rights reserved.
//

#import "LiveRoomInfoModel.h"
typedef NS_ENUM(NSInteger,LiveType) {
  LiveTypeVideo = 1,
  LiveTypeAudio,
  LiveTypeKTV,
  LiveTypeCommentary
};

NS_ASSUME_NONNULL_BEGIN

@protocol HomeDataProtocol <NSObject>

@required

- (void)homeViewDataSource:(NSArray <LiveRoomInfoModel *> *)data withType:(LiveType)type;
- (void)showIndicator;

- (void)hideIndicator;

- (void)showEmptyView;
@end

NS_ASSUME_NONNULL_END
