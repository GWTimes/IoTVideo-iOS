//
//  IoTVideo.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/13.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVLog.h"
#import "IVError.h"

#import "IVAVDefine.h"
#import "IVAVCodecable.h"
#import "IVPlayer.h"
#import "IVLivePlayer.h"
#import "IVMonitorPlayer.h"
#import "IVPlaybackPlayer.h"

#import "IVMessageMgr.h"

#import "IVQRCodeHelper.h"
#import "IVLanNetConfig.h"
#import "IVQRCodeNetConfig.h"
#import "IVQRCodeDef.h"
#import "IVNetConfig.h"
#import "IVNetworkSign.h"
#import "IVNetwork_p2p.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString * IVOptionKey NS_STRING_ENUM;

FOUNDATION_EXPORT IVOptionKey const IVOptionKeyHostWeb; //!< 自定义web服务器域名，⚠️自定义域名优先级高于内置域名
FOUNDATION_EXPORT IVOptionKey const IVOptionKeyHostP2P; //!< 自定义p2p服务器域名，⚠️自定义域名优先级高于内置域名
FOUNDATION_EXPORT IVOptionKey const IVOptionKeyHostType; //!< "0"： p2p、web 内置测试服务器；   "1"：p2p、web 内置正式服务器


@interface IoTVideo : NSObject

/// 单例
+ (instancetype)sharedInstance;
@property (class, nonatomic, strong, readonly) IoTVideo *sharedInstance;

/// 访问Token
@property (nonatomic, strong, nullable, readonly) NSString *accessToken;
/// 用户ID（外部访问IotVideo云平台的唯一性身份标识）
@property (nonatomic, strong, nullable, readonly) NSString *accessId;
/// 终端ID
@property (nonatomic, strong, nullable, readonly) NSString *terminalId;
/// SDK版本
@property (nonatomic, assign, readonly) NSInteger SDKVersion;
/// 日志级别
@property (nonatomic, assign) IVLogLevel logLevel;
/// 日志输出回调
@property (nonatomic, copy, nullable) IVLogCallback logCallback;
/**
可选配置选项
*/
@property (nonatomic, strong, nullable) NSDictionary<IVOptionKey, id> *options;

/// SDK初始化配置一些参数, 需要在`application:didFinishLaunchingWithOptions:`中调用
///
/// @param launchOptions 传入application:didFinishLaunchingWithOptions: 得到的launchOptions
- (void)setupWithLaunchOptions:(nullable NSDictionary *)launchOptions;


/// 注册登陆信息，建议在登录成功(获取到accessId、accessToken)后调用
/// @param accessId  是外部访问IotVideo云平台的唯一性身份标识，所有 OpenAPI 接口都需要传入这个头部参数。
/// @param accessToken   登录成功服务器返回的`accessToken`
- (void)registerWithAccessId:(NSString *)accessId accessToken:(NSString *)accessToken;

/// 刷新accessToken
/// @param accessToken 登录成功服务器返回的`accessToken`
- (void)updateToken:(NSString *)accessToken;

/// SDK反注册，退出登录时调用
- (void)unregister;

@end


@interface IoTVideo (Test)

/// 内部测试代码，开发者请勿调用
+ (void)test:(int)a b:(id)b c:(id)c d:(int)d e:(id)e f:(int)f;

@end

NS_ASSUME_NONNULL_END
