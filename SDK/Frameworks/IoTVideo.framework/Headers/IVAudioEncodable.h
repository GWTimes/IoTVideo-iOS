//
//  IVAudioEncodable.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/12/17.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVAVDefine.h"

/// 音频编码器协议
@protocol IVAudioEncodable <NSObject>

/// 音频编码格式
@property (nonatomic, assign, readwrite) IVAudioCodecType audioType;

/// 音频编码格式的细分类型
@property (nonatomic, assign, readonly) uint8_t audioCodecOption;

/// 每帧数据里的采样数
@property (nonatomic, assign, readonly) uint32_t sampleNumPerFrame;

/// 注册
/// @note 建立连接成功时调用
/// @param channel 通道ID
- (BOOL)registerForChannel:(uint32_t)channel;

/// 注销
- (void)unregister;

/// 编码
- (BOOL)encodeAudioFrame:(IVAudioFrame *)inFrame outPacket:(IVAudioPacket *)outPacket;


@optional
/// 设置相关参数
- (void)setupWithAudioType:(IVAudioCodecType)audioType sampleRate:(uint32_t)sampleRate audioMode:(IVAudioSoundMode)audioMode bitWidth:(uint8_t)bitWidth;

@end
