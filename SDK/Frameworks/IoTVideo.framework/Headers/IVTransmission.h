//
//  IVTransmission.h
//  IoTVideo
//
//  Created by JonorZhang on 2020/5/25.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVConnection.h"

NS_ASSUME_NONNULL_BEGIN

@interface IVTransmission : IVConnection

/// 初始化连接
/// @param deviceId 设备ID
- (nullable instancetype)initWithDeviceId:(NSString *)deviceId;

@end

NS_ASSUME_NONNULL_END
