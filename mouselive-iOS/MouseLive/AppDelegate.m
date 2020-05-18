//
//  AppDelegate.m
//  MouseLive
//
//  Created by 张建平 on 2020/2/26.
//  Copyright © 2020 sy. All rights reserved.
//

#import "AppDelegate.h"
#import "IQKeyboardManager.h"
#import "MainViewController.h"
#import "SYHummerManager.h"
#import "AFNetworking.h"
#import "LiveUserModel.h"
//#import "PLeakSniffer.h"
#import "SYAppInfo.h"
#import "SYToken.h"
#import "SYEffectsDataManager.h"
#import "SYEffectRender.h"


@interface AppDelegate ()
@property (nonatomic, strong) UIAlertController *alertVC;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //第三方库初始化
    [self initValueThirdParty:application didFinishLaunchingWithOptions:launchOptions];
    [self loginIn];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    MainViewController *mainViewController = [MainViewController instance];
    self.window.rootViewController = mainViewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)initValueThirdParty:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    [[PLeakSniffer sharedInstance] installLeakSniffer];
    
    // 添加DDASLLogger，你的日志语句将被发送到Xcode控制台
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *logPath = [paths.firstObject stringByAppendingPathComponent:@"SCLogs/MouseLive"]; // 输出到一个指定的文件夹
    
    // 添加DDFileLogger，你的日志语句将写入到一个文件中，默认路径在沙盒的Library/Caches/Logs/目录下，文件名为bundleid+空格+日期.log。
    // 现在设置到 kLogFilePath 目录下
    DDLogFileManagerDefault *documentsFileManager = [[DDLogFileManagerDefault alloc]
                                                     initWithLogsDirectory:logPath];
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc]
                                initWithLogFileManager:documentsFileManager];
    // Configure File Logger
    [fileLogger setMaximumFileSize:(1024 * 1024)];
    [fileLogger setRollingFrequency:(3600.0 * 24.0)];
    [[fileLogger logFileManager] setMaximumNumberOfLogFiles:5];
    [DDLog addLogger:fileLogger];
    
    [BaseConfigManager sy_sharedInstance].bgLogEnable = NO;
    [self configKeyboardManager];
    
#if USE_BEATIFY
    // 校验美颜 SDK 序列号
    [[SYEffectRender sharedRenderer] checkSDKSerailNumber:[SYAppInfo sharedInstance].ofSerialNumber];
#endif
}
#pragma mark - UISceneSession lifecycle

#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer  API_AVAILABLE(ios(10.0))
{
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"MouseLive"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    YYLogError(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
                
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext
{
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        YYLogError(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

//登录接口
- (void)loginIn
{
    YYLogDebug(@"[MouseLive-APPDelegate] App build:%@, version:%@", [SYAppInfo sharedInstance].appBuild, [SYAppInfo sharedInstance].appVersion);
    
    // 第一次登陆 uid = 0
    long long uid = 0;
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kUserInfo];
    if (userInfo) {
        uid = [[userInfo objectForKey:kUid] longLongValue];
    }
    
    NSDictionary *params = @{
        kUid:@(uid),
        kDevName:[UIDevice currentDevice].name,
        kDevUUID:[UIDevice currentDevice].identifierForVendor.UUIDString,
        kValidTime:@([SYToken sharedInstance].validTime),
    };
    
    [HttpService sy_httpRequestWithType:SYHttpRequestKeyType_Login params:params success:^(int taskId, id  _Nullable respObjc) {
        NSNumber *code = [respObjc objectForKey:kCode];
        if (![code isEqualToNumber:[NSNumber numberWithInt:[ksuccessCode intValue]]]) {
            [self showAlert];
        } else {
            // 在登陆成功后，发送获取美颜效果
            [self getEffects];
            
            NSDictionary *UserInfo = [respObjc objectForKey:kData];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kloginSucess];
            [[NSUserDefaults standardUserDefaults] setObject:UserInfo forKey:kUserInfo];
            //保存uid
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            //初始化 Hummer
            NSString *uid = [NSString stringWithFormat:@"%@",[[[NSUserDefaults standardUserDefaults]dictionaryForKey:kUserInfo] objectForKey:kUid]];
            
            // 获取 token
            [SYToken sharedInstance].thToken = [NSString stringWithFormat:@"%@",[[[NSUserDefaults standardUserDefaults]dictionaryForKey:kUserInfo] objectForKey:kToken]];
            [SYToken sharedInstance].localUid = uid;
            
            [[SYHummerManager sharedManager] loginWithUid:uid completionHandler:^(NSError * _Nullable error) {
                YYLogError(@"Hummer failure%@",error);
            }];
            
            [self.alertVC dismissViewControllerAnimated:YES completion:nil];
            // 刷新主界面数据, video
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyRefreshNew object:@"1"];
           
        }
    } failure:^(int taskId, id  _Nullable respObjc, NSString * _Nullable errorCode, NSString * _Nullable errorMsg) {
        YYLogDebug(@"[MouseLive-AppDelegate] 登录失败%@",respObjc);
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kloginSucess];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self showAlert];
    }];
}
//登陆失败弹框提示
- (void)showAlert
{
    self.alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"登陆失败，请重新登录！" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self loginIn];
    }];
    [self.alertVC addAction:ok];
    [self.window.rootViewController presentViewController:self.alertVC animated:YES completion:nil];
}

- (void)getEffects
{
    [[SYEffectsDataManager sharedManager] downloadEffectsData];
}

- (void)configKeyboardManager
{
    // 设置全局可点击空白处收回键盘
    [IQKeyboardManager sharedManager].shouldResignOnTouchOutside = YES;
    [IQKeyboardManager sharedManager].shouldShowToolbarPlaceholder = NO;
    [IQKeyboardManager sharedManager].toolbarDoneBarButtonItemText = @"完成";
    if (@available(iOS 13.0, *)) {
        [IQKeyboardManager sharedManager].toolbarTintColor = [UIColor whiteColor];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"进入后台");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"杀死进程");
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kloginSucess];

}

@end
