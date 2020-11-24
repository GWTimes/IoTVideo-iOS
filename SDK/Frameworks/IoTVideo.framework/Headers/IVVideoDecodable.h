//
//  IVVideoDecodable.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/12/17.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVAVDefine.h"

/// 视频解码器协议
@protocol IVVideoDecodable <NSObject>

/// 注册
- (BOOL)registerWithHeader:(IVAVHeader)header channel:(uint32_t)channel;

/// 注销
- (void)unregister;

/// 解码
- (BOOL)decodeVideoPacket:(IVVideoPacket *)inPacket outFrame:(IVVideoFrame *)outFrame;

@end


