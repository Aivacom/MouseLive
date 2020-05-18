//
//  GearPickView.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/9.
//  Copyright © 2020 sy. All rights reserved.
//

#import "GearPickView.h"

@interface GearPickView()<UIPickerViewDelegate,UIPickerViewDataSource>

@property (nonatomic, weak) IBOutlet UIPickerView *pickView;
/** pickView 数据源*/
@property (nonatomic, strong) NSArray *dataArray;
/**选择的档位*/
@property (nonatomic,  assign)NSInteger selectGear;
@property (weak, nonatomic) IBOutlet UILabel *qualityBtn;

@end

@implementation GearPickView

+ (instancetype)gearPickView
{
    
    return [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil].lastObject;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.layer.cornerRadius = 16.0f;
    self.layer.masksToBounds = YES;
    self.pickView.dataSource = self;
    self.pickView.delegate = self;
    self.pickView.showsSelectionIndicator = YES;
    [self.pickView selectRow:2 inComponent: 0 animated:YES];
    self.selectGear = 2;
    
    [self.qualityBtn setText:NSLocalizedString(@"Quality", nil)];
}

- (NSArray *)dataArray
{
    if (!_dataArray) {
//        _dataArray = @[@"流畅 540x960 15FPS",@"标清  540X960 15FPS",@"高清 540X960 24FPS",@"超清 540X960 24FPS",@"蓝光 540X960 24FPS"];  // 保留下

        _dataArray = @[NSLocalizedString(@"LD     320*240 15fps 300k", nil),
                       NSLocalizedString(@"SD     640*368 24fps 550k", nil),
                       NSLocalizedString(@"HD     960*540 24fps 1000k", nil)];
    }
    return _dataArray;
}
#pragma mark - Picker Delegate
//行
- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView
{
    return 1;
}
// 每行有3列
- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.dataArray.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.dataArray[row];
}
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 44;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.selectGear = row;
}

#pragma mark- Button Action

- (IBAction)cancelAction:(UIButton *)sender
{
    [self hidenGearView];
}

- (IBAction)okAction:(UIButton *)sender
{
    [[NSNotificationCenter defaultCenter]postNotificationName:kNotifySettingGear object:@(self.selectGear)];
}

- (void)hidenGearView
{
    self.hidden = YES;
    [UIView animateWithDuration:0.3 animations:^{
          self.transform = CGAffineTransformIdentity;
      }];
}
@end
