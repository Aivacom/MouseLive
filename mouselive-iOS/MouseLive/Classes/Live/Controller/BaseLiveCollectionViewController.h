//
//  BaseLiveCollectionViewController.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/12.
//  Copyright © 2020 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveProtocol.h"
#import "LiveDefaultConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface BaseLiveCollectionViewController : UICollectionViewController
/**直播信息配置*/
@property(nonatomic, strong)LiveDefaultConfig *config;

@property (nonatomic,assign)LiveType liveType;
/**是否是主播*/
@property (nonatomic,assign)BOOL isAnchor;
/** 直播 */
@property (nonatomic, strong) NSArray *lives;
/** 当前的index */
@property (nonatomic, assign) NSUInteger currentIndex;
- (void)registerCell;
@end

NS_ASSUME_NONNULL_END
