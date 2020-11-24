//
//  IVConstant.h
//  IoTVideo
//
//  Created by JonorZhang on 2020/8/19.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * IVOptionKey NS_STRING_ENUM;

/**
Web服务器域名配置：
    @li 不指定时默认为内置正式服
    @li "TEST": 内置测试服
    @li "xxxx": 自定义web服务器域名
 */
FOUNDATION_EXPORT IVOptionKey const IVOptionKeyHostWeb;

/**
 P2P服务器域名:
    @li 不指定时默认为内置正式服
    @li "TEST": 内置测试服
    @li "xxxx": 自定义P2P服务器域名
 */
FOUNDATION_EXPORT IVOptionKey const IVOptionKeyHostP2P;

/**
 使用SDK的APP的版本号
 */
FOUNDATION_EXPORT IVOptionKey const IVOptionKeyAppVersion;

/**
 使用SDK的APP的包名
 */
FOUNDATION_EXPORT IVOptionKey const IVOptionKeyAppPkgName;

/**
 使用SDK的APP的语言
 */
FOUNDATION_EXPORT IVOptionKey const IVOptionKeyAppLanguage;

/**
 使用SDK的APP_ID
 */
FOUNDATION_EXPORT IVOptionKey const IVOptionKeyAppID;

/**
 使用SDK的APP_Token
 */
FOUNDATION_EXPORT IVOptionKey const IVOptionKeyAppToken;

/**
 使用SDK的设备类型 保留
 */
FOUNDATION_EXPORT IVOptionKey const IVOptionKeyAppDevType;

/**
 APP PushID
 */
FOUNDATION_EXPORT IVOptionKey const IVOptionKeyPushID;

/**
 第三方ID前缀 保留
 */
FOUNDATION_EXPORT NSString *  const IVThirdIDPrefix;



/// SDK与服务器的连接状态
typedef NS_ENUM(NSUInteger, IVLinkStatus) {
    /// 在线
    IVLinkStatusOnline          = 1,
    /// 离线
    IVLinkStatusOffline         = 2,
    /// accessToken校验失败
    IVLinkStatusTokenFailed     = 3,
    /// 账号被踢飞/在别处登陆
    IVLinkStatusKickOff         = 6,
};

extern const NSString *linkStatusDesc(IVLinkStatus status);


/// 语言码
typedef NS_ENUM(NSUInteger, IVLanguageCode) {
    IVLanguageCodeEN = 1,  /**< 英文*/
    IVLanguageCodeCN = 2,  /**< 中文简体*/
    IVLanguageCodeTH = 3,  /**< 泰语*/
    IVLanguageCodeVI = 4,  /**< 越南语*/
    IVLanguageCodeDE = 5,  /**< 德语*/
    IVLanguageCodeKO = 6,  /**< 韩语*/
    IVLanguageCodeFR = 7,  /**< 法语*/
    IVLanguageCodePT = 8,  /**< 葡萄牙语*/
    IVLanguageCodeIT = 9,  /**< 意大利语*/
    IVLanguageCodeRU = 10, /**< 俄语*/
    IVLanguageCodeJA = 11, /**< 日语*/
    IVLanguageCodeES = 12, /**< 西班牙语*/
    IVLanguageCodePL = 13, /**< 波兰语*/
    IVLanguageCodeTR = 14, /**< 土耳其语*/
    IVLanguageCodeFA = 15, /**< 波斯语*/
    IVLanguageCodeID = 16, /**< 印尼语*/
    IVLanguageCodeMS = 17, /**< 马来语*/
    IVLanguageCodeCS = 18, /**< 捷克语*/
    IVLanguageCodeSK = 19, /**< 斯洛伐克语*/
    IVLanguageCodeNL = 20, /**< 荷兰语*/
    IVLanguageCodeTC = 21, /**< 中文繁体*/
};

/// 当前手机系统使用的语言码
extern IVLanguageCode getSystemLanguageCode(void);

NS_ASSUME_NONNULL_END
