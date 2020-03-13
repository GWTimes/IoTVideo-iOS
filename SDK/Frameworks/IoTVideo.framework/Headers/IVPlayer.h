//
//  IVPlayer.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/13.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IVAVDefine.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "IVAVCodecable.h"
#import "IVMessageMgr.h"

NS_ASSUME_NONNULL_BEGIN

@class IVPlayer;

/// 视频渲染器协议
@protocol IVVideoRenderable <NSObject>
- (void)player:(IVPlayer *)player renderVideoFrame:(IVVideoFrame *)videoFrame;
@end

/// 音频渲染器协议
@protocol IVAudioRenderable <NSObject>
- (void)player:(IVPlayer *)player renderAudioFrame:(IVAudioFrame *)audioFrame;
@end


/// 播放器代理协议
@protocol IVPlayerDelegate <NSObject>
/// 播放器状态回调
/// @param player 播放器实例
/// @param status 状态值
- (void)player:(IVPlayer *)player didUpdateStatus:(IVPlayerStatus)status;
/// 播放时间回调
/// @param player 播放器实例
/// @param PTS 时间戳
- (void)player:(IVPlayer *)player didUpdatePTS:(NSTimeInterval)PTS;
/// 播放错误回调
/// @param player 播放器实例
/// @param error 错误实例
- (void)player:(IVPlayer *)player didReceiveError:(NSError *)error;

/// 音视频头信息回调
/// @param player  播放器实例
/// @param avHeader 音视频头信息
- (void)player:(IVPlayer *)player didReceiveAVHeader:(IVAVHeader)avHeader;
/// 用户数据回调
/// @param player 播放器实例
/// @param userData 用户数据
- (void)player:(IVPlayer *)player didReceiveUserData:(NSData *)userData;
@end


/// 播放器对讲协议
@protocol IVPlayerTalkable <NSObject>
/// 是否正在对讲
@property (nonatomic, assign, readonly) BOOL isTalking;
/// 开启对讲
- (void)startTalk;
/// 关闭对讲
- (void)stopTalk;
@end

/// 核心播放器
@interface IVPlayer : NSObject

/// 音视频编解码器，默认为内置编解码器。⚠️如无必要 请勿修改
@property (nonatomic, strong, nullable) id<IVVideoDecodable> videoDecoder;
@property (nonatomic, strong, nullable) id<IVVideoEncodable> videoEncoder;
@property (nonatomic, strong, nullable) id<IVAudioDecodable> audioDecoder;
@property (nonatomic, strong, nullable) id<IVAudioEncodable> audioEncoder;

/// 音视频渲染器，默认为内置渲染器。⚠️如无必要 请勿修改
@property (nonatomic, strong, nullable) id<IVAudioRenderable> audioRender;
@property (nonatomic, strong, nullable) UIView<IVVideoRenderable> *videoView;

/// 播放器代理
@property (nonatomic, weak, nullable) id<IVPlayerDelegate> delegate;

/// 连接设备
@property (nonatomic, strong, readonly) NSString *deviceId;

/// 视频连接类型
@property (nonatomic, assign, readonly) IVAVConnType connType;

/// 连接通道，`prepare/play`成功后该通道值才有效
@property (nonatomic, assign, readonly) uint32_t channel;

/// 播放器状态
@property (nonatomic, assign, readonly) IVPlayerStatus status;

/// 解码器信息头
@property (nonatomic, assign, readonly) IVAVHeader avheader;

/// 视频时间戳（秒）
@property (nonatomic, assign, readonly) NSTimeInterval pts;

/// 视频清晰度
@property (nonatomic, assign, readwrite) IVVideoDefinition definition;

/// 静音，  默认NO（即允许播放声音）
@property (nonatomic, assign, readwrite) BOOL mute;

#pragma mark - 播放控制

/// 预连接，获取流媒体头信息
- (void)prepare;

/// 开始播放
- (void)play;

/// 停止播放，断开连接
- (void)stop;


#pragma mark - 截图/录像

/// 视频画面截图
- (void)takeScreenshot:(void(^)(UIImage * _Nullable image))completionHandler;

/// 开始录像
- (void)startRecord:(NSString *)savePath completionHandler:(void(^)(NSString * _Nullable savePath, NSError * _Nullable error))completionHandler;

/// 停止录像
- (void)stopRecord;

/// 是否正在录像
@property (nonatomic, assign, readonly) BOOL isRecording;


#pragma mark - 发送数据

/// 数据发送接口
- (int)sendUserData:(NSData *)data responseHandler:(nullable IVMsgDataCallback)responseHandler;


@end

NS_ASSUME_NONNULL_END
