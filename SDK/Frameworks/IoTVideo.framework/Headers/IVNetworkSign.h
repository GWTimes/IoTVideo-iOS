//
//  IVNetworkSign.h
//  IoTVideo
//
//  Created by ZhaoYong on 2019/12/6.
//  Copyright © 2019 gwell. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IVNetworkSign : NSObject

/// sha256 散列
/// @param str 需要散列字符串
+ (NSString *)SHA256WithString:(NSString *)str;

/// HMAM-SHA1 签名
/// @param str 需要签名字符串
+ (NSString *)HMACSHA1WithString:(NSString *)str;

@end

NS_ASSUME_NONNULL_END
