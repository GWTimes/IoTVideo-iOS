//
//  IVVideoDecoder.h
//  IVAVUtils
//
//  Created by JonorZhang on 2020/7/27.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IoTVideo/IVVideoDecodable.h>

NS_ASSUME_NONNULL_BEGIN

@interface IVVideoDecoder : NSObject <IVVideoDecodable>

/// 可用的视频解码器
/// 开发者可以修改此属性以支持更多格式
/// - KeyType          IVVideoCodecType
/// - ObjectType      id<IVVideoDecodable>.class
@property (class, nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, Class> *availableVideoDecoders;

@end

NS_ASSUME_NONNULL_END
