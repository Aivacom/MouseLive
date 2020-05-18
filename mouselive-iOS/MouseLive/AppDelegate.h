//
//  AppDelegate.h
//  MouseLive
//
//  Created by 张建平 on 2020/2/26.
//  Copyright © 2020 sy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow * window;
@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

