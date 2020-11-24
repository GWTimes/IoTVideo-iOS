//
//  IVAVRecorder.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/22.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IoTVideo/IVAVRecordable.h>

NS_ASSUME_NONNULL_BEGIN

/// AudioRecorder + VideoRecorder
@interface IVAVRecorder : NSObject<IVAVRecordable>

/// 通道ID
@property (nonatomic, assign, readonly) uint32_t channel;

@end

NS_ASSUME_NONNULL_END
