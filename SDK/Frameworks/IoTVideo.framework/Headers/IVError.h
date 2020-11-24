//
//  IVError.h
//  IoTVideo
//
//  Created by JonorZhang on 2020/3/30.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef IVError_h
#define IVError_h

/**
    ====== 错误码区间分布 =====
    @li [8000-8499]      Asrv错误码
    @li [8500-8699]      Csrv错误码(对接Asrv)
    @li [8799-9999]       预留
    @li [10000-10999]   通用错误码
    @li [11000-11999]   产品/设备相关
    @li [12000-12999]   用户相关
    @li [13000-13999]   客户相关
    @li [14000-14999]   云存相关
    @li [15000-15999]   UPG相关
    @li [16000-16999]   帮助中心
    @li [17000-17999]    第三方调用
    @li [20000-20999]    P2P错误码
    @li [21000-21999]   iOS SDK错误
    @li [22000-22999]   Android SDK错误码
    @li [23000-23999]   PC SDK错误码
    @li [24000-24999]   DEV SDK错误码
 */


/**
    ===== iOS SDK错误码 =====
    @li [21000-21019]      消息错误, 详见`IVMessageError`
    @li [21020-21029]      连接错误, 详见`IVConnError`
    @li [21030-21049]      播放错误, 详见`IVPlayerError`
 */


/**
    ===== P2P错误码 =====
 */
typedef NS_ENUM(NSUInteger, IVTermErr) {
    //!< 终端使用
    IVTermErr_msg_send_peer_timeout          = 20001, //!< 消息发送给对方超时
    //calling相关
    IVTermErr_msg_calling_hangup             = 20002, //!< 普通挂断，即设备端主动断开
    IVTermErr_msg_calling_send_timeout       = 20003, //!< calling消息发送超时
    IVTermErr_msg_calling_no_srv_addr        = 20004, //!< 服务器未分配转发地址
    IVTermErr_msg_calling_handshake_timeout  = 20005, //!< 握手超时
    IVTermErr_msg_calling_token_error        = 20006, //!< 设备端token校验失败
    IVTermErr_msg_calling_all_chn_busy       = 20007, //!< 监控通道数满
    IVTermErr_msg_calling_timeout_disconnect = 20008, //!< 超时断开
    IVTermErr_msg_calling_no_find_dst_id     = 20009, //!< 未找到目的id
    IVTermErr_msg_calling_check_token_error  = 20010, //!< token校验出错
    IVTermErr_msg_calling_dev_is_disable     = 20011, //!< 设备已经禁用
    IVTermErr_msg_calling_duplicate_call     = 20012, //!< 重复呼叫
    //物模型
    IVTermErr_msg_gdm_handle_processing       = 20100, //!< 设备正在处理中
    IVTermErr_msg_gdm_handle_leaf_path_error  = 20101, //!< 设备端校验叶子路径非法
    IVTermErr_msg_gdm_handle_parse_json_fail  = 20102, //!< 设备端解析JSON出错
    IVTermErr_msg_gdm_handle_fail             = 20103, //!< 设备处理ACtion失败
    IVTermErr_msg_gdm_handle_no_cb_registered = 20104, //!< 设备未注册相应的ACtion回调函数
    IVTermErr_msg_gdm_handle_buildin_prowritable_error = 20105,//!< 设备不允许通过局域网修改内置可写对象
};

/**
   ===== 常见服务器错误码 =====
*/
typedef NS_ENUM(NSUInteger, IVASrvErr) {
    IVASrvErr_dst_offline = 8000, // 目标离线
    IVASrvErr_dst_notexsit = 8002, // 目标不存在
    IVASrvErr_dst_error_relation = 8003, // 非法关系链
    IVASrvErr_binderror_dev_usr_has_bind = 8022, // 设备已经绑定此用户
    IVASrvErr_binderror_dev_has_bind_other = 8023, // 设备已经绑定其他用户
    IVASrvErr_binderror_customer_diffrent = 8024, // 设备的客户ID与用户的客户ID不一致
};


extern NSString *IVErrorDescribe(NSUInteger errorCode);

extern NSError  *IVErrorMake(id target, NSUInteger errorCode, const char *fmt, ...);
extern NSError  *IVErrorMake2(id target, NSUInteger errorCode, NSUInteger reasonCode, const char *fmt, ...);
extern NSError  *IVErrorMake3(id target, NSUInteger errorCode, NSUInteger reasonCode, const char *reasonDesc, const char *fmt, ...);


#endif /* IVError_h */
