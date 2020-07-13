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
#import "IVConnection.h"

NS_ASSUME_NONNULL_BEGIN

@class IVPlayer;

/// 视频渲染器协议
@protocol IVVideoRenderable <NSObject>

/// 视频渲染代理
/// @param player 播放器实例
/// @param videoFrame 要渲染的视频帧
- (void)player:(IVPlayer *)player renderVideoFrame:(IVVideoFrame *)videoFrame;

@end


/// 播放器代理协议
@protocol IVPlayerDelegate <IVConnectionDelegate>

@optional

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


/// 播放器视频通话协议
@protocol IVPlayerVideoable <NSObject>
/// 摄像头预览图层
@property (nonatomic, strong, readonly) CALayer *previewLayer;

/// 镜头位置，默认IVCameraPositionFront
@property (nonatomic, assign, readonly) IVCameraPosition cameraPosition;

/// 是否正在开启摄像头
@property (nonatomic, assign, readonly) BOOL isCameraOpening;

/// 视频帧率，默认16
@property (nonatomic, assign) int frameRate;

/// 启动摄像头
- (void)openCamera;

/// 关闭摄像头
- (void)closeCamera;

/// 切换摄像头
- (void)switchCamera;

@end


/// 核心播放器（抽象类，不要直接实例化，请使用其派生类: IVLivePlayer / IVPlaybackPlayer / IVMonitorPlayer）
@interface IVPlayer : IVConnection

/// 播放器代理
@property (nonatomic, weak, nullable) id<IVPlayerDelegate> delegate;

/// 播放器状态
@property (nonatomic, assign, readonly) IVPlayerStatus status;

/// 流媒体信息头
@property (nonatomic, assign, readonly) IVAVHeader avheader;

/// 当前播放时间戳（秒）
@property (nonatomic, assign, readonly) NSTimeInterval pts;

/// 视频清晰度
@property (nonatomic, assign, readwrite) IVVideoDefinition definition;

/// 静音，  默认NO（即允许播放声音）
@property (nonatomic, assign, readwrite) BOOL mute;


#pragma mark - 播放控制

/// (可选) 预连接，获取流媒体信息头
- (void)prepare;

/// 开始播放
- (void)play;

/// 停止播放，断开连接
- (void)stop;

#pragma mark - 截图/录像

/// 视频画面截图
/// @param completionHandler 完成回调
- (void)takeScreenshot:(void(^)(UIImage * _Nullable image))completionHandler;

/// 开始录像
/// @param savePath 录像文件路径
/// @param completionHandler 完成回调
- (void)startRecord:(NSString *)savePath completionHandler:(void(^)(NSString * _Nullable savePath, NSError * _Nullable error))completionHandler;

/// 停止录像
- (void)stopRecord;

/// 是否正在录像
@property (nonatomic, assign, readonly) BOOL isRecording;


#pragma mark - 高级功能【可选】

/// 视频解码器。⚠️已内置，如无必要 请勿修改
@property (nonatomic, strong, nullable) id<IVVideoDecodable> videoDecoder;
/// 视频编码器。⚠️已内置，如无必要 请勿修改
@property (nonatomic, strong, nullable) id<IVVideoEncodable> videoEncoder;
/// 音频解码器。⚠️已内置，如无必要 请勿修改
@property (nonatomic, strong, nullable) id<IVAudioDecodable> audioDecoder;
/// 音频编码器。⚠️已内置，如无必要 请勿修改
@property (nonatomic, strong, nullable) id<IVAudioEncodable> audioEncoder;

/// 视频渲染器。⚠️已内置，如无必要 请勿修改
/// 仅当`syncAudio=YES`时有效。
@property (nonatomic, strong, nullable) UIView<IVVideoRenderable> *videoView;

/// 自定义音频渲染。⚠️已内置，如无必要 请勿修改
/// 通过`getAudioFrame:`获取并渲染，⚠️内置音频渲染器将失效。
@property (nonatomic, assign, readwrite) BOOL customAudioRender;

/// 视频向音频对齐(由音频播放单元驱动)，默认YES。⚠️如无必要 请勿修改
/// [YES] 执行`play`后，SDK会自动根据当前音频的pts返回对应的视频帧，见`UIView<IVVideoRenderable> *videoView`；
/// [NO]  执行`play`后，SDK不会自动返回视频帧，需由开发者通过`getVideoFrame:`获取并做音视频对齐；
@property (nonatomic, assign, readwrite) BOOL syncAudio;

/// 获取PCM音频数据, 建议由音频播放单元驱动（例如在playbackCallback中调用该方法）
/// @param aframe [IN][OUT]用于接收音频帧数据
/// @note aframe入参时 `aframe->data`不可为NULL，aframe->size`不可为0；
/// @return [YES]成功，[NO]失败
- (BOOL)getAudioFrame:(IVAudioFrame *)aframe;

/// 获取YUV视频数据
/// 仅当`syncAudio=NO`时有效。
/// @param vframe [IN][OUT]用于接收视频帧数据
/// @note vframe入参时 `vframe->data[i]`不可为NULL，vframe->linesize[i]`不可为0；
/// @return [YES]成功，[NO]失败
- (BOOL)getVideoFrame:(IVVideoFrame *)vframe;

@end

NS_ASSUME_NONNULL_END
