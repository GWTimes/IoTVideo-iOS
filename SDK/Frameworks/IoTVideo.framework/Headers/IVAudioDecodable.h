//
//  IVAudioDecodable.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/12/17.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVAVDefine.h"

/// 音频解码器协议
@protocol IVAudioDecodable <NSObject>

/// 注册
- (BOOL)registerWithHeader:(IVAVHeader)header channel:(uint32_t)channel;

/// 注销
- (void)unregister;

/// 解码
- (BOOL)decodeAudioPacket:(IVAudioPacket *)inPacket outFrame:(IVAudioFrame *)outFrame;

@end


