//
//  IVLog.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/12/31.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, IVLogLevel) {
    IVLogLevel_OFF   = 0,    //!< 不打印日志
    IVLogLevel_FATAL = 1,    //!< 严重
    IVLogLevel_ERROR = 2,    //!< 错误
    IVLogLevel_WARN  = 3,    //!< 警告
    IVLogLevel_INFO  = 4,    //!< 信息
    IVLogLevel_DEBUG = 5,    //!< 调试
    IVLogLevel_TRACE = 6,    //!< 跟踪
};

// 日志输出（DEBUG）
void ivlog(IVLogLevel level, const char *file, const char *func, int line, const char *fmt, ...);

#define logFatal(fmt, ...)   ivlog(IVLogLevel_FATAL, __FILE__, __PRETTY_FUNCTION__, __LINE__, fmt, ##__VA_ARGS__);
#define logError(fmt, ...)   ivlog(IVLogLevel_ERROR, __FILE__, __PRETTY_FUNCTION__, __LINE__, fmt, ##__VA_ARGS__);
#define logWarning(fmt, ...) ivlog(IVLogLevel_WARN,  __FILE__, __PRETTY_FUNCTION__, __LINE__, fmt, ##__VA_ARGS__);
#define logInfo(fmt, ...)    ivlog(IVLogLevel_INFO,  __FILE__, __PRETTY_FUNCTION__, __LINE__, fmt, ##__VA_ARGS__);
#define logDebug(fmt, ...)   ivlog(IVLogLevel_DEBUG, __FILE__, __PRETTY_FUNCTION__, __LINE__, fmt, ##__VA_ARGS__);
#define logVerbose(fmt, ...) ivlog(IVLogLevel_TRACE, __FILE__, __PRETTY_FUNCTION__, __LINE__, fmt, ##__VA_ARGS__);
#define logTrace(fmt, ...)   ivlog(IVLogLevel_TRACE, __FILE__, __PRETTY_FUNCTION__, __LINE__, fmt, ##__VA_ARGS__);

/// 日志输出回调
/// @param level  日志级别, 详见IVLogLevel
/// @param file  文件名
/// @param function  函数名
/// @param line  行号
/// @param message  日志信息
typedef void(^IVLogCallback)(int level, NSString *file, NSString *function, int line, NSString *message);

@interface IVLog : NSObject

+ (void)logDebug:(NSString *)str;
+ (void)logInfo:(NSString *)str;
+ (void)logWarring:(NSString *)str;
@end

NS_ASSUME_NONNULL_END
