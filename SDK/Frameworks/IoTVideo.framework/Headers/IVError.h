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

typedef NS_ENUM(int64_t, IVErrorCode) {
    IVErrorCode_error_none = 0,                                                 //!< 成功

    //!< 中心服务器返回的错误码
    IVErrorCode_AC_frm_type_err = 1,                                                //!< 帧类型错误
    IVErrorCode_AC_frm_len_err = 2,                                                 //!< 帧长度错误
    IVErrorCode_AC_frm_bson_hashval_err = 3,                                        //!< bson数据与bson哈希值不匹配
    IVErrorCode_AC_GdmType_err = 4,                                                 //!< 无效的GdmType
    IVErrorCode_AC_UploadReq_termid_is_not_dev_err = 5,                             //!< GACFRM_Bson_UploadReq帧上传的不是一个设备id
    IVErrorCode_AC_MsgBody_GdmBsonDat_Leaf_length_err = 6,                          //!< MsgBody_GdmBsonDat结构体中leaf字符串的结束符错误
    IVErrorCode_AC_MsgBody_GdmJsonDat_Leaf_length_err = 7,                          //!< MsgBody_GdmJsonDat结构体中leaf字符串的结束符错误
    IVErrorCode_AC_MsgBody_GetGdmDefBson_err = 8,                                   //!< 获取GdmDefBson错误
    IVErrorCode_AC_MsgBody_GdmJsonDat_length_err = 9,                               //!< MsgBody_GdmJsonDat结构体中json字符串的结束符错误
    IVErrorCode_AC_MsgBody_GdmDat_Leaf_path_err = 10,                               //!< MsgBody_GdmDat结构体中leaf_path无效
    IVErrorCode_AC_MsgBody_GdmDat_content_err = 11,                                 //!< MsgBody_GdmDat结构体中数据无效
    IVErrorCode_AC_csrv_no_term_GdmDat_err = 12,                                    //!< 中心服务器中不存在该终端的物模型
    IVErrorCode_AC_csrv_no_term_err = 13,                                           //!< 中心服务器中找不到该终端
    IVErrorCode_AC_csrv_no_term_productID_err = 14,                                 //!< 中心服务器中没有与该终端对应的productID

    IVErrorCode_AC_TermOnlineReq_olinf_parm_err = 20,                               //!< 初始化请求帧，olinf 参数不正确
    IVErrorCode_AC_TermOnlineReq_opt_with_fp_but_no_with_termid = 21,               //!< 初始化请求帧,置上了opt_with_data_fp，但是没有置上opt_with_termid

    IVErrorCode_AC_Dat_UploadReq_dat_type_json_but_no_opt_with_termid_err = 31,     //!< GACFRM_Dat_UploadReq reqfrm->dat_type是0，但是没有置上opt_with_termid
    IVErrorCode_AC_Dat_UploadReq_dat_type_err = 32,                                 //!< GACFRM_Dat_UploadReq reqfrm->dat_type是0，但是没有置上opt_with_termid

    IVErrorCode_AC_other_err = 100,                                                 //!< 其它类型错误
    IVErrorCode_AC_centerInner_load_bson_err = 101,                                 //!< 中心服务器load_bson失败
    IVErrorCode_AC_centerInner_load_json_err = 102,                                 //!< 中心服务器load_json失败
    IVErrorCode_AC_centerInner_get_bson_raw_err = 103,                              //!< 中心服务器get_bson_raw失败

    IVErrorCode_AC_centerInner_insert_user_fail = 110,                              //!< 中心服务器user哈希表插入失败
    IVErrorCode_AC_centerInner_insert_dev_fail = 111,                               //!< 中心服务器dev哈希表插入失败
    IVErrorCode_AC_centerInner_find_login_user_err = 112,
    IVErrorCode_AC_centerInner_login_user_utcinitchgd_lower_err = 113,
    IVErrorCode_AC_centerInner_login_dev_utcinitchgd_lower_err = 114,

    IVErrorCode_AC_centerInner_processDevLastWord_err = 120,
    IVErrorCode_AC_MsgBody_LastWords_topic_is_not_valide_err = 121,
    IVErrorCode_AC_MsgBody_LastWords_json_is_not_valide_err = 122,
    IVErrorCode_AC_MsgBody_LastWords_not_with_livetime_err = 123,
    IVErrorCode_AC_MsgBody_LastWords_not_with_topic_err = 124,
    IVErrorCode_AC_MsgBody_LastWords_not_with_json_err = 125,
    IVErrorCode_AC_MsgBody_LastWords_action_is_err = 126,
    IVErrorCode_AC_MsgBody_LastWords_query_is_none = 127,                            //!< 中心服务器未查到遗言
    IVErrorCode_ASrv_centerInner_other_err = 200,

    IVErrorCode_ASrv_TempSubscription_termid_is_not_usr_err = 300,                //!< GACFRM_TempSubscription帧上传的不是一个用户id

    IVErrorCode_ASrv_RdbTermListReq_neither_get_online_nor_get_offline_err = 400, //!< GACFRM_RdbTermListReq帧既不获取在线信息也不获取离线信息，从业务上来说这是无意义的

    IVErrorCode_ASrv_AllTermInitReq_other_err = 500,

    //!< 接入服务器返回的错误码
    IVErrorCode_ASrv_dst_offline = 8000,                 //!< 目标离线
    IVErrorCode_ASrv_dst_notfound_asrv = 8001,           //!< 没有找到目标所在的接入服务器
    IVErrorCode_ASrv_dst_notexsit = 8002,                 //!< 目标不存在
    IVErrorCode_ASrv_dst_error_relation = 8003,          //!< 非法关系链
    IVErrorCode_ASrv_data_chkfrm_fail = 8004,          //!< 校验帧失败
    IVErrorCode_ASrv_data_loadjson_fail = 8005,          //!< 终端上传的json,加载到物模型失败
    IVErrorCode_ASrv_data_modifytick_fail = 8006,        //!< 终端上传的json,修改物模型相关的时间戳失败
    IVErrorCode_ASrv_tocsrv_timeout = 8007,     //!< 接入服务器与中心服务器通信超时
    IVErrorCode_ASrv_url_parse_fail = 8008,     //!< url地址解析失败
    IVErrorCode_ASrv_csrv_reply_err = 8009,           //!<  中心服务器响应错误的数据
    IVErrorCode_ASrv_forward_toASrv_timeout = 8010,      //!< 接入服务器转发消息到其他接入服务器超时
    IVErrorCode_ASrv_forward_toASrv_fail = 8011,         //!< 接入服务器转发消息到其他接入服务器失败
    IVErrorCode_ASrv_forward_toTerm_timeout = 8012,      //!< 接入服务器转发消息到设备超时
    IVErrorCode_ASrv_forward_toTerm_fail = 8013,         //!< 接入服务器转发消息到设备失败
    IVErrorCode_ASrv_handle_fail = 8014,                 //!< 接入服务器转发消息到设备失败
    IVErrorCode_ASrv_dstid_parse_faild = 8015,             //!< 接入服务器没有从数据帧中解析出目标ID
    IVErrorCode_ASrv_dstid_isuser = 8016,                //!< 接入服务器发现目标ID是个用户
    IVErrorCode_ASrv_calc_leaf_fail = 8017,             //!< 接入服务器计算leaf失败
    IVErrorCode_ASrv_set_timeval_leafval_fail = 8018,             //!< 接入服务器设置物模型的timeval值失败
    IVErrorCode_ASrv_calc_forward_json_fail = 8019,      //!< 接入服务器计算转发json失败
    IVErrorCode_ASrv_tmpsubs_parse_fail = 8020,         //!< 临时订阅帧没有解析出设备ID
    IVErrorCode_ASrv_csrvctrl_trgtype_error = 8021,     //!< 中心服务器发来的ctl帧，trgtype不对
    IVErrorCode_ASrv_binderror_dev_usr_has_bind = 8022,           //!< 这对设备和用户已经绑定
    IVErrorCode_ASrv_binderror_dev_has_bind_other = 8023,         //!< 设备已经绑定其他用户
    IVErrorCode_ASrv_binderror_customer_diffrent = 8024,       //!<不同客户
    IVErrorCode_ASrv_unformat_jsstr_fail = 8025,           //!<JS字符串错误
    IVErrorCode_ASrv_netcfg_maketoken_fail = 8026,       //!< 配网时生成token失败
    IVErrorCode_ASrv_netcfg_verifytoken_fail = 8027,       //!< 配网时校验token失败
    IVErrorCode_ASrv_parse_json_fail = 8028,               //!<json错误

    //!< 终端使用
    IVErrorCode_Term_msg_send_peer_timeout = 20001,            //!< 消息发送给对方超时
    //calling相关
    IVErrorCode_Term_msg_calling_hangup = 20002,            //!< 普通挂断消息
    IVErrorCode_Term_msg_calling_send_timeout = 20003,        //!< calling消息发送超时
    IVErrorCode_Term_msg_calling_no_srv_addr = 20004,        //!< 服务器未分配转发地址
    IVErrorCode_Term_msg_calling_handshake_timeout = 20005,//!< 握手超时
    IVErrorCode_Term_msg_calling_token_error = 20006,        //!< 设备端token校验失败
    IVErrorCode_Term_msg_calling_all_chn_busy = 20007,        //!< 监控通道数满
    IVErrorCode_Term_msg_calling_timeout_disconnect = 20008,//!< 超时断开
    IVErrorCode_Term_msg_calling_no_find_dst_id = 20009,    //!< 未找到目的id
    IVErrorCode_Term_msg_calling_check_token_error = 20010, //!< token校验出错

    //物模型CO
    IVErrorCode_Term_msg_gdm_handle_processing = 20100,        //!< 设备正在处理中
    IVErrorCode_Term_msg_gdm_handle_leaf_path_error = 20101,//!< 设备端校验叶子路径非法
    IVErrorCode_Term_msg_gdm_handle_parse_json_fail = 20102, //!< 设备端解析JSON出错
    IVErrorCode_Term_msg_gdm_handle_fail = 20103,            //!< 设备处理ACtion失败
    IVErrorCode_Term_msg_gdm_handle_no_cb_registered = 20104,//!< 设备未注册相应的ACtion回调函数
    IVErrorCode_Term_msg_gdm_handle_buildin_prowritable_error = 20105,//!< 设备不允许通过局域网修改内置可写对象
};


extern NSString *IVErrorDescribe(int64_t errorCode);

#endif /* IVError_h */
