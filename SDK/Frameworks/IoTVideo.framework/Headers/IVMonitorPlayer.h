//
//  IVMonitorPlayer.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/20.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IVPlayer.h"

NS_ASSUME_NONNULL_BEGIN

/// 监控播放器
@interface IVMonitorPlayer : IVPlayer <IVPlayerTalkable>

/// 创建播放器
/// @param deviceId 设备ID
- (nullable instancetype)initWithDeviceId:(NSString *)deviceId;

/// 创建播放器
/// @param deviceId 设备ID
/// @param sourceId 源ID
- (nullable instancetype)initWithDeviceId:(NSString *)deviceId sourceId:(uint16_t)sourceId;

@end

NS_ASSUME_NONNULL_END
