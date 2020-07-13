//
//  IVQRCodeHelper.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/13.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 扫码结果回调
 @param scanResult 原始字符串
 */
typedef void(^IVQRCodeScanCallback)(NSString * _Nullable scanResult);

@interface IVQRCodeHelper : NSObject

/**
 初始化二维码扫码
 需要手动调用startScan开启扫码
 @param preView 视频显示区域
 @param cropRect 识别区域，值为CGRectZero时全屏识别
 @param callback 识别完成回调
 @return IVQRCodeHelper实例
 */
- (instancetype)initWithPreView:(UIView*)preView cropRect:(CGRect)cropRect callback:(IVQRCodeScanCallback)callback;

/**
 初始化并开启二维码扫码

 @param preView 视频显示区域
 @param cropRect 识别区域，值为CGRectZero时全屏识别
 @param callback 识别完成回调
 @return IVQRCodeHelper实例
 */
+ (instancetype)startScanWithPreView:(UIView*)preView cropRect:(CGRect)cropRect callback:(IVQRCodeScanCallback)callback;

/**
 闪光灯模式
 */
@property (nonatomic, assign) AVCaptureTorchMode torchMode;

/**
 开始扫码
 */
- (void)startScan;

/**
 停止扫码
 */
- (void)stopScan;

/// 解析图片二维码
/// @param image 包含二维码图片
/// @return 二维码信息
- (nullable NSString *)detectQRCodeWithImage:(UIImage *)image;

/**
 生成二维码

 @param QRString 要生成二维码的字符串
 @param size 二维码尺寸
 @return 二维码图片, 失败时为nil
 */
+ (nullable UIImage *)createQRCodeWithString:(NSString *)QRString QRSize:(CGSize)size;

/**
生成二维码

@param QRData 要生成二维码的data
@param size 二维码尺寸
@return 二维码图片, 失败时为nil
*/
+ (nullable UIImage *)createQRCodeWithData:(NSData *)QRData QRSize:(CGSize)size;

/// 以内置协议 生成分享设备二维码
///
/// 需要使用本类扫描解析本类生成的二维码
/// @param token 分享的token
/// @param size 二维码大小
//+ (UIImage *)createShareDeviceQRCodeWithToken:(NSString *)token QRSize:(CGSize)size;


@end

NS_ASSUME_NONNULL_END
