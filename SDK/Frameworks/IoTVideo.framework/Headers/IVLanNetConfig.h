//
//  IVLanNetConfig.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/12/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 局域网设备模型
@interface IVLANDevice : NSObject
/// device id
@property (nonatomic, strong) NSString *deviceID;
/// 产品ID
@property (nonatomic, strong) NSString *productID;
/// 序列号
@property (nonatomic, strong) NSString *serialNumber;
/// 设备版本
@property (nonatomic, strong) NSString *version;
/// MAC地址
@property (nonatomic, strong) NSString *macAddr;

@end

/// 局域网配网类
@interface IVLanNetConfig : NSObject

/// 通过局域网发送配网信息
/// @param wifiName Wi-Fi名称
/// @param wifiPwd Wi-Fi密码
/// @param deviceId 设备ID
/// @param completionHandler 配网结果回调
- (void)sendWifiName:(NSString *)wifiName wifiPwd:(NSString *)wifiPwd toDevice:(NSString *)deviceId completion:(void(^)(BOOL success,  NSError * _Nullable error))completionHandler;

/// 获取局域网设备列表
- (NSArray<IVLANDevice *> *)getDeviceList;

@end

NS_ASSUME_NONNULL_END
