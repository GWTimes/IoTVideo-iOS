//
//  IVVideoEncoder.h
//  IVAVUtils
//
//  Created by JonorZhang on 2020/7/27.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IoTVideo/IVVideoEncodable.h>

NS_ASSUME_NONNULL_BEGIN

/// 视频编码器
@interface IVVideoEncoder : NSObject <IVVideoEncodable>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithVideoType:(IVVideoCodecType)videoType size:(CGSize)videoSize pixFmt:(IVPixelFormatType)pixFmt frameRate:(int)frameRate NS_DESIGNATED_INITIALIZER;

/// 可用的视频编码器
/// 开发者可以修改此属性以支持更多格式
/// - KeyType          IVVideoCodecType
/// - ObjectType      id<IVVideoEncodable>.class
@property (class, nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, Class> *availableVideoEncoders;

@end

NS_ASSUME_NONNULL_END
