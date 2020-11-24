//
//  IVVideoEncodable.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/12/17.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVAVDefine.h"

/// 视频编码器协议
@protocol IVVideoEncodable <NSObject>

/// 视频编码格式
@property (nonatomic, assign, readwrite) IVVideoCodecType videoType;

/// 注册
/// @note 建立连接成功时调用
/// @param channel 通道ID
- (BOOL)registerForChannel:(uint32_t)channel;

/// 注销
- (void)unregister;

/// 编码
- (BOOL)encodeVideoFrame:(IVVideoFrame *)inFrame outPacket:(IVVideoPacket *)outPacket;


@optional
/// 设置相关参数
- (void)setupWithVideoType:(IVVideoCodecType)videoType size:(CGSize)videoSize pixFmt:(IVPixelFormatType)pixFmt frameRate:(int)frameRate;

@end

