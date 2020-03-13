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

@interface IVMonitorPlayer : IVPlayer <IVPlayerTalkable>

/// 创建播放器
/// @param deviceId 设备ID
- (instancetype)initWithDeviceId:(NSString *)deviceId;

@end

NS_ASSUME_NONNULL_END
