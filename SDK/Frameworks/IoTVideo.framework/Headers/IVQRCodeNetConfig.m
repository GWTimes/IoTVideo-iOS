//
//  IVQRCodeNetConfig.m
//  IoTVideo
//
//  Created by ZhaoYong on 2019/12/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import "IVQRCodeNetConfig.h"
#import "IVQRCodeHelper.h"
#import "IVCommUtils.h"
#import "iot_video_link_def.h"
#import "IVNetConfig_internal.h"


@implementation IVQRCodeNetConfig


- (UIImage *)createQRCodeWithWifiName:(NSString *)name wifiPassword:(NSString *)pwd token:(NSString *)token {
    return [self createQRCodeWithWifiName:name wifiPassword:pwd language:IVNetConfigLanguageCN token:token extraInfo:nil QRSize:CGSizeMake(1024, 1024)];
}

- (UIImage *)createQRCodeWithWifiName:(NSString *)name wifiPassword:(NSString *)pwd language:(IVNetConfigLanguage)language token:(NSString *)token extraInfo:(NSDictionary<NSString *,NSString *> *)extraInfo QRSize:(CGSize)size {
    return [self createQRCodeWithWifiName:name wifiPassword:pwd reserve:nil language:language token:token extraInfo:extraInfo QRSize:size];
}


- (UIImage *)createQRCodeWithWifiName:(NSString *)name
                         wifiPassword:(NSString *)pwd
                              reserve:(NSString *)reserve
                             language:(IVNetConfigLanguage)language
                                token:(NSString *)token
                            extraInfo:(NSDictionary<NSString *,NSString *> *)extraInfo
                               QRSize:(CGSize)size {
   
    NSData *netData = [IVNetConfig _getDataFromWifiName:name wifiPassword:pwd userId:reserve language:language token:token extraInfo:extraInfo];
    UIImage *QRImage = [IVQRCodeHelper createQRCodeWithData:netData QRSize:size];
    return QRImage;
}


/**
 以内置协议 生成设备配网二维码
 
 @param wifiName  wifi name
 @param wifiPwd   wifi 密码
 @param size      二维码尺寸
 @param completionHandler 完成回调
 */
//- (void)createQRCodeWithWifiName:(NSString *)wifiName wifiPwd:(NSString  * _Nullable)wifiPwd QRSize:(CGSize)size completionHandler:(nullable IVQRCodeCreateCallback)completionHandler {
//    [self createQRCodeWithWifiName:wifiName wifiPwd:wifiPwd language:IV_QR_CODE_LANGUAGE_EN timeZone:[NSTimeZone.systemTimeZone secondsFromGMT]/60 QRSize:size completionHandler:completionHandler];
//}

/**
 以内置协议 生成设备配网二维码
 
 @param wifiName wifi name
 @param wifiPwd  wifi 密码
 @param language 需要配置的语言
 @param timeZone timeZone 分钟
 @param size     二维码尺寸
 @param completionHandler 完成回调
 */
//- (void)createQRCodeWithWifiName:(NSString *)wifiName wifiPwd:(NSString * _Nullable)wifiPwd  language:(IV_QR_CODE_LANGUAGE)language timeZone:(NSInteger)timeZone QRSize:(CGSize)size completionHandler:(nullable IVQRCodeCreateCallback)completionHandler {
//    NSString *inPath = [NSString stringWithFormat:@"%s/%s", URLCMD_HEAD_GET, URLCMD_DATA_NETCFG_TOKEN];
//    [IVMessageMgr.sharedInstance sendDataToServer:inPath
//                                             data:nil
//                                completionHandler:^(NSData * _Nullable data, NSError * _Nullable error) {
//        if (!completionHandler) { return;}
//
//        if (data == nil) {
//            completionHandler(nil, error);
//            return;
//        }
//
//        NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
//        if (error) {
//            completionHandler(nil, error);
//            return;
//        }
//
//        NSString *token = jsonDic[@"token"];
//        UIImage *image = [self createQRCodeWithWifiName:wifiName
//                                                wifiPwd:wifiPwd
//                                            netConfigId:token
//                                               language:language
//                                               timeZone:timeZone
//                                                 QRSize:size];
//        completionHandler(image, nil);
//
//    }];
//}


#pragma mark - private function

/**
 以内置协议 生成设备配网二维码
 
 @param wifiName wifi name
 @param wifiPwd  wifi 密码
 @param language 需要配置的语言
 @param timeZone timeZone 分钟
 @param size     二维码尺寸
 @param netConfigId 配网ID
 @return 二维码图片
 */
- (nullable UIImage *)createQRCodeWithWifiName:(NSString *)wifiName
                                       wifiPwd:(NSString *)wifiPwd
                                   netConfigId:(NSString *)netConfigId
                                      language:(IVNetConfigLanguage)language
                                      timeZone:(NSInteger)timeZone
                                        QRSize:(CGSize)size {
    
    NSMutableData *dataBuff = [[NSMutableData alloc] initWithLength:1024];
    uint8_t *buffer = (uint8_t *)(dataBuff.mutableBytes);
    __block NSInteger pOffset = 0;//初始化起始指针偏移量
    
    /***********************************
     类型       数据长度   数据
     uint8_t   uint8_t       ****
     type      len              data
     ************************************/
    //写入数据
    /*
     void(^writeData)(IV_QR_CODE_FUNCTION, NSString *) = ^(IV_QR_CODE_FUNCTION type, NSString *string) {
     if (!string || string.length == 0) { return;} //string为空则不写入
     logDebug("qr enter string : %@", string);
     *((uint8_t *)(buffer + pOffset)) = (uint8_t)(type); //写入type
     pOffset += sizeof(uint8_t);
     NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
     uint8_t dataLength = (uint8_t)(data.length);
     *((uint8_t *)(buffer + pOffset)) = dataLength; //写入数据长度
     pOffset += sizeof(uint8_t);
     [data getBytes:buffer + pOffset length:dataLength]; //写入传输的数据
     pOffset += dataLength;
     };
     
     //写入协议头"IVQR"
     for (; pOffset < strlen((char *)IV_QR_HEADER); pOffset++) {
     *((uint8_t *)(buffer + pOffset)) = IV_QR_HEADER[pOffset];
     }
     
     //写入二维码类型
     *((uint8_t *)(buffer + pOffset)) = (uint8_t)(IV_QR_CODE_TYPE_NET_CONFIG);
     pOffset += sizeof(uint8_t);
     
     NSString *timeZoneStr = [NSString stringWithFormat:@"%ld", (long)timeZone]; //时区
     NSString *userId = IoTVideo.sharedInstance.accessId; //用户id
     NSString *languageStr = [NSString stringWithFormat:@"%u", (unsigned int)language]; //语言
     
     
     writeData(IV_QR_CODE_FUNCTION_WIFI_SSID,     wifiName);    //写入Wifi name
     writeData(IV_QR_CODE_FUNCTION_WIFI_PASSWORD, wifiPwd);     //写入Wifi password
     writeData(IV_QR_CODE_FUNCTION_APP_USER_ID,   userId);      //写入UserId
     writeData(IV_QR_CODE_FUNCTION_NETSET_ID,     netConfigId); //写入配网id
     writeData(IV_QR_CODE_FUNCTION_TIMEZONE,      timeZoneStr); //写入时区
     writeData(IV_QR_CODE_FUNCTION_LANGUAGE,      languageStr);    //写入语言
     //    writeData(IV_NET_CONFIG_QR_CODE_SESSION_ID, @"");      //写入session
     //    writeData(IV_NET_CONFIG_QR_CODE_ASSIGN, @"");          //写入assign
     
     */
    NSData *QRCodeData = [NSData dataWithBytes:buffer length:pOffset];
    
    logDebug("qrCode Length %ld %ld", pOffset, QRCodeData.length);
    UIImage *QRImage = [IVQRCodeHelper createQRCodeWithData:QRCodeData QRSize:size];
    return QRImage;
}


@end
