//
//  LiveBottomSettingView.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/9.
//  Copyright © 2020 sy. All rights reserved.
//

#import "LiveBottomSettingView.h"
@interface LiveBottomSettingView()
/** 档位*/
@property (nonatomic, weak) IBOutlet UIButton *gearBtn;
@property (nonatomic, weak) IBOutlet UIView *bgView;
@property (nonatomic, weak) IBOutlet UIButton *SwitchBtn;
@property (nonatomic, weak) IBOutlet UIButton *mirrorBtn;
@property (nonatomic, weak) IBOutlet UIButton *magicBtn;

@end
@implementation LiveBottomSettingView

+ (instancetype)bottomSettingView
{
    return [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil].lastObject;
}
- (IBAction)buttonAction:(UIButton *)sender
{
    if (self.settingBlock) {
        self.settingBlock((BottomSettingType)sender.tag);
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.gearBtn.tintColor = [UIColor whiteColor];
    [self.gearBtn setTitle:NSLocalizedString(@"Quality", nil) forState:UIControlStateNormal];
    [self.SwitchBtn setTitle:NSLocalizedString(@"Switch", nil) forState:UIControlStateNormal];
    [self.mirrorBtn setTitle:NSLocalizedString(@"Mirror", nil) forState:UIControlStateNormal];
    [self.magicBtn setTitle:NSLocalizedString(@"Magic", nil) forState:UIControlStateNormal];

//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingGear:) name:kNotifySettingGear object:nil];
    
    
}
//#pragma mark - 通知
//- (void)settingGear:(NSNotification *)note
//{
//    NSString *mode  = @"流畅";
//    NSNumber *gear = note.object;
//    switch (gear.intValue) {
//        case 0:  //流畅
//            mode = @"流畅";
//            break;
//        case 1://标清
//            mode = @"标清";
//
//            break;
//        case 2: //高清
//            mode = @"高清";
//            break;
//        case 3://超清
//            mode = @"超清";
//            break;
//        case 4://蓝光
//            mode = @"蓝光";
//            break;
//        default:
//            mode = @"流畅";
//            break;
//
//    }
// [self.gearBtn setTitle:[NSString stringWithFormat:@"档位 %@",mode] forState:UIControlStateNormal];
//}


- (void)setIsMircPeople:(BOOL)isMircPeople
{
    _isMircPeople = isMircPeople;
    self.gearBtn.userInteractionEnabled = isMircPeople;
    if (_isMircPeople) {
        [self.gearBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.gearBtn.tintColor = [UIColor whiteColor];
    } else {
        self.gearBtn.tintColor = [UIColor lightGrayColor];
        [self.gearBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
  

}
@end
