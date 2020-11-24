//
//  IVDeviceMgr.h
//  IoTVideo
//
//  Created by zhaoyong on 2020/10/27.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVNetwork_p2p.h"

NS_ASSUME_NONNULL_BEGIN

@interface IVDeviceMgr : NSObject

/// 查询设备新固件版本信息
/// @param deviceId 设备id
/// @param responseHandler 回调
+ (void)queryDeviceNewVersionWidthDevieId:(NSString *)deviceId responseHandler:(IVNetworkResponseHandler)responseHandler;


/// 查询设备新固件版本信息
/// @param deviceId 设备id
/// @param currentVersion 当前版本号 nil: 默认为当前版本号 当针对特定版本的升级时为必填
/// @param language 语言 nil：默认系统语言
/// @param responseHandler 回调
+ (void)queryDeviceNewVersionWidthDevieId:(NSString *)deviceId currentVersion:(NSString * _Nullable)currentVersion language:(NSString * _Nullable)language responseHandler:(IVNetworkResponseHandler)responseHandler;


@end

NS_ASSUME_NONNULL_END
