//
//  IVAudioDecoder.h
//  IVAVUtils
//
//  Created by JonorZhang on 2020/7/27.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IoTVideo/IVAudioDecodable.h>

NS_ASSUME_NONNULL_BEGIN

@interface IVAudioDecoder : NSObject <IVAudioDecodable>

/// 可用的音频解码器
/// 开发者可以修改此属性以支持更多格式
/// - KeyType          IVAudioCodecType
/// - ObjectType      id<IVAudioDecodable>.class
@property (class, nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, Class> *availableAudioDecoders;

@end

NS_ASSUME_NONNULL_END
