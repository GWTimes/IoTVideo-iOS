//
//  IVMessageMgr.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/27.
//  Copyright © 2019 gwell. All rights reserved.
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

/// 透传数据给设备（无数据回传）
/// 使用在不需要数据回传的场景，如发送控制指令
/// @note 完成回调条件：收到ACK 或 消息超时
/// @param deviceId 设备ID
/// @param data 数据内容
/// @param completionHandler 完成回调
- (void)sendDataToDevice:(NSString *)deviceId
                    data:(NSData *)data
         withoutResponse:(nullable IVMsgDataCallback)completionHandler;

/// 透传数据给设备（有数据回传）
/// 使用在预期有数据回传的场景，如获取信息
/// @note 完成回调条件：收到ACK错误、消息超时 或 有数据回传
/// @param deviceId 设备ID
/// @param data 数据内容
/// @param completionHandler 完成回调
- (void)sendDataToDevice:(NSString *)deviceId
                    data:(NSData *)data
            withResponse:(nullable IVMsgDataCallback)completionHandler;

/// 透传数据给设备
/// 可使用在需要数据回传的场景，如获取信息
/// @note 可以等待有数据回传时才完成回调, 如忽略数据回传可简单使用`sendDataToDevice:data:completionHandler:`代替。
/// @param deviceId 设备ID
/// @param data 数据内容
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
/// @param data 数据内容
/// @param completionHandler 完成回调
- (void)sendDataToServer:(NSString *)url
                    data:(nullable NSData *)data
       completionHandler:(nullable IVMsgDataCallback)completionHandler;

/// 透传数据给服务器
/// @param url 服务器路径
/// @param data 数据内容
/// @param timeout 超时时间
/// @param completionHandler 完成回调
- (void)sendDataToServer:(NSString *)url
                    data:(nullable NSData *)data
                 timeout:(NSTimeInterval)timeout
       completionHandler:(nullable IVMsgDataCallback)completionHandler;

@end


NS_ASSUME_NONNULL_END
