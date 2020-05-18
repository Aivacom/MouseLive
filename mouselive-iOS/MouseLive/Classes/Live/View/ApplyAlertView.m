//
//  LiveUserView.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/5.
//  Copyright © 2020 sy. All rights reserved.
//

#import "ApplyAlertView.h"
#import "LiveProtocol.h"
#import "LivePresenter.h"

@interface ApplyAlertView()<LiveProtocol>
/** 头像*/
@property (nonatomic, weak) IBOutlet UIImageView *coverView;
/** 昵称*/
@property (nonatomic, weak) IBOutlet UILabel *nickNameLabel;
/** 申请类型*/
@property (nonatomic, weak) IBOutlet UILabel *applyNameLabel;
/** 关闭*/
@property (nonatomic, weak) IBOutlet UIButton *closeBtn;
/** 同意*/
@property (nonatomic, weak) IBOutlet UIButton *agreeBtn;
/** 拒绝*/
@property (nonatomic, weak) IBOutlet UIButton *rejectBtn;

@property (nonatomic, weak) IBOutlet UIView *bottomBgView;

@property (weak, nonatomic) IBOutlet UIView *bgContentView;
@property (nonatomic, strong)LivePresenter *presenter;

@property (nonatomic,strong)LiveUserModel *liveUserModel;

@property (nonatomic,strong)LiveAnchorModel *liveAnchorModel;

@property (nonatomic, copy) NSString *uid;

@end

@implementation ApplyAlertView

+ (instancetype)applyAlertView
{
    return [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil].lastObject;
}

//- (LivePresenter *)presenter
//{
//    if (!_presenter) {
//        _presenter = [[LivePresenter alloc]init];
//        [_presenter attachView:self];
//    }
//    return _presenter;
//}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [UIView yy_maskViewToBounds:self.bgContentView radius:12.0];
    self.bottomBgView.layer.borderWidth = 1.0f;
    self.bottomBgView.layer.borderColor= [UIColor sl_colorWithHexString:@"#F3F3F3"].CGColor;
}

- (IBAction)closeBtnClicked:(UIButton *)sender
{
    if (self.applyBlock) {
        self.applyBlock(ApplyActionTypeReject,self.uid,sender);
    }
}

- (IBAction)applayAction:(UIButton *)sender
{
    if (self.applyBlock) {
        self.applyBlock(sender.tag,self.uid,sender);
    }
}

- (void)setModel:(id)model
{
    _model = model;
    NSString *cover = @"";
    NSString *NickName = @"";
    if ([model isKindOfClass:[LiveUserModel class]]) {
        self.liveUserModel = model;
        cover = self.liveUserModel.Cover;
        NickName = self.liveUserModel.NickName;
        self.uid = self.liveUserModel.Uid;
        // @"申请连麦"
        self.applyNameLabel.text = self.livetype == LiveTypeVideo ? NSLocalizedString(@"wants to interact with you.",nil):NSLocalizedString(@"wants to have a seat.",nil);
    }else{
        self.liveAnchorModel = model;
        cover = self.liveAnchorModel.ACover;
        NickName = self.liveAnchorModel.AName;
        self.uid = self.liveAnchorModel.AId;
        //@"想与您PK"
        self.applyNameLabel.text =NSLocalizedString(@"wants to battle with you.",nil);
    }
    [self.coverView yy_setImageWithURL:[NSURL URLWithString:cover] placeholder:PLACEHOLDER_IMAGE];
    self.nickNameLabel.text = NickName;
}

- (void)liveUserData:(LiveUserModel *)user
{

    
}

@end
