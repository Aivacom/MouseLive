//
//  LiveCodeRateView.h
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/4.
//  Copyright © 2020 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkQualityStauts.h"
#import "BaseLiveViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface LiveCodeRateView : UIView
@property (weak, nonatomic) IBOutlet UILabel *upQualityLabel;
@property (weak, nonatomic) IBOutlet UILabel *upLabel;
@property (weak, nonatomic) IBOutlet UILabel *upDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *downQualityLabel;
@property (weak, nonatomic) IBOutlet UILabel *downLabel;
@property (weak, nonatomic) IBOutlet UILabel *downDetailLabel;

+ (instancetype)liveCodeRateView;

@property (nonatomic, assign)LiveType type;
@property (nonatomic, copy)NSString *uid;
@property (nonatomic, copy)NSString *userDetailString;
@property (nonatomic,strong) NetworkQualityStauts *qualityModel;
@end

NS_ASSUME_NONNULL_END
