//
//  LiveUserView.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/5.
//  Copyright © 2020 sy. All rights reserved.
//

#import "LiveUserView.h"

@interface LiveUserView()
/** 头像*/
@property (nonatomic, weak) IBOutlet UIImageView *coverView;
/** 昵称*/
@property (nonatomic, weak) IBOutlet UILabel *nickNameLabel;
/** 关闭*/
@property (nonatomic, weak) IBOutlet UIButton *closeBtn;
/** 升管*/
@property (nonatomic, weak) IBOutlet UIButton *riserBtn;
/** 禁言*/
@property (nonatomic, weak) IBOutlet UIButton *shutupBtn;
/** 剔出*/
@property (nonatomic, weak) IBOutlet UIButton *outBtn;
@property (nonatomic, weak) IBOutlet UIView *bottomBgView;
@property (nonatomic, weak) IBOutlet UIView *leftLine;
@property (nonatomic, weak) IBOutlet UIView *rightLine;

/**语音房上麦 下麦分割线*/

@property (nonatomic, weak) IBOutlet UIView *centerLine;
/**闭麦*/
@property (nonatomic, weak) IBOutlet UIButton *closeMircBtn;
/**下麦*/
@property (nonatomic, weak) IBOutlet UIButton *downMircBtn;

@end

@implementation LiveUserView

+ (instancetype)userView
{
    return [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil].lastObject;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [UIView yy_maskViewToBounds:self radius:12.0];
    self.bottomBgView.layer.borderWidth = 1.0f;
    self.bottomBgView.layer.borderColor= [UIColor sl_colorWithHexString:@"#F3F3F3"].CGColor;
    //@"升管"
    [self.riserBtn setTitle:NSLocalizedString(@"Apply_Admin",nil) forState:UIControlStateNormal];
    //"降管"
    [self.riserBtn setTitle:NSLocalizedString(@"Viewer",nil) forState:UIControlStateSelected];
    //@"禁言"
    [self.shutupBtn setTitle:NSLocalizedString(@"Ban",nil) forState:UIControlStateNormal];
    //@"解言"
    [self.shutupBtn setTitle:NSLocalizedString(@"Unban","解禁") forState:UIControlStateSelected];
    self.riserBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.shutupBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.outBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.closeMircBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.downMircBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    
}

- (IBAction)closeBtnClicked:(UIButton *)sender
{
    if (self.closeBlock) {
        self.closeBlock();
    }
}

- (IBAction)managerBtnAction:(UIButton *)sender
{
    if (self.managementBlock) {
        if (self.model.isAdmin) {
            self.managementBlock(self.model, ManagementUserTypeRemoveAdmin,sender);
        }
        else {
            self.managementBlock(self.model, ManagementUserTypeAddAdmin,sender);
        }
    }
}
//禁言
- (IBAction)shutupBtnClicked:(id)sender
{
    if (self.managementBlock) {
        if (self.model.isMuted) {
            self.managementBlock(self.model, ManagementUserTypeUnmute,sender);
        }
        else {
            self.managementBlock(self.model, ManagementUserTypeMute,sender);
        }
    }
}

- (IBAction)kickBtnClicked:(id)sender
{
    if (self.managementBlock) {
        self.managementBlock(self.model, ManagementUserTypeKick,sender);
    }
}

- (void)setModel:(LiveUserModel *)model
{
    _model = model;
    [self.coverView yy_setImageWithURL:[NSURL URLWithString:model.Cover] placeholder:PLACEHOLDER_IMAGE];
    self.nickNameLabel.text = model.NickName;
    //视频聊天房
    if (self.type != LiveTypeAudio) {
        
        // 如果全体禁言，以哪个优先级高？？？？
        //主播 升管 禁言 踢出
        if (self.isAnchor) {
            if (self.model.isMuted) {
                //解禁
                self.shutupBtn.selected = YES;
                
            }
            else {
                //禁言
                self.shutupBtn.selected = NO;
            }
            
            if (self.model.isAdmin) {
                //降管
                self.riserBtn.selected = YES;
                
            }
            else {
                //升管
                self.riserBtn.selected = NO;
            }
        }
        //管理员
        if (self.isAdmin) {
            //改变左右按钮文字
            //左按钮
            //@"禁言"
            [self.closeMircBtn setTitle:NSLocalizedString(@"Ban",nil)  forState:UIControlStateNormal];
            //@"解言"
            [self.closeMircBtn setTitle:NSLocalizedString(@"Unban",nil) forState:UIControlStateSelected];
            //右按钮 "踢出"
            [self.downMircBtn setTitle:NSLocalizedString(@"Kick",nil) forState:UIControlStateNormal];
            if (self.model.isMuted) {
                //解禁
                self.closeMircBtn.selected = YES;
                
            }
            else {
                //禁言
                self.closeMircBtn.selected = NO;
            }
        }
    } else {
         [self.closeMircBtn setTitle:NSLocalizedString(@"Mic On",nil)  forState:UIControlStateNormal];
         [self.closeMircBtn setTitle:NSLocalizedString(@"Mic Off",nil)  forState:UIControlStateSelected];
         [self.downMircBtn setTitle:NSLocalizedString(@"Off Seat",nil)  forState:UIControlStateNormal];
        if (model.MicEnable) {
            self.closeMircBtn.selected = YES;  // 闭麦
        } else {
            self.closeMircBtn.selected = NO; // 开麦
        }
    }
}


- (void)setType:(LiveType)type
{
    _type = type;
    if (type == LiveTypeAudio) {
        self.centerLine.hidden = NO;
        self.closeMircBtn.hidden = NO;
        self.downMircBtn.hidden = NO;
        
        self.leftLine.hidden  = YES;
        self.rightLine.hidden = YES;
        self.outBtn.hidden = YES;
        self.riserBtn.hidden = YES;
        self.shutupBtn.hidden = YES;
    } else if (type == LiveTypeVideo) {

        if (self.isAnchor) {
            self.centerLine.hidden = YES;
            self.closeMircBtn.hidden = YES;
            self.downMircBtn.hidden = YES;

            self.leftLine.hidden  = NO;
            self.rightLine.hidden = NO;
            self.outBtn.hidden = NO;
            self.riserBtn.hidden = NO;
            self.shutupBtn.hidden = NO;
        }

        if (self.isAdmin) {
            self.centerLine.hidden = NO;
            self.closeMircBtn.hidden = NO;
            self.downMircBtn.hidden = NO;

            self.leftLine.hidden  = YES;
            self.rightLine.hidden = YES;
            self.outBtn.hidden = YES;
            self.riserBtn.hidden = YES;
            self.shutupBtn.hidden = YES;
        }
        
    }
}
- (IBAction)closeMirClicked:(UIButton *)sender
{
    if (_type == LiveTypeAudio) {
        if (self.managementBlock) {
            int micType = ManagementUserTypeCloseMirc;
            if (!self.closeMircBtn.selected) {
                // 开麦
                micType = ManagementUserTypeOpenMirc;
            }
            self.closeMircBtn.selected = !self.closeMircBtn.selected;
            self.managementBlock(self.model, micType,sender);
        }
    } else {
        //管理员禁言 解禁
        if (self.managementBlock) {
            if (self.model.isMuted) {
                self.managementBlock(self.model, ManagementUserTypeUnmute,sender);
            }
            else {
                self.managementBlock(self.model, ManagementUserTypeMute,sender);
            }
        }
    }
}

- (IBAction)downMircClicked:(UIButton *)sender
{
    if (_type == LiveTypeAudio) {
        if (self.managementBlock) {
            self.managementBlock(self.model, ManagementUserTypeDownMirc,sender);
        }
    } else {
        //踢出
        if (self.managementBlock) {
            self.managementBlock(self.model, ManagementUserTypeKick,sender);
        }
    }
}

@end
