//
//  IVAudioEncoder.h
//  IVAVUtils
//
//  Created by JonorZhang on 2020/7/27.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IoTVideo/IVAudioEncodable.h>

NS_ASSUME_NONNULL_BEGIN

@interface IVAudioEncoder : NSObject <IVAudioEncodable>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAudioType:(IVAudioCodecType)audioType sampleRate:(uint32_t)sampleRate audioMode:(IVAudioSoundMode)audioMode bitWidth:(uint8_t)bitWidth NS_DESIGNATED_INITIALIZER;

/// 可用的音频编码器
/// 开发者可以修改此属性以支持更多格式
/// - KeyType          IVAudioCodecType
/// - ObjectType      id<IVAudioEncodable>.class
@property (class, nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, Class> *availableAudioEncoders;

@end

NS_ASSUME_NONNULL_END
