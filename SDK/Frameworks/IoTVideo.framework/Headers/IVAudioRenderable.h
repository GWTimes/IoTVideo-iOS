//
//  IVAudioUnit.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVAVDefine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IVAudioRenderDataSource <NSObject>

/// 获取PCM音频数据, 建议由音频播放单元驱动（例如在AURenderCallback中调用该方法）
/// @param[in,out] aframe  用于承载音频帧数据
/// @note aframe入参时 `aframe->data`不可为NULL（由开发者malloc和free），aframe->size`不可为0；
/// @return [YES]成功，[NO]失败
- (BOOL)getAudioFrame:(IVAudioFrame *)aframe;

@end

@protocol IVAudioRenderable <NSObject>

/// 免提
@property (nonatomic, assign, readwrite) BOOL handsFree;

/// 播放音量 （取值范围 0.0 ~ 1.0）
@property (nonatomic, assign, readwrite) float volume;

/// 静音 {get, set}
@property (nonatomic, assign, readwrite) BOOL mute;

/// 是否正在运行
@property (nonatomic, assign, readonly) BOOL isRendering;

/// 开始运行
/// @param avheader 流媒体信息头
/// @param channel 通道ID
/// @param dataSource 数据源
- (BOOL)startRenderingWithAVHeader:(IVAVHeader)avheader channel:(uint32_t)channel dataSource:(id<IVAudioRenderDataSource>)dataSource;

/// 停止运行
- (void)stopRendering;

@end

NS_ASSUME_NONNULL_END
