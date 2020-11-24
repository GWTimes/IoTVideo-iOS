//
//  IVAudioCapturable.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVAVDefine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IVAudioCaptureDelegate <NSObject>

/// 填充PCM音频数据, 建议在音频采集回调函数里调用（例如在AURenderCallback中调用该方法）
/// @param[in] aframe  用于承载音频帧数据
/// @note aframe入参时 `aframe->data`不可为NULL（由开发者malloc和free），aframe->size`不可为0；
/// @return [YES]成功，[NO]失败
- (BOOL)fillAudioFrame:(IVAudioFrame *)aframe;

@end


/// 音频采集器协议
@protocol IVAudioCapturable <NSObject>

/// 音频模式： 单声道/双声道
@property (nonatomic, assign, readwrite) IVAudioSoundMode audioMode;

/// 音频位宽
@property (nonatomic, assign, readwrite) uint8_t  bitWidth;

/// 音频采样率
@property (nonatomic, assign, readwrite) uint32_t sampleRate;

/// 无声
@property (nonatomic, assign, readwrite) BOOL silent;

/// 是否正在运行
@property (nonatomic, assign, readonly) BOOL isCapturing;

/// 开始运行
/// @param channel 通道ID
/// @param delegate 代理
- (BOOL)startCapturingWithChannel:(uint32_t)channel delegate:(id<IVAudioCaptureDelegate>)delegate;

/// 停止运行
- (void)stopCapturing;

@end

NS_ASSUME_NONNULL_END
