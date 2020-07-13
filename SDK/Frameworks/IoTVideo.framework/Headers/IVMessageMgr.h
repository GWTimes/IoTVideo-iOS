//
//  IVMessageMgr.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/27.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define IVMsgTimeoutAuto  0.0

typedef void(^IVMsgJSONCallback)(NSString * _Nullable json, NSError * _Nullable error);
typedef void(^IVMsgDataCallback)(NSData * _Nullable data, NSError * _Nullable error);

@class IVMessageMgr;

/// 消息代理协议
@protocol IVMessageDelegate <NSObject>

@optional
/// 接收到事件消息（Event）:  告警、分享、系统通知
/// @param event 事件消息体
/// @param topic 请参照物模型定义
- (void)didReceiveEvent:(NSString *)event topic:(NSString *)topic;

/// 接收到只读属性消息（ProReadonly）
/// @param json 内容（JSON的具体字符串）
/// @param path 路径（JSON的叶子节点）
/// @param deviceId 设备ID
- (void)didUpdateProperty:(NSString *)json path:(NSString *)path deviceId:(NSString *)deviceId;

@end


/// 消息管理类
@interface IVMessageMgr : NSObject

/// 消息管理单例
@property (class, nonatomic, strong, readonly) IVMessageMgr *sharedInstance;
+ (instancetype)sharedInstance;

/// 消息代理
@property (nonatomic, weak) id<IVMessageDelegate> delegate;

/// 全局消息默认超时时间，10秒，不可修改 单个消息可以单独设置
@property (nonatomic, assign, readonly) NSTimeInterval defaultTimeout;


#pragma mark - 物模型方法

/// 写入属性
/// @param deviceId 设备ID
/// @param path 路径（JSON的叶子节点）
/// @param json  内容（JSON的具体字符串）
/// @param completionHandler 完成回调
- (void)writePropertyOfDevice:(NSString *)deviceId
                         path:(NSString *)path
                         json:(NSString *)json
            completionHandler:(nullable IVMsgJSONCallback)completionHandler;

/// 写入属性
/// @param deviceId 设备ID
/// @param path 路径（JSON的叶子节点）
/// @param json  内容（JSON的具体字符串）
/// @param timeout 超时时间
/// @param completionHandler 完成回调
- (void)writePropertyOfDevice:(NSString *)deviceId
                         path:(NSString *)path
                         json:(NSString *)json
                      timeout:(NSTimeInterval)timeout
            completionHandler:(nullable IVMsgJSONCallback)completionHandler;

/// 读取属性
/// @param deviceId 设备ID
/// @param path 路径（JSON的叶子节点）
/// @param completionHandler 完成回调
- (void)readPropertyOfDevice:(NSString *)deviceId
                        path:(NSString *)path
           completionHandler:(nullable IVMsgJSONCallback)completionHandler;

/// 读取属性
/// @param deviceId 设备ID
/// @param path 路径（JSON的叶子节点）
/// @param timeout 超时时间
/// @param completionHandler 完成回调
- (void)readPropertyOfDevice:(NSString *)deviceId
                        path:(NSString *)path
                     timeout:(NSTimeInterval)timeout
           completionHandler:(nullable IVMsgJSONCallback)completionHandler;

/// 执行动作
/// @param deviceId 设备ID
/// @param path 路径（JSON的叶子节点）
/// @param json  内容（JSON的具体字符串）
/// @param completionHandler 完成回调
- (void)takeActionOfDevice:(NSString *)deviceId
                      path:(NSString *)path
                      json:(NSString *)json
         completionHandler:(nullable IVMsgJSONCallback)completionHandler;

/// 执行动作
/// @param deviceId 设备ID
/// @param path 路径（JSON的叶子节点）
/// @param json  内容（JSON的具体字符串）
/// @param timeout 超时时间
/// @param completionHandler 完成回调
- (void)takeActionOfDevice:(NSString *)deviceId
                      path:(NSString *)path
                      json:(NSString *)json
                   timeout:(NSTimeInterval)timeout
         completionHandler:(nullable IVMsgJSONCallback)completionHandler;


#pragma mark - 透传消息方法

#define MAX_DATA_SIZE 30000

/// 透传数据给设备（无数据回传）
///
/// 不需要建立通道连接，数据经由服务器转发，适用于实时性不高、数据小于`MAX_DATA_SIZE`、不需要回传的场景，如控制指令。
/// @note 完成回调条件：收到ACK 或 消息超时
/// @param deviceId 设备ID
/// @param data 数据内容，data.length不能超过`MAX_DATA_SIZE`
/// @param completionHandler 完成回调
- (void)sendDataToDevice:(NSString *)deviceId
                    data:(NSData *)data
         withoutResponse:(nullable IVMsgDataCallback)completionHandler;


/// 透传数据给设备（有数据回传）
///
/// 不需要建立通道连接，数据经由服务器转发，适用于实时性不高、数据小于`MAX_DATA_SIZE`、需要回传的场景，如获取信息。
/// @note 完成回调条件：收到ACK错误、消息超时 或 有数据回传
/// @param deviceId 设备ID
/// @param data 数据内容，data.length不能超过`MAX_DATA_SIZE`
/// @param completionHandler 完成回调
- (void)sendDataToDevice:(NSString *)deviceId
                    data:(NSData *)data
            withResponse:(nullable IVMsgDataCallback)completionHandler;


/// 透传数据给设备
///
/// 不需要建立通道连接，数据经由服务器转发，适用于实时性要求不高，数据小于`MAX_DATA_SIZE`的场景，如控制指令、获取信息。
/// @note 相关接口 @c `sendDataToDevice:data:withoutResponse:`、`sendDataToDevice:data:withResponse:`。
/// @param deviceId 设备ID
/// @param data 数据内容，data.length不能超过`MAX_DATA_SIZE`
/// @param timeout 自定义超时时间，默认超时时间可使用@c `IVMsgTimeoutAuto`
/// @param expectResponse 【YES】预期有数据回传 ；【NO】忽略数据回传
/// @param completionHandler 完成回调
- (void)sendDataToDevice:(NSString *)deviceId
                    data:(NSData *)data
                 timeout:(NSTimeInterval)timeout
          expectResponse:(BOOL)expectResponse
       completionHandler:(nullable IVMsgDataCallback)completionHandler;


/// 透传数据给服务器
/// @param url 服务器路径
/// @param data 数据内容，data.length不能超过`MAX_DATA_SIZE`
/// @param completionHandler 完成回调
- (void)sendDataToServer:(NSString *)url
                    data:(nullable NSData *)data
       completionHandler:(nullable IVMsgDataCallback)completionHandler;


/// 透传数据给服务器
/// @param url 服务器路径
/// @param data 数据内容，data.length不能超过`MAX_DATA_SIZE`
/// @param timeout 超时时间
/// @param completionHandler 完成回调
- (void)sendDataToServer:(NSString *)url
                    data:(nullable NSData *)data
                 timeout:(NSTimeInterval)timeout
       completionHandler:(nullable IVMsgDataCallback)completionHandler;

@end

/// 消息管理错误码
typedef NS_ENUM(NSUInteger, IVMessageError) {
    /// 消息重复、消息正在发送
    IVMessageError_duplicate        = 21000,
    /// 消息发送失败
    IVMessageError_sendFailed       = 21001,
    /// 消息响应超时
    IVMessageError_timeout          = 21002,
    /// 获取物模型失败
    IVMessageError_GetGdmDataErr    = 21003,
    /// 接收物模型失败
    IVMessageError_RcvGdmDataErr    = 21004,
    /// 透传数据给服务器失败
    IVMessageError_SendPassSrvErr   = 21005,
    /// 透传数据给设备失败
    IVMessageError_SendPassDevErr   = 21006,
    /// 没有找到回调
    IVMessageError_NotFoundCallback = 21007,
    /// 数据超过上限
    IVMessageError_ExceedsMaxLength = 21008,
};

NS_ASSUME_NONNULL_END
