//
//  IVVideoCapture.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IoTVideo/IVVideoCapturable.h>

@interface IVVideoCapture : NSObject <IVVideoCapturable>

/// 默认构造器
/// definition: IVVideoDefinitionLow
/// pixFmt: IVPixelFormatType32BGRA
/// frameRate: 16
- (instancetype)init;

/// 自定义构造器
- (instancetype)initWithDefinition:(IVVideoDefinition)definition pixFmt:(IVPixelFormatType)pixFmt frameRate:(int)frameRate;

@end

