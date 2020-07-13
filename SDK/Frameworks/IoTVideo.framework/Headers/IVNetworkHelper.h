//
//  IVNetworkHelper.h
//  IoTVideo
//
//  Created by JonorZhang on 2020/6/3.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IVNetworkHelper : NSObject

+ (void)startMonitor;

@property (class, nonatomic, copy, readonly) NSString *currentWiFiSSID;

@end

NS_ASSUME_NONNULL_END
