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

@interface IVLivePlayer : IVPlayer <IVPlayerTalkable>

/// 创建播放器
/// @param deviceId 设备ID
- (instancetype)initWithDeviceId:(NSString *)deviceId;

/// 摄像头预览图层
@property (nonatomic, strong, readonly) CALayer *previewLayer;

/// 镜头位置，默认IVCameraPositionFront
@property (nonatomic, assign, readonly) IVCameraPosition cameraPosition;

/// 是否正在开启摄像头
@property (nonatomic, assign, readonly) BOOL isCameraOpening;

/// 视频帧率，默认16
@property (nonatomic, assign) int frameRate;

/// 启动摄像头
- (void)openCamera;

/// 关闭摄像头
- (void)closeCamera;

/// 切换摄像头
- (void)switchCamera;

@end

NS_ASSUME_NONNULL_END
