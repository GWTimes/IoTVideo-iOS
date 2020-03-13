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
@protocol IVAVCodecRegister <NSObject>
- (void)registerWithHeader:(IVAVHeader)header;
- (void)unregister;
@end

/// 视频解码器协议
@protocol IVVideoDecodable <IVAVCodecRegister>
- (int)decodeVideoPacket:(IVVideoPacket *)inPacket outFrame:(IVVideoFrame *)outFrame;
@end

/// 视频编码器协议
@protocol IVVideoEncodable <IVAVCodecRegister>
- (int)encodeVideoFrame:(IVVideoFrame *)inFrame outPacket:(IVVideoPacket *)outPacket;
@end

/// 音频解码器协议
@protocol IVAudioDecodable <IVAVCodecRegister>
- (int)decodeAudioPacket:(IVAudioPacket *)inPacket outFrame:(IVAudioFrame *)outFrame;
@end

/// 音频编码器协议
@protocol IVAudioEncodable <IVAVCodecRegister>
- (int)encodeAudioFrame:(IVAudioFrame *)inFrame outPacket:(IVAudioPacket *)outPacket;
@end

