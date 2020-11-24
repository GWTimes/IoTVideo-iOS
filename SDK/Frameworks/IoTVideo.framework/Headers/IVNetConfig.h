//
//  IVNetConfig.h
//  IoTVideo
//
//  Created by ZhaoYong on 2020/1/8.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVConstant.h"

@class IVLanNetConfig, IVQRCodeNetConfig;

NS_ASSUME_NONNULL_BEGIN

typedef IVLanguageCode IVNetConfigLanguage;

/// 设备上线通知完整模型
@interface IVDeviceOnline : NSObject
/// device id
@property (nonatomic, copy) NSString *deviceID;
/// errorCode
/// @code
/// | errorCode | 解释
/// | --------- | -----------------------------------
/// | 0         | 成功
/// | 8022      | 设备和用户已经绑定
/// | 8023      | 设备已经绑定其他用户
/// | 8024      | 设备的客户ID与用户的客户ID不一致
/// | 8027      | 设备上传的token校验失败
/// | 8028      | 设备上传的json解析失败
@property (nonatomic, assign) NSInteger errorCode;
/// 时间戳
@property (nonatomic, assign) NSTimeInterval time;
/// 配网token
@property (nonatomic, copy) NSString *token;
/// 设备uuid
@property (nonatomic, copy) NSString *uuid;
/// 预留
@property (nonatomic, copy) NSString *reserve;
@end

typedef void(^IVDeviceOnlineCallback)(NSString * _Nullable deviceId, NSError *error);
typedef void(^IVDeviceOnlineFullCallback)(IVDeviceOnline *deviceOnline);
/// 配网管理
@interface IVNetConfig : NSObject

/// 局域网配网
@property(class, nonatomic, strong, readonly) IVLanNetConfig *lan;

/// 二维码配网
@property(class, nonatomic, strong, readonly) IVQRCodeNetConfig *QRCode;


///// 局域网配网
//+ (IVLanNetConfig *)lan;
//
///// 二维码配网
//+ (IVQRCodeNetConfig *)QRCode;

/// 配网结果回调  
///
/// deviceId: 设备id
///
/// errorCode: 错误码
/// @code
/// | errorCode | 解释
/// | --------- | -----------------------------------
/// | 0         | 成功
/// | 8022      | 设备和用户已经绑定
/// | 8023      | 设备已经绑定其他用户
/// | 8024      | 设备的客户ID与用户的客户ID不一致
/// | 8027      | 设备上传的token校验失败
/// | 8028      | 设备上传的json解析失败
/// @endcode
+ (void)registerDeviceOnlineCallback:(IVDeviceOnlineCallback)onlineCallback;

+ (void)registerDeviceOnlineFullCallback:(IVDeviceOnlineFullCallback)onlineCallback;

/// 销毁监听block
+ (void)unregisterDeviceOnline;

/// 获取二维码/AP 配网所需要的配网 Token
/// @param completionHandler 回调
+ (void)getToken:(void(^)(NSString * _Nullable token, NSError * _Nullable error))completionHandler;

                    
/**
 * 通过web绑定成功后，快速订阅设备
 *  @param token 订阅的设备访问token
 *  @param deviceId 设备ID
 *  @return 是否成功
 */
+ (BOOL)subscribeDeviceWithToken:(NSString *)token deviceId:(NSString *)deviceId;

@end

NS_ASSUME_NONNULL_END
