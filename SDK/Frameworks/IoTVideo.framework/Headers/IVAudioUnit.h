//
//  IVAudioUnit.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IoTVideo/IVAudioRenderable.h>
#import <IoTVideo/IVAudioCapturable.h>

NS_ASSUME_NONNULL_BEGIN

/// AudioRender + AudioCapture
/// 使用AUGraph同时管理音频渲染和采集
@interface IVAudioUnit : NSObject <IVAudioRenderable, IVAudioCapturable>

// 默认值
// isRendering = NO;
// handsFree  = YES;
// mute       = NO;
// volume     = 1.0;
//
// isCapturing = NO;
// bitWidth   = 16;
// silent     = YES;
// audioMode  = IVAudioSoundModeMono;
// sampleRate = kRecordSampleRate;

@end


NS_ASSUME_NONNULL_END
