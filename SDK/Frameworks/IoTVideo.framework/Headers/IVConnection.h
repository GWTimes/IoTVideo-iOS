//
//  IVConnection.h
//  IoTVideo
//
//  Created by JonorZhang on 2020/5/25.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 最大连接个数
#define MAX_CONNECTION_NUM 16

/// 单个数据包允许最大字节数
#define MAX_PKG_BYTES 64000

/// 连接类型
typedef NS_ENUM(NSUInteger, IVConnType) {
    /// 视频呼叫，双向音视频
    IVConnTypeLive          = 0,
    /// 监控，单向视频，双向音频（对讲）
    IVConnTypeMonitor       = 1,
    /// 录像回放
    IVConnTypePlayback      = 2,
    /// 数据传输
    IVConnTypeTransmission  = 3,
};

/// 连接状态
typedef NS_ENUM(NSInteger, IVConnStatus) {
    /// 断开中...
    IVConnStatusDisconnecting   = -1,
    /// 已断开
    IVConnStatusDisconnected    = 0,
    /// 连接中...
    IVConnStatusConnecting      = 1,
    /// 已连接
    IVConnStatusConnected       = 2,
};

/// 连接错误
typedef NS_ENUM(NSUInteger, IVConnError) {
    /// APP端超过最大通道个数, 见`MAX_CONNECTION_NUM`
    IVConnError_ExceedsMaxNumber  = 21020,
    /// 重复的连接通道, 已存在相同`deviceId + sourceId`
    IVConnError_Duplicate         = 21021,
    /// 建立连接失败
    IVConnError_ConnectFailed     = 21022,
    /// 连接已断开/连接失败
    IVConnError_Disconnected      = 21023,
    /// 超出最大数据长度, 见`MAX_PKG_BYTES`
    IVConnError_ExceedsMaxLength  = 21024,
    /// 当前连接暂不可用
    IVConnError_NotAvailableNow   = 21025,
};

@class IVConnection;


/// 连接代理
@protocol IVConnectionDelegate <NSObject>

@optional

/// 状态更新
/// @param connection 连接实例
/// @param status 状态
- (void)connection:(IVConnection *)connection didUpdateStatus:(IVConnStatus)status;

/// 数据接收速率
/// @param connection 连接实例
/// @param speed 接收速率(字节/秒)
- (void)connection:(IVConnection *)connection didUpdateSpeed:(uint32_t)speed;

/// 收到错误
/// @param connection 连接实例
/// @param error 错误, 见`IVConnError` / [`IVError`、`IVLinkStatus`]
- (void)connection:(IVConnection *)connection didReceiveError:(NSError *)error;

/// 收到数据
/// @param connection 连接实例
/// @param data 数据
- (void)connection:(IVConnection *)connection didReceiveData:(NSData *)data;

@end


/// 通道连接
/// @note IVConnection为抽象基类，请勿直接实例化，应使用其派生类:IVLivePlayer、IVPlaybackPlayer、IVMonitorPlayer和IVTransmission
@interface IVConnection: NSObject

/// 连接代理
@property (nonatomic, weak, nullable) id<IVConnectionDelegate> delegate;

/// 设备ID
@property (nonatomic, strong, readonly) NSString *deviceId;

/// 源ID（一个设备 可以对应 多个源）
@property (nonatomic, assign, readonly) uint16_t sourceId;

/// 通道ID，连接成功该值才有效（一个设备+一个源 对应 唯一通道）
@property (nonatomic, assign, readonly) uint32_t channel;

/// 连接类型
@property (nonatomic, assign, readonly) IVConnType connType;

/// 连接状态
@property (nonatomic, assign, readonly) IVConnStatus connStatus;

/// 开始连接
/// 该方法较耗时, 建议在子线程执行
- (void)connect;

/// 断开连接
- (void)disconnect;

/// 发送自定义数据
///
/// 需要与设备建立专门的连接通道，适用于较大数据传输、实时性要求较高的场景，如多媒体数据传输。
/// 接收到设备端发来的数据见`-[IVConnectionDelegate connection:didReceiveData:]`
/// @param data 要发送的数据，data.length不能超过`MAX_PKG_BYTES`
/// @return 发送是否成功
- (BOOL)sendData:(NSData *)data;

@end


NS_ASSUME_NONNULL_END
