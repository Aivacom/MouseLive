//
//  LiveListResponse.m
//  MouseLive
//
//  Created by 张建平 on 2020/3/3.
//  Copyright © 2020 sy. All rights reserved.
//

#import "LiveListResponse.h"
#import <YYModel.h>

@interface LiveListResponse()

@property (nonatomic, readwrite) Error* error;
@property (nonatomic, readwrite) NSMutableArray<LiveListItem*>* Item;

@end

@implementation LiveListResponse

// TODO: for test
+ (LiveListResponse*)test
{
    LiveListResponse* resp = [[LiveListResponse alloc] init];
    resp.error = [[Error alloc] init];
    resp.error.code = 0;
    resp.error.msg = @"123";
    
    resp.Item = [[NSMutableArray alloc] init];
    for (int i = 0; i < 10; i++) {
        LiveListItem* item = [[LiveListItem alloc] init];
        item.imageUrl = [NSString stringWithFormat:@"imageUrl=%d", (i)];
        item.userName = [NSString stringWithFormat:@"userName=%d", (i)];
        item.roomName = [NSString stringWithFormat:@"roomName=%d", (i)];
        item.roomId = [NSString stringWithFormat:@"roomId=%d", (i)];
        item.pullUrl = [NSString stringWithFormat:@"pullUrl=%d", (i)];
        item.viewerCount = i;
        [resp.Item addObject:item];
    }

//    // Convert model to json:
//    NSDictionary *json = [resp yy_modelToJSONObject];
//
//    NSLog(@"json = %@", json);
//
//    NSError *error;
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
//
//    NSString* js = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//
//    // Convert json to model:
//    LiveListResponse *response = [LiveListResponse yy_modelWithJSON:js];
//    NSLog(@"response = %@", js);
    
    return resp;
}

+ (NSDictionary *)modelContainerPropertyGenericClass
{
    // value should be Class or Class name.
    //
    return @{@"roomName":@"roomName111"};
}

@end
