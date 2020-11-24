//
//  IVVideoRenderable.h
//  IoTVideo
//
//  Created by JonorZhang on 2020/7/27.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVAVDefine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IVVideoRenderDataSource <NSObject>

/// 获取YUV视频数据
/// @param[in,out] vframe 用于接收视频帧数据
/// @note vframe入参时 `vframe->data[i]`不可为NULL（由开发者malloc和free），vframe->linesize[i]`不可为0；
/// @return [YES]成功，[NO]失败
- (BOOL)getVideoFrame:(IVVideoFrame *)vframe;

@end

/// 视频渲染器协议
@protocol IVVideoRenderable <NSObject>

/// 视频画面
@property (nonatomic, strong, readonly) UIView *videoView;

/// 视频画面截图
/// @param completionHandler 完成回调
- (void)takeScreenshot:(void(^)(UIImage * _Nullable image))completionHandler;

/// 是否正在运行
@property (nonatomic, assign, readonly) BOOL isRendering;

/// 开始运行
/// @param avheader 流媒体信息头
/// @param channel 通道ID
/// @param dataSource 数据源
- (BOOL)startRenderingWithAVHeader:(IVAVHeader)avheader channel:(uint32_t)channel dataSource:(id<IVVideoRenderDataSource>)dataSource;

/// 停止运行
- (void)stopRendering;

@end

NS_ASSUME_NONNULL_END
