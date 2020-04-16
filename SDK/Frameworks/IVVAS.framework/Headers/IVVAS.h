//
//  IVVAS.h
//  IVVAS
//
//  Created by JonorZhang on 2020/4/2.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IoTVideo/IVNetwork_p2p.h>


/// 支付方式
typedef NS_ENUM(NSInteger, IVVASOrderPayType) {
  IVVASOrderPayTypeWxpay = 0,
  IVVASOrderPayTypeAlipay = 1,
};

/// 订单状态
typedef NS_ENUM(NSInteger, IVVASOrderStatus) {
/// 已支付
  IVVASOrderStatusPaid = 0,
/// 未支付
  IVVASOrderStatusUnpaid = 1,
/// 关闭
  IVVASOrderStatusClose = 2,
};

/// 套餐服务类型
typedef NS_ENUM(NSInteger, IVVASServiceType) {
/// 全时套餐
  IVVASServiceTypeVss = 1,
/// 分时套餐
  IVVASServiceTypeEvs = 2,
};


NS_ASSUME_NONNULL_BEGIN

@interface IVVAS : NSObject

/// 增值服务管理单例
+ (instancetype)shareInstance;
@property (nonatomic, class, strong, readonly) IVVAS *shared;

/// SDK版本
@property (class, nonatomic, strong, readonly) NSString *SDKVersion;

// MARK: - 套餐/订单

/// 热度值套餐列表查询
/// @param countryCode  国家二字码,如中国：CN
/// @param responseHandler 回调
- (void)queryPackageHotListWithCountryCode:(NSString *)countryCode responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

/// 查询套餐列表
/// @param countryCode 国家二字码,如中国：CN
/// @param serviceType 套餐类型
///     - vss: 全时套餐
///     - evs: 事件套餐
/// @param responseHandler 回调
- (void)queryPackageListWithCountryCode:(NSString *)countryCode serviceType:(IVVASServiceType)serviceType responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

/// 查询设备已购买服务的概要
/// - 查询设备已经购买的套餐服务概要，主要是服务剩余时间（包括事件服务、全时服务）。
/// @param deviceId 腾讯id
/// @param responseHandler 回调
- (void)queryServiceOutlineWithDeviceId:(NSString *)deviceId responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

/// 查询设备所有支持的服务详情列表
/// - 查询设备所有支持的套餐服务详情列表，包括已激活、未激活、暂停的服务。
/// @param deviceId 腾讯id
/// @param responseHandler 回调
- (void)queryServiceListWithDeviceId:(NSString *)deviceId responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

/// 生成订单
/// @param deviceId 腾讯id
/// @param packageNo 套餐编号
/// @param couponCode 优惠券编号
/// @param timezone 相对于0时区的秒数，例如东八区28800
/// @param responseHandler 回调
- (void)createOrderWithDeviceId:(NSString *)deviceId packageNo:(NSString *)packageNo couponCode:(NSString * _Nullable)couponCode timezone:(NSInteger)timezone responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

/// 查询订单详情
/// @param orderId 订单号
/// @param responseHandler 回调
- (void)queryOrderInfoWithOrderId:(NSString *)orderId responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

/// 查询订单列表
/// - 终端用户查询已购买的订单列表信息。
/// @param deviceId 腾讯id
/// @param orderStatus 订单状态
/// @param responseHandler 回调
- (void)queryOrderListWithDeviceId:(NSString *)deviceId orderStatus:(IVVASOrderStatus)orderStatus responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

/// 订单信息总览
/// - 查看已支付订单、未支付订单和未使用的优惠券总数。
/// @param deviceId 腾讯id
/// @param responseHandler 回调
- (void)queryOrderOverviewWithDeviceId:(NSString *)deviceId responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

/// 生成支付签名信息
/// @param orderId 订单id
/// @param payType 支付方式 wx alipay
/// @param responseHandler 回调
- (void)createPaymentWithOrderId:(NSString *)orderId payType:(IVVASOrderPayType)payType responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

/// 获取支付结果
/// @param orderId 订单id
/// @param responseHandler 回调
- (void)queryPaymentResultWithOrderId:(NSString *)orderId responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

/// 查询可转移套餐服务
- (void)queryCanTransferPackageWithDeviceId:(NSString *)deviceId responseHandler:(void (^)(NSString * _Nullable, NSError * _Nullable))responseHandler;

/// 转移套餐服务
- (void)transferPackageWithDeviceId:(NSString *)deviceId serviceId:(NSString *)serviceId responseHandler:(void (^)(NSString * _Nullable, NSError * _Nullable))responseHandler;


// MARK: - 云回放


/// 获取云存视频列表
/// - 用于终端用户在云存页面中对云存服务时间内的日期进行标注，区分出是否有云存视频文件。
/// @param deviceId 腾讯id
/// @param timezone 相对于0时区的秒数，例如东八区28800
/// @param responseHandler 回调
- (void)getVideoListWithDeviceId:(NSString *)deviceId timezone:(NSInteger)timezone responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

/// 获取云存回放m3u8列表
///- 终端用户获取云存储的m3u8列表进行回放，同时根据返回的列表对时间轴进行渲染。
/// @param deviceId 设备id
/// @param timezone  相对于0时区的秒数，例如东八区28800
/// @param startTime  时间戳，回放开始时间
/// @param endTime 时间戳，回放结束时间
/// @param responseHandler 回调
- (void)getVideoPlaybackListWithDeviceId:(NSString *)deviceId timezone:(NSInteger)timezone startTime:(NSTimeInterval)startTime endTime:(NSTimeInterval)endTime responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

/// 倍速回放
/// @param deviceId 腾讯id
/// @param startTime 倍速回放的开始时间
/// @param speed 倍数
/// @param responseHandler 回调
- (void)videoSpeedPlayWithDeviceId:(NSString *)deviceId startTime:(NSTimeInterval)startTime speed:(NSInteger)speed responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

/// 下载视频m3u8列表
/// - 终端用户在云存页面中对一段时间内的视频文件下载。
/// @param deviceId 腾讯id
/// @param timezone 相对于0时区的秒数，例如东八区28800
/// @param dateTime 时间戳，为当天的零点零分零秒
/// @param responseHandler 回调
- (void)downloadVideoWithDeviceId:(NSString *)deviceId timezone:(NSInteger)timezone dateTime:(NSTimeInterval)dateTime responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;


//MARK:- 事件

/// 事件列表查询
/// @param deviceId 腾讯id
/// @param startTime 事件告警开始时间
/// @param endTime 时间告警结束时间，当为0时，默认当天的23点59分59秒
/// @param lastId 倒序分页查看的最后一条记录ID
/// @param pageSize 每页总数
/// @param responseHandler 回调
- (void)getEventListWithDeviceId:(NSString *)deviceId startTime:(NSTimeInterval)startTime endTime:(NSTimeInterval)endTime lastId:(int64_t)lastId pageSize:(NSInteger)pageSize responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

// FIXME: - 需要和后台讨论
/// 事件删除（批量）
/// @param eventIds 腾讯id 数组
/// @param responseHandler 回调
- (void)deleteEventsWithEventIds:(NSArray<NSNumber *> *)eventIds responseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;


/// 测试p2p
- (void)testP2PRequestWithResponseHandler:(IVNetworkResponseHandler _Nullable)responseHandler;

@end

NS_ASSUME_NONNULL_END

