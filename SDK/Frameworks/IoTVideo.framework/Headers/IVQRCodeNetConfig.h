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
 2. 使用本类中的创建配网二维码方法直接获取二维码
 3. 用户使用设备扫描二维码
 4. 设备获取配网信息并连接指定网络
 5. 设备上线并向服务器注册
 6. APP收到设备已上线通知
 7. APP向服务器发起绑定目标设备的请求
 8. 账户绑定设备成功
 9. 订阅该设备
 10. 配网结束
 */

/**
 * ***************************************************************************************************
 *      内置二维码协议
 *
 *   数据类型 +  数据长度 + 数据 + 数据类型 + 数据长度  + ......
 *
 *   数据类型        数据长度        数据
 *   string         string        string
 *   type           len           data
 *
 * *****************************************************************************************************
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "IVNetConfig.h"

NS_ASSUME_NONNULL_BEGIN


@interface IVQRCodeNetConfig : NSObject
/// 生成配网二维码
///
/// 语言默认 CN, 生成的二维码大小 1024 * 1024
///
/// @param name wifi名称
/// @param pwd wifi密码
/// @param token 配网token
- (nullable UIImage *)createQRCodeWithWifiName:(NSString *)name
                                  wifiPassword:(NSString *)pwd
                                         token:(NSString *)token;



/// 生成配网二维码
///
/// 类型   必选    说明
/// 0      是    wifi-ssid
/// 1      是    wifi密码
/// 2      是    wifi安全/加密选项  无密码:0  WPA:2 SDK内部判断实现
/// 3      否    平台保留
/// 4      否    配网提示音语言类型
/// 5      是    配网token,从IoT Video平台获取
/// 6-9    否    平台扩展保留
/// A-Z    否    厂商自定义扩展 放入 extraInfo 中
/// @param name wifi SSID
/// @param pwd wifi密码
/// @param language 设备语言
/// @param token 配网Token
/// @param extraInfo 额外自定义扩展信息
/// @param size 二维码大小
/// @return 二维码图片
- (nullable UIImage *)createQRCodeWithWifiName:(NSString *)name
                                  wifiPassword:(NSString *)pwd
                                      language:(IVNetConfigLanguage)language
                                         token:(NSString *)token
                                     extraInfo:(nullable NSDictionary<NSString *, NSString *> *)extraInfo
                                        QRSize:(CGSize)size;


/// 生成配网二维码
///
/// 类型   必选    说明
/// 0      是    wifi-ssid
/// 1      是    wifi密码
/// 2      是    wifi安全/加密选项  无密码:0  WPA:2 SDK内部判断实现
/// 3      否    平台保留
/// 4      否    配网提示音语言类型
/// 5      是    配网token,从IoT Video平台获取
/// 6-9    否    平台扩展保留
/// A-Z    否    厂商自定义扩展 放入 extraInfo 中
/// @param name wifi SSID
/// @param pwd wifi密码
/// @param reserve 平台保留 厂商请使用上面的接口，或传nil
/// @param language 设备语言
/// @param token 配网Token
/// @param extraInfo 额外自定义扩展信息
/// @param size 二维码大小
/// @return 二维码图片
- (nullable UIImage *)createQRCodeWithWifiName:(NSString *)name
                                  wifiPassword:(NSString *)pwd
                                       reserve:(nullable NSString *)reserve
                                      language:(IVNetConfigLanguage)language
                                         token:(NSString *)token
                                     extraInfo:(nullable NSDictionary<NSString *, NSString *> *)extraInfo
                                        QRSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
