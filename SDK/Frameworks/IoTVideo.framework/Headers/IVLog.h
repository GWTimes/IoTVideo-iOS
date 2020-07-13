//
//  IVLog.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/12/31.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef IVLog_h
#define IVLog_h

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, IVLogLevel) {
    /// 不打印日志
    IVLogLevel_OFF   = 0,
    /// 严重
    IVLogLevel_FATAL = 1,
    /// 错误
    IVLogLevel_ERROR = 2,
    /// 警告
    IVLogLevel_WARN  = 3,
    /// 信息
    IVLogLevel_INFO  = 4,
    /// 调试
    IVLogLevel_DEBUG = 5,
    /// 跟踪
    IVLogLevel_TRACE = 6,
};

/// 日志输出回调
/// @param level  日志级别, 详见IVLogLevel
/// @param file  文件名
/// @param function  函数名
/// @param line  行号
/// @param message  日志信息
typedef void(^IVLogCallback)(int level, NSString *file, NSString *function, int line, NSString *message);

NS_ASSUME_NONNULL_END

#endif /* IVLog_h */
