//
//  IVQRCodeNetConfig.h
//  IoTVideo
//
//  Created by ZhaoYong on 2019/12/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

/**
 二维码配网流程
 
 1. 设备复位进入配网模式，摄像头开始扫描二维码
 2. APP使用配网信息生成二维码
    - 自有配网协议（自定义wifi信息，配网token等的组合编码方式生成二维码）：
        1. 获取配网token： 使用 - (void)getToken:(void(^)(NSString * _Nullable token, NSError * _Nullable error))completionHandler;
        2. 生成配网二维码： 可使用 IVQRCodeHelper 中的 生成二维码方法生成二维码，也可以自己生成
    - 直接使用SDK内置协议（需要设备也同时使用内置协议）
        1. 使用本类中的获取配网二维码方法直接获取二维码
 3. 用户使用设备扫描二维码
 4. 设备获取配网信息并连接指定网络
 5. 设备上线并向服务器注册
 6. APP收到设备已上线通知
 7. APP向服务器发起绑定目标设备的请求
 8. 账户绑定设备成功
 9. 订阅该设备
10. 配网结束
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "IVQRCodeDef.h"

NS_ASSUME_NONNULL_BEGIN

/**
 生成二维码回调
 @param QRImage 二维码
 @param error 错误信息
 */
typedef void(^IVQRCodeCreateCallback)(UIImage * _Nullable QRImage, NSError * _Nullable error);

@interface IVQRCodeNetConfig : NSObject


/// 获取二维码配网所需要的配网 Token
/// @param completionHandler 回调
- (void)getToken:(void(^)(NSString * _Nullable token, NSError * _Nullable error))completionHandler;

/**
 以内置协议 生成设备配网二维码 简单信息
 
 @param wifiName  wifi name
 @param wifiPwd   wifi 密码
 @param size      二维码尺寸
 @param completionHandler 完成回调
*/
- (void)createQRCodeWithWifiName:(NSString *)wifiName wifiPwd:(NSString  * _Nullable)wifiPwd QRSize:(CGSize)size completionHandler:(nullable IVQRCodeCreateCallback)completionHandler;

/**
 以内置协议 生成设备配网二维码
 
 @param wifiName wifi name
 @param wifiPwd  wifi 密码
 @param language 需要配置的语言
 @param timeZone timeZone 分钟
 @param size     二维码尺寸
 @param completionHandler 完成回调
*/
- (void)createQRCodeWithWifiName:(NSString *)wifiName wifiPwd:(NSString * _Nullable)wifiPwd language:(IV_QR_CODE_LANGUAGE)language timeZone:(NSInteger)timeZone QRSize:(CGSize)size completionHandler:(nullable IVQRCodeCreateCallback)completionHandler;



@end

NS_ASSUME_NONNULL_END
