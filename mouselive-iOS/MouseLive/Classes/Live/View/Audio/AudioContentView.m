//
//  AudioContentView.m
//  MouseLive
//
//  Created by 宁丽环 on 2020/3/6.
//  Copyright © 2020 sy. All rights reserved.
//

#import "AudioContentView.h"
#import "AudioCollectionViewCell.h"
#import "AudioFlowLayout.h"
#import "LivePresenter.h"
#import "SYHummerManager.h"
#import "SYThunderManagerNew.h"


@interface AudioContentView()<UICollectionViewDataSource,UICollectionViewDelegate,LiveProtocol,UIGestureRecognizerDelegate,UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet UIImageView *headerImageview;
@property (nonatomic, weak) IBOutlet UIImageView *microImageView;
@property (nonatomic, weak) IBOutlet UILabel *nickNameLB;
@property (nonatomic, weak) IBOutlet UIButton *musicButton;
/**全员闭麦*/
@property (nonatomic, weak) IBOutlet UIButton *closeMircButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mircButtonBottomConstraint;
@property (nonatomic, weak) IBOutlet UIButton *linkMricButton;
//@property (nonatomic, strong) LivePresenter *presenter;
@property (nonatomic, weak) IBOutlet UIView *volumeBgView;
@property (nonatomic, weak) IBOutlet UISlider *volumeSlider;
/**主播房间名*/
@property (nonatomic, weak) IBOutlet UILabel *anchorRoomName;
/**在线人数*/
@property (nonatomic, weak) IBOutlet UILabel *onlinePeopleCount;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topLayouConstraint;
@property (nonatomic, strong)NSTimer *timer;
@property (nonatomic, strong)CAShapeLayer *shapeLayer;


@end

static NSString *reuseIdentifier = @"AudioCollectionViewCell";
@implementation AudioContentView
#pragma mark 抖动

- (NSTimer *)timer
{
    if (!_timer) {
        _timer = [NSTimer timerWithTimeInterval:5.0
                                         target:self
                                       selector:@selector(timerAction)
                                       userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    }
    return _timer;
}

- (NSMutableArray *)dataArray
{
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc]init];
    }
    return _dataArray;
}

+ (AudioContentView *)audioContentView
{
    return [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil].lastObject;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
    self.mircButtonBottomConstraint.constant = TabbarSafeBottomMargin + Live_Tool_H + 10;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshUserMicEnable:) name:kNotifyisMicEnable object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAllUserMicEnable:) name:kNotifyAllMicEnable object:nil];
    [self.volumeSlider setThumbImage:[UIImage imageNamed:@"slider_thurk"] forState:UIControlStateNormal];
    [self.volumeSlider setThumbImage:[UIImage imageNamed:@"slider_thurk"] forState:UIControlStateSelected];
    [self.volumeSlider setThumbImage:[UIImage imageNamed:@"slider_thurk"] forState:UIControlStateHighlighted];
    self.topLayouConstraint.constant = StatusBarHeight + 4.0f;
    self.isRunningMusic = NO;
    
}



- (void)refreshAllUserMicEnable:(NSNotification *)notification
{
    // TODO: 其他用户自己进来，就让他自己刷上来好了 走流程 handleDidMicOnWithUid 和 handleDidMicOffWithUid 刷新 refreshUserMicEnable
    
    NSString *state = notification.object;
    BOOL enable = [state isEqualToString:@"YES"] ? YES : NO;
    
    // 把所有的黄色 禁麦图片全部刷下去/刷上去
    // yes -- 刷下黄色图片； no -- 刷上黄色图片
    for (LiveUserModel *userModel in self.dataArray) {
        userModel.MicEnable = enable;
        userModel.AnchorLocalLock = NO;
    }
    
    [self.contentView reloadData];
}

- (void)refreshUserMicEnable:(NSNotification *)notification
{
    NSString *uid = [notification.object objectForKey:@"uid"];
    BOOL ignoreSelfMicEnable = [[notification.object objectForKey:@"SelfMicEnable"] isEqualToString:@"2"] ? YES : NO;  // 是否忽略设置 SelfMicEnable
    BOOL selfMicEnable = [[notification.object objectForKey:@"SelfMicEnable"] isEqualToString:@"1"] ? YES : NO;
    BOOL micEnableByAnchor = [[notification.object objectForKey:@"MicEnableByAnchor"] isEqualToString:@"1"] ? YES : NO;
    
    BOOL found = NO;
    BOOL anchorLocalLock = NO;
    NSString *strAnchorLocalLock = [notification.object objectForKey:@"AnchorLocalLock"];
    if (strAnchorLocalLock) {
        found = YES;
        anchorLocalLock = [[notification.object objectForKey:@"AnchorLocalLock"] isEqualToString:@"1"] ? YES : NO;
    }
    
    // 这里需要修改
    LiveUserModel *userModel = [self searchLiveUserWithUid:uid];
    if (userModel != nil) {
        if (found) {
            userModel.MicEnable = micEnableByAnchor;
            userModel.AnchorLocalLock = anchorLocalLock;
            if (!ignoreSelfMicEnable) {
                // 主播设置的
                userModel.SelfMicEnable = selfMicEnable;
            }
        }
        else {
            if (!userModel.AnchorLocalLock) {
                // 没有锁住，才可修改
                userModel.MicEnable = micEnableByAnchor;
                if (!ignoreSelfMicEnable) {
                    // 主播设置的
                    userModel.SelfMicEnable = selfMicEnable;
                }
            }
        }

        [self.contentView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.dataArray indexOfObject:userModel] inSection:0]]];
    }
    
    //刷新主播麦克风状态
    if ([self.roomInfoModel.ROwner.Uid isEqualToString:uid]) {
        self.roomInfoModel.ROwner.SelfMicEnable = selfMicEnable;
        if (self.roomInfoModel.ROwner.SelfMicEnable) {
            [self.microImageView setImage:[UIImage imageNamed:@"audio_micr_open"]];
        } else {
            [self.microImageView setImage:[UIImage imageNamed:@"audio_mirc_close_onme"]];
        }
    }
}

#pragma mark - 查询房间用户
- (LiveUserModel *)searchLiveUserWithUid:(NSString *)uid
{
    //刷新席位
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Uid == %@", uid];
    NSArray *filteredArray = [self.dataArray filteredArrayUsingPredicate:predicate];
    if (filteredArray.count > 0) {
        return filteredArray.lastObject;
    } else {
        return nil;
    }
}

- (void)setup
{
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.musicButton.bounds byRoundingCorners:UIRectCornerTopRight | UIRectCornerBottomRight cornerRadii:CGSizeMake(100,100)];
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.frame = self.musicButton.bounds;
    layer.path = path.CGPath;
    self.musicButton.layer.mask = layer;
    self.musicButton.backgroundColor = [UIColor sl_colorWithHexString:@"#33C397"];
    
    
    self.volumeBgView.layer.cornerRadius = 17.0f;
    self.volumeBgView.layer.masksToBounds = YES;
    self.volumeBgView.backgroundColor = [UIColor sl_colorWithHexString:@"#33C397"];
    self.volumeBgView.hidden = YES;
    self.volumShowState =  self.volumeBgView.hidden;
    
    self.closeMircButton.backgroundColor = [UIColor sl_colorWithHexString:@"#33C397"];
    self.closeMircButton.layer.cornerRadius = 15.0f;
    self.closeMircButton.layer.masksToBounds = YES;
    
    
    self.contentView.collectionViewLayout = [[AudioFlowLayout alloc]init];
    [self.contentView registerNib:[UINib nibWithNibName:NSStringFromClass([AudioCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    self.contentView.dataSource = self;
    self.contentView.delegate = self;
    [self.contentView reloadData];
    [UIView yy_maskViewToBounds:self.headerImageview];
    [UIView yy_maskViewToBounds:self.microImageView];
}

- (void)setIsAnchor:(BOOL)isAnchor
{
    _isAnchor = isAnchor;
    //全部闭麦
    [self.closeMircButton setTitle:NSLocalizedString(@"Mute All", nil) forState:UIControlStateNormal];
    //全部开麦"
    [self.closeMircButton setTitle:NSLocalizedString(@"Unmute All", nil) forState:UIControlStateSelected];
    if (!_isAnchor) {
        _closeMircButton.hidden = YES;
        _musicButton.hidden = YES;
        _volumeBgView.hidden = YES;
        self.volumShowState =  self.volumeBgView.hidden;
    }
}
#pragma mark - 刷新语音房
- (void)refreshView
{
    NSSortDescriptor *firstDescriptor = [[NSSortDescriptor alloc] initWithKey:@"Uid" ascending:YES];
    self.dataArray = [[self.dataArray sortedArrayUsingDescriptors:@[firstDescriptor]] mutableCopy];
    [self.contentView reloadData];
}

#pragma mark - CollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 8;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AudioCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.indexPath = indexPath;
    if (indexPath.row <= self.dataArray.count - 1 && self.dataArray.count > 0) {
        LiveUserModel *model = self.dataArray[indexPath.row];
        cell.userModel = model;
    } else {
        cell.userModel = nil;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AudioCollectionViewCell *cell = (AudioCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (self.isAnchor) {
        if (cell.userModel) {
            LiveUserModel *model = [self searchLiveUserWithUid:cell.userModel.Uid];
            // 主播请人下麦，发送关闭连麦的请求
            if (model && self.closeOtherMicBlock) {
                self.closeOtherMicBlock(model);
            }
        }
    }
}
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
//    return CGSizeMake(<#CGFloat width#>, <#CGFloat height#>)
//}
//刷新主播头像
- (void)setRoomInfoModel:(LiveRoomInfoModel *)roomInfoModel
{
    _roomInfoModel = roomInfoModel;
    [self.headerImageview yy_setImageWithURL:[NSURL URLWithString:_roomInfoModel.ROwner.Cover] placeholder:PLACEHOLDER_IMAGE];
    if (_roomInfoModel.ROwner.SelfMicEnable) {
        [self.microImageView setImage:[UIImage imageNamed:@"audio_micr_open"]];
    } else {
        [self.microImageView setImage:[UIImage imageNamed:@"audio_mirc_close_onme"]];
    }
    self.anchorRoomName.text = _roomInfoModel.RName;
    self.nickNameLB.text = _roomInfoModel.ROwner.NickName;
}
- (void)setAudioAnchorModel:(RoomOwnerModel *)audioAnchorModel
{
    
}

- (void)setPeopleCount:(NSInteger)peopleCount
{
    
    _peopleCount = peopleCount;
    self.onlinePeopleCount.text = [NSString stringWithFormat:@"%@：%ld",NSLocalizedString(@"Online", nil),(long)peopleCount];
}

#pragma mark -播放音乐 展开收起播放条
- (IBAction)musicClicked:(UIButton *)sender
{
    
    if (!self.isRunningMusic) {
        [[SYThunderManagerNew sharedManager] openAuidoFileWithPath:[[NSBundle mainBundle]pathForResource:@"music1931" ofType:@"mp3"]];
        [[SYThunderManagerNew sharedManager] setAudioFilePlayVolume:50];
        //第一次进来先不要播放
        [[SYThunderManagerNew sharedManager] pauseAudioFile];
    }
    
    if (!self.volumeBgView.hidden) {
        sender.selected = !sender.selected;
        //相应了block开始播放音乐了
        if (self.musicBlock) {
            self.isRunningMusic = YES;
            self.musicBlock(sender.selected);
        }
 
        
    }
    //首次点击展开音量条
    self.volumeBgView.hidden = NO;
    self.volumShowState =  self.volumeBgView.hidden;
    [sender setImage:[UIImage imageNamed:@"music_play"] forState:UIControlStateNormal];
    [sender setImage:[UIImage imageNamed:@"music_pause"] forState:UIControlStateSelected];
    [self.musicButton.imageView.layer addSublayer:self.shapeLayer];
 
    self.shapeLayer.strokeEnd = [SYThunderManagerNew sharedManager].currentPlayprogress;
    if (self.shapeLayer.strokeEnd == 1.0) {
        self.shapeLayer.strokeEnd = 0.1;
    }
    if (_timer.isValid) {
        [_timer invalidate];
    }
    _timer = nil;
    _timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(timerAction) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
}

- (void)timerAction
{
    [self.musicButton setImage:[UIImage imageNamed:@"audio_music"] forState:UIControlStateNormal];
    [self.musicButton setImage:[UIImage imageNamed:@"audio_music"] forState:UIControlStateSelected];
    [self.shapeLayer removeFromSuperlayer];
    self.volumeBgView.hidden = YES;
    self.volumShowState =  self.volumeBgView.hidden;
}

//绘制播放进度
- (CAShapeLayer *)shapeLayer
{
    if (!_shapeLayer) {
        _shapeLayer =[[CAShapeLayer alloc]init];
        
        _shapeLayer.frame = CGRectMake(0, 0, self.musicButton.imageView.bounds.size.width - 2, self.musicButton.imageView.bounds.size.width - 2);
        _shapeLayer.lineWidth = 1;
        
        _shapeLayer.fillColor =[UIColor clearColor].CGColor;
        _shapeLayer.strokeColor =[UIColor whiteColor].CGColor;
        _shapeLayer.strokeStart = 0;
        _shapeLayer.strokeEnd = 0.1;
        
        CGPoint center =  CGPointMake((self.musicButton.imageView.bounds.size.width)/2, (self.musicButton.imageView.bounds.size.width)/2);
        
        UIBezierPath *bezierPath =[UIBezierPath bezierPathWithArcCenter:center radius:(self.musicButton.imageView.bounds.size.width)/2 startAngle: -0.5 * M_PI endAngle: 1.5 * M_PI clockwise:YES];
        _shapeLayer.path = bezierPath.CGPath;
    }
    return _shapeLayer;
}


- (IBAction)volumeSliderAction:(UISlider *)sender
{
    [[SYThunderManagerNew sharedManager] setAudioFilePlayVolume:sender.value];
}



- (IBAction)closeBtnClicked:(UIButton *)sender
{
    if (self.allMicOffBlock) {
        // TODO: 全部闭麦/开麦 -- 按钮文案需要修改
        // 如果禁麦/开麦失败，就 GG
        self.closeMircButton.selected = !self.closeMircButton.selected;
        self.allMicOffBlock(![SYHummerManager sharedManager].isAllMicOff);
    }
}

- (IBAction)peopleListBtnAction:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (self.iconClickBlock) {
        self.iconClickBlock(sender.selected);
    }
}


- (IBAction)quitBtnAction:(UIButton *)sender
{
    if (self.quitBlock) {
        self.isRunningMusic = NO;
        self.quitBlock();
    }
}

@end
