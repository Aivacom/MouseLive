//
//  VideoLiveCollectionViewCell.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/3.
//  Copyright © 2020 sy. All rights reserved.
//

#import "AudioLiveCollectionViewCell.h"

#import "AudioContentView.h"


@interface AudioLiveCollectionViewCell()


@end

@implementation AudioLiveCollectionViewCell


//-(void)setupLiveView{
//    
//    // gradient
//    CAGradientLayer *gl = [CAGradientLayer layer];
//    gl.frame = CGRectMake(0,0,self.contentView.width,self.contentView.height);
//    gl.startPoint = CGPointMake(0.5, 0);
//    gl.endPoint = CGPointMake(0.5, 1);
//    gl.colors = @[(__bridge id)[UIColor colorWithRed:0/255.0 green:187/255.0 blue:110/255.0 alpha:1.0].CGColor, (__bridge id)[UIColor colorWithRed:2/255.0 green:153/255.0 blue:210/255.0 alpha:1.0].CGColor];
//    gl.locations = @[@(0), @(1.0f)];
//    [self.contentView.layer addSublayer:gl];
//    //父类 布局
//    self.liveContentView = (UIView *)self.audioContentView;
//}
- (int)limit
{
    return 8;
}


- (BOOL)haveVideo
{
    return NO;
}
- (void)setupLiveView
{
    [super setupLiveView];
    [self.liveContentView insertSubview:self.audioContentView atIndex:0];

}

//-(void)linkMicr{
//    //主播pk 弹出主播列表
//    if (self.isAnchor) {
//        
//        <#statements#>
//    }
//}

@end
