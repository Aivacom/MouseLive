//
//  LiveCodeRateView.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/4.
//  Copyright © 2020 sy. All rights reserved.
//

#import "LiveCodeRateView.h"

@interface LiveCodeRateView()
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@end
/**
 @property (nonatomic) CGFloat audioUpload;  // A 音频上行
 @property (nonatomic) CGFloat audioDownload; // A 音频下行
 @property (nonatomic) CGFloat videoUpload; // V 视频上行
 @property (nonatomic) CGFloat videoDownload; // V 视频下行
 @property (nonatomic) CGFloat upload; // 上行
 @property (nonatomic) CGFloat download; // 下行
 */

@implementation LiveCodeRateView

+ (instancetype)liveCodeRateView
{
    
    return [[NSBundle mainBundle]loadNibNamed:NSStringFromClass(self) owner:nil options:nil].lastObject;
    
}
/**
 THUNDER_SDK_NETWORK_QUALITY_UNKNOWN = 0, // 质量未知
 THUNDER_SDK_NETWORK_QUALITY_EXCELLENT = 1, // 网络质量极好
 THUNDER_SDK_NETWORK_QUALITY_GOOD = 2, // 网络质量好
 THUNDER_SDK_NETWORK_QUALITY_POOR = 3, // 网络质量较好，用户感受有瑕疵但不影响沟通
 THUNDER_SDK_NETWORK_QUALITY_BAD = 4, // 网络质量一般，勉强能沟通但不顺畅
 THUNDER_SDK_NETWORK_QUALITY_VBAD = 5, // 网络质量非常差，基本不能沟通
 THUNDER_SDK_NETWORK_QUALITY_DOWN = 6, // 网络连接已断开，完全无法沟通
 */

- (void)setQualityModel:(NetworkQualityStauts *)qualityModel
{
    _qualityModel = qualityModel;
    NetWorkQuality *quality = [qualityModel.netWorkQualityDictionary objectForKey:@"0"];
    switch (quality.uploadNetQuality) {
        case THUNDER_SDK_NETWORK_QUALITY_UNKNOWN:
            self.upQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Unknown", nil)];
            break;
        case THUNDER_SDK_NETWORK_QUALITY_EXCELLENT://@"网络质量:极好";
            self.upQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Excellent", nil)];
            
            break;
        case THUNDER_SDK_NETWORK_QUALITY_GOOD://@"网络质量:良好";
            self.upQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Good", nil)];
            
            break;
        case THUNDER_SDK_NETWORK_QUALITY_POOR: //@"网络质量:较好";
            self.upQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Good", nil)];
            
            break;
        case THUNDER_SDK_NETWORK_QUALITY_BAD: //Poor @"网络质量:一般";
            self.upQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Poor", nil)];
            
            break;
        case THUNDER_SDK_NETWORK_QUALITY_VBAD://Bad @"网络质量:差";
            self.upQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Bad", nil)];
            break;
        case THUNDER_SDK_NETWORK_QUALITY_DOWN: //Very Bad @"网络质量:断开";
            self.upQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Very Bad", nil)];
            break;
        default:
            self.upQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Unknown", nil)];
            break;
    }
    switch (quality.downloadNetQuality) {
        case THUNDER_SDK_NETWORK_QUALITY_UNKNOWN:
            self.downQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Unknown", nil)];
            break;
        case THUNDER_SDK_NETWORK_QUALITY_EXCELLENT:
            self.downQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Excellent", nil)];
            break;
        case THUNDER_SDK_NETWORK_QUALITY_GOOD:
            self.downQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Good", nil)];
            break;
        case THUNDER_SDK_NETWORK_QUALITY_POOR:
            self.downQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Good", nil)];
            break;
        case THUNDER_SDK_NETWORK_QUALITY_BAD:
            self.downQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Poor", nil)];
            break;
        case THUNDER_SDK_NETWORK_QUALITY_VBAD:
            self.downQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Bad", nil)];
            break;
        case THUNDER_SDK_NETWORK_QUALITY_DOWN:
            self.downQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Very Bad", nil)];
            break;
        default:
            self.downQualityLabel.text = [[NSLocalizedString(@"Network", nil)stringByAppendingString:@":"] stringByAppendingString:NSLocalizedString(@"Unknown", nil)];
            break;
    }
    
    self.upLabel.text = [NSString stringWithFormat:@"%@:%.0fkb",NSLocalizedString(@"Upload", nil),_qualityModel.upload];
    self.upDetailLabel.text = [NSString stringWithFormat:@"(A:%.0fkb/ V:%.0fkb)",_qualityModel.audioUpload,_qualityModel.videoUpload];
    
    self.downLabel.text = [NSString stringWithFormat:@"%@:%.0fkb",NSLocalizedString(@"Download", nil),_qualityModel.download];
    self.downDetailLabel.text = [NSString stringWithFormat:@"(A:%.0fkb/ V:%.0fkb)",_qualityModel.audioDownload,_qualityModel.videoDownload];
}

- (void)setUserDetailString:(NSString *)userDetailString
{
    _userDetailString = userDetailString;
    self.nameLabel.text = userDetailString;
}
@end
