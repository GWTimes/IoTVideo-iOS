//
//  IVAVRecordable.h
//  IoTVideo
//
//  Created by JonorZhang on 2020/7/30.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVAVDefine.h"

NS_ASSUME_NONNULL_BEGIN

/// 写入音视频原始数据帧
@protocol IVAVFrameWritable <NSObject>
@optional
- (void)writeVideoFrame:(IVVideoFrame *)vframe;
- (void)writeAudioFrame:(IVAudioFrame *)aframe;
@end

/// 写入音视频编码数据包
@protocol IVAVPacketWritable <NSObject>
@optional
- (void)writeVideoPacket:(IVVideoPacket *)packet;
- (void)writeAudioPacket:(IVAudioPacket *)packet;
@end


@protocol IVAVRecordable <IVAVFrameWritable, IVAVPacketWritable>

/// 录制的音视频信息头
@property (nonatomic, assign, readonly) IVAVHeader recordHeader;

/// 输入的音视频源信息头
@property (nonatomic, assign, readonly) IVAVHeader avheader;

/// 视频保存路径
@property (nonatomic, strong, nullable, readonly) NSString *savePath;

/// 是否正在录像
@property (nonatomic, assign, readonly) BOOL isRecording;

/// 开始录像
- (void)startRecordingWithHeader:(IVAVHeader)avheader channel:(uint32_t)channel savePath:(NSString *)savePath completionHandler:(void(^)(NSString * _Nullable savePath, NSError * _Nullable error))completionHandler;

/// 停止录像
- (void)stopRecording;

@end


NS_ASSUME_NONNULL_END
