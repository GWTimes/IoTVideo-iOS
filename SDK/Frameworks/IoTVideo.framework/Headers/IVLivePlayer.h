//
//  IVLivePlayer.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/20.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVPlayer.h"
#import <QuartzCore/CALayer.h>

NS_ASSUME_NONNULL_BEGIN

/// 音视频通话播放器
@interface IVLivePlayer : IVPlayer <IVPlayerTalkable, IVPlayerVideoable>

/// 创建播放器
/// @param deviceId 设备ID
- (instancetype)initWithDeviceId:(NSString *)deviceId;

@end

NS_ASSUME_NONNULL_END
