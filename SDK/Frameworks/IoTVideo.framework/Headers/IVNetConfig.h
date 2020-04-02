//
//  IVNetConfig.h
//  IoTVideo
//
//  Created by ZhaoYong on 2020/1/8.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class IVLanNetConfig,IVQRCodeNetConfig;
NS_ASSUME_NONNULL_BEGIN


/// 配网管理
@interface IVNetConfig : NSObject
/// 局域网配网
@property(class, nonatomic, strong, readonly) IVLanNetConfig *lan;
/// 二维码配网
@property(class, nonatomic, strong, readonly) IVQRCodeNetConfig *QRCode;

/// 局域网配网
+ (IVLanNetConfig *)lan;
/// 二维码配网
+ (IVQRCodeNetConfig *)QRCode;

/**
 * 通过web绑定成功后，快速订阅设备
 *  @param token 订阅的设备访问token
 *  @param deviceId 设备ID
 *  @return 是否成功
 */
+ (BOOL)subscribeDeviceWithToken:(NSString *)token deviceId:(NSString *)deviceId;

@end

NS_ASSUME_NONNULL_END
