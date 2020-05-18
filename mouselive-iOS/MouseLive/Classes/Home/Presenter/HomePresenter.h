//
//  HomePresenter.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/16.
//  Copyright © 2020 sy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HomeDataProtocol.h"
#import "LiveRoomInfoModel.h"


NS_ASSUME_NONNULL_BEGIN

@interface HomePresenter : NSObject

- (void)attachView:(id <HomeDataProtocol>)view;
- (void)fetchDataWithType:(LiveType)type;
//加载更多数据
- (void)fetchMoreDataWithType:(LiveType)type;

@end

NS_ASSUME_NONNULL_END
