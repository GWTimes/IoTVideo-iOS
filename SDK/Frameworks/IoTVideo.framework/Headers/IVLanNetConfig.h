//
//  IVLanNetConfig.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/12/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVNetConfig.h"

NS_ASSUME_NONNULL_BEGIN

/// 局域网设备模型
@interface IVLANDevice : NSObject
/// device id
@property (nonatomic, copy) NSString *deviceID;
/// 产品ID
@property (nonatomic, copy) NSString *productID;
/// 序列号
@property (nonatomic, copy) NSString *serialNumber;
/// 设备版本
@property (nonatomic, copy) NSString *version;
/// ip地址
@property (nonatomic, copy) NSString *ipAddr;
/// MAC地址
@property (nonatomic, copy) NSString *macAddr;
/// 预留
@property (nonatomic, copy) NSString *reserve;
@end

/// 局域网配网类
@interface IVLanNetConfig : NSObject

/// 通过局域网发送配网信息（AP）
///
/// 类型   必选    说明
/// 0      是    wifi-ssid
/// 1      是    wifi密码
/// 2      是    wifi安全/加密选项  无密码:0  WPA:2 SDK内部判断实现
/// 3      否    平台保留
/// 4      否    配网提示音语言类型
/// 5      是    配网token,从IoT Video平台获取
/// 6-9    否    平台扩展保留  0 - 9
/// A-Z    否    厂商自定义扩展 放入 extraInfo 中
///
/// @param name Wi-Fi名称
/// @param pwd Wi-Fi密码
/// @param token 配网token
/// @param deviceId 设备id
/// @param completionHandler 配网结果回调
- (void)sendWifiName:(NSString *)name
        wifiPassword:(NSString *)pwd
               token:(NSString *)token
            toDevice:(NSString *)deviceId
          completion:(void(^)(BOOL success,  NSError * _Nullable error))completionHandler;

/// 通过局域网发送配网信息（AP）
///
/// 类型   必选    说明
/// 0      是    wifi-ssid
/// 1      是    wifi密码
/// 2      是    wifi安全/加密选项  无密码:0  WPA:2 SDK内部判断实现
/// 3      否    平台保留
/// 4      否    配网提示音语言类型
/// 5      是    配网token,从IoT Video平台获取
/// 6-9    否    平台扩展保留  0 - 9
/// A-Z    否    厂商自定义扩展 放入 extraInfo 中
///
/// @param name Wi-Fi名称
/// @param pwd Wi-Fi密码
/// @param language 设备语言
/// @param token 配网token
/// @param extraInfo 额外信息
/// @param deviceId 设备id
/// @param completionHandler 配网结果回调
- (void)sendWifiName:(NSString *)name
        wifiPassword:(NSString *)pwd
            language:(IVNetConfigLanguage)language
               token:(NSString *)token
           extraInfo:(nullable NSDictionary<NSString *, NSString *> *)extraInfo
            toDevice:(NSString *)deviceId
          completion:(void(^)(BOOL success,  NSError * _Nullable error))completionHandler;

/// 获取局域网设备列表
- (NSArray<IVLANDevice *> *)getDeviceList;

@end

NS_ASSUME_NONNULL_END
