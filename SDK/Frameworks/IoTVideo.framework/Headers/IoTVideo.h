//
//  IoTVideo.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/13.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVLog.h"

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
#import "IVNetConfig.h"
#import "IVNetworkSign.h"
#import "IVNetwork_p2p.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString * IVOptionKey NS_STRING_ENUM;

extern IVOptionKey const IVOptionKeyHostWeb; //!< 自定义web服务器域名，⚠️自定义域名优先级高于内置域名
extern IVOptionKey const IVOptionKeyHostP2P; //!< 自定义p2p服务器域名，⚠️自定义域名优先级高于内置域名
extern IVOptionKey const IVOptionKeyHostType; //!< "0"： p2p、web 内置测试服务器；   "1"：p2p、web 内置正式服务器
extern IVOptionKey const IVOptionKeyProductId; //!< app的产品id(从平台注册时获取)


@interface IoTVideo : NSObject

+ (instancetype)sharedInstance;
@property (class, nonatomic, strong, readonly) IoTVideo *sharedInstance;

@property (nonatomic, strong, nullable, readonly) NSString *accessToken;
@property (nonatomic, strong, nullable, readonly) NSString *accessId;
@property (nonatomic, strong, nullable, readonly) NSString *productId;
@property (nonatomic, strong, nullable, readonly) NSString *terminalId;
@property (nonatomic, strong, nullable, readonly) NSDictionary<IVOptionKey, id> *options;
@property (nonatomic, assign, readonly) NSInteger SDKVersion;

/// 调试模式
@property (nonatomic, assign) BOOL debugMode;

/// 日志输出回调
@property (nonatomic, copy, nullable) IVLogCallback logCallback;

/// SDK初始化
/// @param productId  app的产品id(从平台注册时获取)
/// @param options      参考`IVOptionKey`，默认传nil
/// @code
/// [self setupToken]
/// @endcode
/// @remark 录成功服务器
- (void)setupProductId:(NSString *)productId options:(nullable NSDictionary<IVOptionKey, id> *)options;

/// 设置当前用户信息，登录成功调用
/// @param accessId  是外部访问IotVideo云平台的唯一性身份标识，所有 OpenAPI 接口都需要传入这个头部参数。
/// @param accessToken   登录成功服务器返回的`accessToken`
- (void)registerWithAccessId:(NSString *)accessId accessToken:(NSString *)accessToken;

/// 刷新accessToken
/// @param accessToken 登录成功服务器返回的`accessToken`
- (void)updateToken:(NSString *)accessToken;

/// SDK反注册，退出登录时调用
- (void)unregister;


@end

NS_ASSUME_NONNULL_END
