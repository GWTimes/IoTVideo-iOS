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

#import "IVAVUtils.h"

#import "IVMessageMgr.h"
#import "IVConnection.h"

NS_ASSUME_NONNULL_BEGIN

@class IVPlayer;

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

/// SD卡回放文件播放结束
/// @param player 播放器实例
/// @param startTime 当前播放结束的文件的开始时间
- (void)player:(IVPlayer *)player didFinishPlaybackFile:(NSTimeInterval)startTime;

/// 观众人数变更
/// @param player 播放器实例
/// @param audience 观众人数
- (void)player:(IVPlayer *)player didUpdateAudience:(NSInteger)audience;

/// 播放错误回调
/// @param player 播放器实例
/// @param error 错误实例, 见 @c `IVPlayerError`
- (void)player:(IVPlayer *)player didReceiveError:(NSError *)error;

/// 音视频头信息回调
/// @param player  播放器实例
/// @param avHeader 音视频头信息
- (void)player:(IVPlayer *)player didReceiveAVHeader:(IVAVHeader)avHeader;

@end

/// 播放器可对讲协议
@protocol IVPlayerTalkable <IVAudioCaptureDelegate>

/// 对讲和视频通话时APP端使用的流媒体信息头, 由对应采集器和编码器参数组合而成, 建立连接时会发送给设备。
@property (nonatomic, assign, readonly) IVAVHeader encHeader;

/// 音频采集器, 默认为 `IVAudioCapture`
@property (nonatomic, strong, readwrite) id<IVAudioCapturable> audioCapture;

/// 音频编码器, 默认为 `IVAudioEncoder`
@property (nonatomic, strong, readwrite) id<IVAudioEncodable> audioEncoder;

/// 是否正在对讲
@property (nonatomic, assign, readonly) BOOL isTalking;

/// 开启对讲
/// 开启后APP开始发送音频数据，若开启前后需发送其他通信数据，如唤醒设备扬声器等，请使用`发送自定义数据`方法，参见`-[IVConnection sendData:]`
- (void)startTalking;

/// 关闭对讲
/// 关闭后APP停止发送音频数据，若关闭前后需发送其他通信数据，如关闭设备扬声器等，请使用`发送自定义数据`方法，参见`-[IVConnection sendData:]`
- (void)stopTalking;

@end


/// 播放器可视频协议
@protocol IVPlayerVideoable <IVVideoCaptureDelegate>

/// 对讲和视频通话时APP端使用的流媒体信息头, 由对应采集器和编码器参数组合而成, 建立连接时会发送给设备。
@property (nonatomic, assign, readonly) IVAVHeader encHeader;

/// 视频采集器, 默认为 `IVVideoCapture`
@property (nonatomic, strong, readwrite) id<IVVideoCapturable> videoCapture;

/// 视频编码器, 默认为 `IVVideoEncoder`
@property (nonatomic, strong, readwrite) id<IVVideoEncodable> videoEncoder;

/// 摄像头预览图层
@property (nonatomic, strong, readonly) CALayer *previewLayer;

/// 镜头位置
@property (nonatomic, assign, readwrite) IVCameraPosition cameraPosition;

/// 是否正在开启摄像头
@property (nonatomic, assign, readonly) BOOL isCameraOpening;

/// 视频帧率，默认16
@property (nonatomic, assign, readwrite) int frameRate;

/// 启动摄像头
- (void)openCamera;

/// 关闭摄像头
- (void)closeCamera;

/// 切换摄像头
- (void)switchCamera;

@end


/// 核心播放器
/// @note IVPlayer为抽象基类，请勿直接实例化，应使用其派生类:IVLivePlayer、IVPlaybackPlayer和IVMonitorPlayer
@interface IVPlayer : IVConnection <IVAudioRenderDataSource, IVVideoRenderDataSource>

/// 播放器代理
@property (nonatomic, weak, nullable) id<IVPlayerDelegate> delegate;

/// 接收到设备端端的流媒体信息头
@property (nonatomic, assign, readonly) IVAVHeader avheader;

/// 视频画面
@property (nonatomic, strong, readonly) UIView *videoView;

/// 播放器状态
@property (nonatomic, assign, readonly) IVPlayerStatus status;

/// 当前播放时间戳（秒）
@property (nonatomic, assign, readonly) NSTimeInterval pts;

/// 视频清晰度, set方法内部会触发发送切换分辨率指令给设备
@property (nonatomic, assign, readwrite) IVVideoDefinition definition;

/// 静音，  默认NO（即允许播放声音）
@property (nonatomic, assign, readwrite) BOOL mute;

/// 免提， 默认YES, 有外设时无效
/// @li YES 没有外设时外放声音
/// @li NO  没有外设时听筒处播放声音
@property (nonatomic, assign, readwrite) BOOL handsFree;

#pragma mark - 控制

/// 预连接(可选)
/// @note 设备会发送流媒体信息头，但不会发送音视频数据
- (void)prepare;

/// 开始播放
/// @note 设备会发送流媒体信息头，接着发送音视频数据
- (void)play;

/// 停止播放
/// @note 该操作APP将与设备断开连接
- (void)stop;

/// 截图
/// @param completionHandler 截图回调
- (void)takeScreenshot:(void(^)(UIImage * _Nullable image))completionHandler;

/// 是否正在录像
@property (nonatomic, assign, readonly) BOOL isRecording;

/// 开始录像
/// @param savePath 录像文件路径
/// @param completionHandler 完成回调
- (void)startRecording:(NSString *)savePath completionHandler:(void(^)(NSString * _Nullable savePath, NSError * _Nullable error))completionHandler;

/// 停止录像
- (void)stopRecording;

#pragma mark - 解码器/渲染器/录制器

/// 音频解码器, 默认为 `IVAudioDecoder`
@property (nonatomic, strong, readwrite) id<IVAudioDecodable> audioDecoder;

/// 音频渲染器, 默认为 `IVAudioRender`
@property (nonatomic, strong, readwrite) id<IVAudioRenderable> audioRender;

/// 视频解码器, 默认为 `IVVideoDecoder`
@property (nonatomic, strong, readwrite) id<IVVideoDecodable> videoDecoder;

/// 视频渲染器, 默认为`IVVideoRender`
@property (nonatomic, strong, readwrite) id<IVVideoRenderable> videoRender;

/// 音视频录制器, 默认为`IVAVRecorder`
@property (nonatomic, strong, readwrite) id<IVAVRecordable> avRecorder;

@end

NS_ASSUME_NONNULL_END
