//
//  IVQRCodeNetConfig.h
//  IoTVideo
//
//  Created by ZhaoYong on 2019/12/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 生成二维码回调
 @param QRImage 二维码
 @param error 错误信息
 */
typedef void(^IVQRCodeCreateCallback)(UIImage * _Nullable QRImage, NSError * _Nullable error);

@interface IVQRCodeNetConfig : NSObject

/**
 生成设备配网二维码
 
 @param wifiName  wifi name
 @param wifiPwd   wifi 密码
 @param size      二维码尺寸
 @param completionHandler 完成回调
*/
+ (void)createQRCodeWithWifiName:(NSString *)wifiName wifiPwd:(NSString  * _Nullable)wifiPwd QRSize:(CGSize)size completionHandler:(nullable IVQRCodeCreateCallback)completionHandler;

/**
 生成设备配网二维码
 
 @param wifiName wifi name
 @param wifiPwd  wifi 密码
 @param language 需要配置的语言
 @param timeZone timeZone 分钟
 @param size     二维码尺寸
 @param completionHandler 完成回调
*/
+ (void)createQRCodeWithWifiName:(NSString *)wifiName wifiPwd:(NSString * _Nullable)wifiPwd  language:(NSString *)language timeZone:(NSInteger)timeZone QRSize:(CGSize)size completionHandler:(nullable IVQRCodeCreateCallback)completionHandler;

/**
 生成设备配网二维码
 
 @param wifiName  wifi name
 @param wifiPwd   wifi 密码
 @param size      二维码尺寸
 @param completionHandler 完成回调
*/
- (void)createQRCodeWithWifiName:(NSString *)wifiName wifiPwd:(NSString  * _Nullable)wifiPwd QRSize:(CGSize)size completionHandler:(nullable IVQRCodeCreateCallback)completionHandler;

/**
 生成设备配网二维码
 
 @param wifiName wifi name
 @param wifiPwd  wifi 密码
 @param language 需要配置的语言
 @param timeZone timeZone 分钟
 @param size     二维码尺寸
 @param completionHandler 完成回调
*/
- (void)createQRCodeWithWifiName:(NSString *)wifiName wifiPwd:(NSString * _Nullable)wifiPwd  language:(NSString *)language timeZone:(NSInteger)timeZone QRSize:(CGSize)size completionHandler:(nullable IVQRCodeCreateCallback)completionHandler;


@end

NS_ASSUME_NONNULL_END
