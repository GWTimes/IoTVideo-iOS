//
//  IVAVCodecable.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/12/17.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVAVDefine.h"

/// 编解码器注册协议
@protocol IVAVCodecable <NSObject>

@property (nonatomic, assign, readonly) uint32_t channel;

- (void)registerWithHeader:(IVAVHeader)header channel:(uint32_t)channel;
- (void)unregister;
@end

/// 视频解码器协议
@protocol IVVideoDecodable <IVAVCodecable>
- (int)decodeVideoPacket:(IVVideoPacket *)inPacket outFrame:(IVVideoFrame *)outFrame;
@end

/// 视频编码器协议
@protocol IVVideoEncodable <IVAVCodecable>
- (int)encodeVideoFrame:(IVVideoFrame *)inFrame outPacket:(IVVideoPacket *)outPacket;
@end

/// 音频解码器协议
@protocol IVAudioDecodable <IVAVCodecable>
- (int)decodeAudioPacket:(IVAudioPacket *)inPacket outFrame:(IVAudioFrame *)outFrame;
@end

/// 音频编码器协议
@protocol IVAudioEncodable <IVAVCodecable>
- (int)encodeAudioFrame:(IVAudioFrame *)inFrame outPacket:(IVAudioPacket *)outPacket;
@end

