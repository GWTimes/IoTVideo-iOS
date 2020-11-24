//
//  IVUtils_internal.h
//  IotVideo
//
//  Created by JonorZhang on 2019/11/1.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#ifndef IVUtils_h
#define IVUtils_h

#import <Foundation/Foundation.h>

/// NSData转十六进制NSString
///
/// 仅转换前100个字节，超过部分省略，形如 {length=195, bytes=0x00000000 00000000 00000000...}
/// @param data 要转换的data
/// @return data的十六进制字符串
extern NSString *convertDataToHexStr(NSData *data);

/// 计算任意时间当天开始时间
///
/// 例如：输入1604073623 ( 2020-10-31 00:00:23 UTC+8) ，输出1604073600 ( 2020-10-31 00:00:00 UTC+8)
/// @param time The time interval since 00:00:00 UTC on 1 January 1970.
/// @return The start time of the date since 00:00:00 UTC on 1 January 1970.
extern NSInteger startTimeOfDate(NSInteger time);


/// 获取SDK运行环境
extern NSString *getSDKEnvironment(void);

#endif /* IVUtils_h */
