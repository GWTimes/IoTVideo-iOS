//
//  IVAVDefine.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/14.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef IVAVDefine_h
#define IVAVDefine_h

/// 音视频连接类型
typedef NS_ENUM(NSUInteger, IVAVConnType) {
    IVAVConnTypeLive     = 0,      //!< 视频呼叫，双向音视频
    IVAVConnTypeMonitor  = 1,      //!< 监控，单向视频，双向音频（对讲）
    IVAVConnTypePlayback = 2,      //!< 录像回放
};

/// 播放器状态
typedef NS_ENUM(NSUInteger, IVPlayerStatus) {
    IVPlayerStatusStoped,          //!< 停止
    IVPlayerStatusPreparing,       //!< 准备中
    IVPlayerStatusReady,           //!< 就绪
    IVPlayerStatusLoading,         //!< 加载中
    IVPlayerStatusPlaying,         //!< 播放中
    IVPlayerStatusPaused,          //!< 暂停
    IVPlayerStatusFastForward,     //!< 快进中
};

/// 多媒体类型
typedef NS_ENUM(NSUInteger, IVMediaType) {
    IVMediaTypeVideo,
    IVMediaTypeAudio,
};

/// 视频编码类型
typedef NS_ENUM(NSUInteger, IVVideoCodecType) {
    IVVideoCodecTypeH264  = 1,
    IVVideoCodecTypeMPEG4 = 2,
    IVVideoCodecTypeJPEG  = 3,
    IVVideoCodecTypeMJPEG = 4,
    IVVideoCodecTypeH265  = 5,
};

/// 视频像素格式
typedef NS_ENUM(NSUInteger, IVPixelFormatType) {
    IVPixelFormatTypeYUV420P = 0,
    IVPixelFormatType32BGRA  = 1,
};

/// 视频清晰度
typedef NS_ENUM(NSUInteger, IVVideoDefinition) {
    IVVideoDefinitionLow  = 0,
    IVVideoDefinitionMid  = 1,
    IVVideoDefinitionHigh = 2,
};

/// 音频编码类型
typedef NS_ENUM(NSUInteger, IVAudioCodecType) {
    IVAudioCodecTypeG711A  = 1,
    IVAudioCodecTypeG711U  = 2,
    IVAudioCodecTypeG726   = 3,
    IVAudioCodecTypeAAC    = 4,
    IVAudioCodecTypeAMR    = 5,
    IVAudioCodecTypeADPCMA = 6,
};

/// 音频每个采样的位宽
typedef NS_ENUM(NSUInteger, IVAudioBitWidth) {
    IVAudioBitWidth8  = 0,
    IVAudioBitWidth16 = 1,
    IVAudioBitWidth32 = 2,
};

/// 音频声道模式
typedef NS_ENUM(NSUInteger, IVAudioSoundMode) {
    IVAudioSoundModeMono   = 0, /**< 单声道 */
    IVAudioSoundModeStereo = 1, /**< 立体声 */
};

/// 音频格式
typedef NS_ENUM(NSUInteger, IVAudioFormat) {
    IVAudioFormatLinearPCM = 0,
};

/// 视频原始帧
typedef struct IVVideoFrame {
    // For YUV: [0]Y [1]U [2]V,
    // For RGBA: [0]BGRA

    IVPixelFormatType type;
    uint8_t    *data[3];
    uint32_t    linesize[3];
    uint32_t    width;
    uint32_t    height;
    uint64_t    pts;
} IVVideoFrame;

/// 音频原始帧
typedef struct IVAudioFrame {
    IVAudioFormat type; //!< 音频采样格式
    uint8_t    *data;   //!< [IN][OUT] 缓冲区地址
    uint32_t    size;   //!< [IN] data最大容量,  [OUT] data有效长度
    uint64_t    pts;    //!< 时间戳，may be 0。
} IVAudioFrame;

/// 视频数据包
typedef struct IVVideoPacket {
    IVVideoCodecType type;
    uint8_t    *data;
    int         size;
    bool        keyFrame;
    uint64_t    dts;
    uint64_t    pts;
} IVVideoPacket;

/// 音频数据包
typedef struct IVAudioPacket {
    IVAudioCodecType type;
    uint8_t    *data;
    int         size;
    uint64_t    pts; 
} IVAudioPacket;

/// 摄像头方位
typedef NS_ENUM(NSUInteger, IVCameraPosition) {
    IVCameraPositionFront,
    IVCameraPositionBack,
};

// 音视频头信息
typedef struct IVAVHeader {
    /*audio info*/
    IVAudioCodecType    audioType;         //!< 音频编码格式
    IVAudioSoundMode    audioMode;         //!< 音频模式： 单声道/双声道
    uint8_t             audioCodecOption;  //!< 音频编码格式的细分类型
    uint8_t             audioBitWidth;     //!< 音频位宽
    uint32_t            audioSampleRate;   //!< 音频采样率
    uint32_t            sampleNumPerFrame; //!< 每帧数据里的采样数
    
    /*video info*/
    IVVideoCodecType    videoType;         //!< 视频类型(h264/h265)
    uint8_t             videoFrameRate;    //!< 视频帧率
    uint32_t            videoWidth;        //!< 视频像素宽度
    uint32_t            videoHeight;       //!< 视频像素高度
} IVAVHeader;

#endif /* IVAVDefine_h */
