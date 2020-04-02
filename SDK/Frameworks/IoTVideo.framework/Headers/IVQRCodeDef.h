//
//  IVQRCodeDef.h
//  IoTVideo
//
//  Created by ZhaoYong on 2020/1/6.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#ifndef IVQRCodeDef_h
#define IVQRCodeDef_h

/// 二维码协议头
static uint8_t const IV_QR_HEADER[] = {'I','V','Q','R'};

/// 二维码类型
typedef NS_ENUM(NSUInteger, IV_QR_CODE_TYPE){
    IV_QR_CODE_TYPE_NET_CONFIG   = 1,  /**<  配网  */
    IV_QR_CODE_TYPE_SHARE_DEVICE = 2   /**<  分享  */
};

/// 二维码协议枚举
typedef NS_ENUM(NSUInteger, IV_QR_CODE_FUNCTION) {
    IV_QR_CODE_FUNCTION_RESERVE       = 0, /**<  保留  */
    IV_QR_CODE_FUNCTION_WIFI_ENC_TYPE = 1, /**<  WiFi加密类型,WPA加密类型=2 1个字节,默认为WPA加密类型  */
    IV_QR_CODE_FUNCTION_WIFI_SSID     = 2, /**<  WiFi名称 文本  */
    IV_QR_CODE_FUNCTION_WIFI_PASSWORD = 3, /**<  WiFi密码 文本 没有密码就不传  */
    IV_QR_CODE_FUNCTION_APP_USER_ID   = 4, /**<  用户id  */
    IV_QR_CODE_FUNCTION_NETSET_ID     = 5, /**<  配网id  */
    IV_QR_CODE_FUNCTION_TIMEZONE      = 6, /**<  时区  */
    IV_QR_CODE_FUNCTION_LANGUAGE      = 7, /**<  设置设备语言  */
    
    IV_QR_CODE_FUNCTION_SHARE_TOKEN   = 32 /**<  分享设备  */
};

/// 二维码可设置语言 
typedef NS_ENUM(NSUInteger, IV_QR_CODE_LANGUAGE)
{
    IV_QR_CODE_LANGUAGE_TYPE_CN = 0, /**< 中文*/
    IV_QR_CODE_LANGUAGE_TYPE_EN,     /**< 英文*/
    IV_QR_CODE_LANGUAGE_TYPE_KR,     /**< 韩语*/
    IV_QR_CODE_LANGUAGE_TYPE_GER,    /**< 德语*/
    IV_QR_CODE_LANGUAGE_TYPE_JAPAN,  /**< 日语*/
    IV_QR_CODE_LANGUAGE_TYPE_SPANISH = 5, /**< 西班牙语*/

    IV_QR_CODE_LANGUAGE_TYPE_END
};


#endif /* IVQRCodeDef_h */
