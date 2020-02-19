//
//  IVApiFormatTest.m
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/4.
//  Copyright © 2019 gwell. All rights reserved.
//

#import "IVApiFormatTest.h"
#import <IVAccountMgr/IVAccountMgr.h>
//#import "IotVideoDemo-Swift.h"
//#import <IoTVideo/IVMessageMgr.h>
#import <IoTVideo/IoTVideo.h>

@interface IVApiFormatTest ()

@end

@implementation IVApiFormatTest

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
//
    //    [IVAccountMgr.shareInstance registerWithEmail:"" password:"" verificationCode:"" ivCid:"" responseHandler:nil];
    [IVAccountMgr.shareInstance getVerificationCodeForMobile:@"123546664"
                                                  mobileArea:@"86"
                                                   checkType:IVAccountCheckCodeTypeRegister
                                             responseHandler:^(NSString * _Nullable json, NSError * _Nullable error) {
        if (error) {
            return;
        }
        NSLog(@"%@",json);
    }];
//    NSData *deviceToken = [NSData new];
//    [IVMessageMgr.sharedInstance registerForRemoteNotificationsWithDeviceToken:deviceToken completionHandler:^(NSString * _Nullable json, NSError * _Nullable error) {
//        if (error != nil) {
//            NSLog(@"注册失败 Error: %@", error);
//        }
//        NSLog(@"注册成功");
//    }];
    
//    [IoTVideo.sharedInstance setupIvCid:@"xxx" productId:@"xxxxxxxxxxxx" userInfo:nil];
//    [IoTVideo.sharedInstance registerWithAccessId:@"xxxxxxxx" accessToken:@"xxxxxx"];
    
//    [IVAccountMgr.shareInstance addDeviceWithDeviceId:@"12345678" responseHandler:^(NSString * _Nullable json, NSError * _Nullable error) {
//
//    }];

    [IVAccountMgr.shareInstance addDeviceWithDeviceId:@"0000" deviceName:nil forceBind:true responseHandler:nil];
//    IVMessageMgr.sharedInstance.delegate = self;
    
//    // deviceId 是设备ID的字符串
//    // controlPath 是模型路径的字符串，如 "SP.presetPosSetting.setVal"
//    // controlData 是模型参数的字符串，如 "{\"pos1\":{\"x\":10,\"y\":10},\"pos2\":{\"x\":100,\"y\":200}}"
//    [IVMessageMgr.sharedInstance controlDevice:deviceId
//                                          path:controlPath
//                                          data:controlData
//                             completionHandler:^(IVMessage * _Nullable message, NSError * _Nullable error) {
//        // do something here
//    }];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

#import <IoTVideo/IoTVideo.h>


