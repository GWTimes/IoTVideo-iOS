//
//  IVVideoCapturable.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/CALayer.h>
#import "IVAVDefine.h"
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IVVideoCaptureDelegate <NSObject>

/// 填充RGBA视频数据, 建议在摄像采集回调函数里调用（例如在captureOutput:didOutputSampleBuffer:fromConnection:中调用该方法）
/// @param[in] vframe  用于承载视频帧数据
/// @note vframe入参时 `vframe->data[i]`不可为NULL（由开发者malloc和free），vframe->linesize[i]`不可为0；
/// @return [YES]成功，[NO]失败
- (BOOL)fillVideoFrame:(IVVideoFrame *)vframe;

@end

@protocol IVVideoCapturable <NSObject>

/// 清晰度
@property (nonatomic, assign, readwrite) IVVideoDefinition definition;

/// 像素格式
@property (nonatomic, assign, readwrite) IVPixelFormatType pixFmt;

/// 帧率
@property (nonatomic, assign, readwrite) int frameRate;

/// 镜头位置
@property (nonatomic, assign, readwrite) IVCameraPosition cameraPosition;

/// 分辨率
@property (nonatomic, assign, readonly) CGSize videoSize;

/// 预览图层
@property (nonatomic, strong, readonly) CALayer *previewLayer;

/// 是否正在运行
@property (nonatomic, assign, readonly) BOOL isCapturing;

/// 切换摄像头
- (void)switchCamera;

/// 开始运行
/// @param channel 通道ID
/// @param delegate 代理
- (BOOL)startCapturingWithChannel:(uint32_t)channel delegate:(id<IVVideoCaptureDelegate>)delegate;

/// 停止运行
- (void)stopCapturing;

@end

NS_ASSUME_NONNULL_END
