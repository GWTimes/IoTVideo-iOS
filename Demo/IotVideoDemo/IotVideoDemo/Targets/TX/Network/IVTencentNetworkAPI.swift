//
//  IVTencentNetworkAPI.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2020/3/11.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation
import IoTVideo
import SwiftyJSON

//具体API请求
extension IVTencentNetwork {
    //注册
    func register(tmpSecretID: String, tmpSecretKey: String, token: String, userName: String, responseHandler: IVTencentNetworkResponseHandler) {
        IVTencentNetwork.shared.secretKey = tmpSecretKey
        IVTencentNetwork.shared.secretId = tmpSecretID
        
        UserDefaults.standard.do {
            $0.setValue(tmpSecretID, forKey: demo_secretId)
            $0.setValue(tmpSecretKey, forKey: demo_secretKey)
            $0.setValue(token, forKey: demo_loginToken)
        }
        
        IVTencentNetwork.shared.token = token
        self.request(methodType: .POST,
                     action: "CreateAppUsr",
                     params: ["CunionId": userName],
                     response: responseHandler)
    }
    
    //登录
    func login(accessId: String, responseHandler:IVTencentNetworkResponseHandler) {
        self.request(methodType: .POST,
                     action: "CreateUsrToken",
                     params: ["AccessId": accessId,
                              "UniqueId": IVTencentNetwork.shared.getUniqueId(),
                              "TtlMinutes": 43200],
                     response: responseHandler)
    }
    
    //获取设备列表
    func deviceList(responseHandler: IVTencentNetworkResponseHandler) {
        let accessId = UserDefaults.standard.string(forKey: demo_accessId)!
        self.request(methodType: .POST,
                     action: "DescribeBindDev",
                     params: ["AccessId": accessId],
                     response: responseHandler)
    }
    
    //绑定设备
    //role: .owner 主人绑定设备
    //role: .guest 绑定别人分享的设备
    //forceBid: 默认true 是否踢掉之前的主人，true：踢掉；false：不踢掉。当role为owner时，可以不填
    func addDevice(accessId: String, deviceId: String, role: IVRole, forceBind: Bool = true, responseHandler: IVTencentNetworkResponseHandler) {
        self.request(methodType: .POST,
                     action: "CreateBinding",
                     params: ["AccessId": accessId,
                              "Tid": deviceId,
                              "Role": role.rawValue,
                              "ForceBind": forceBind],
                     response: responseHandler)
    }
    
    //解绑
    func deleteDevice(deviceId: String, accessId: String, role: IVRole, responseHandler: IVTencentNetworkResponseHandler) {
        self.request(methodType: .POST,
                     action: "DeleteBinding",
                     params: ["AccessId": accessId,
                              "Tid": deviceId,
                              "Role": role.rawValue],
                     response: responseHandler)
    }
    
    //主人获取设备的分享者列表
    func getVisitorList(deviceId: String, responseHandler: IVTencentNetworkResponseHandler) {
        let accessId = UserDefaults.standard.string(forKey: demo_accessId)!
        self.request(methodType: .POST,
                     action: "DescribeBindUsr",
                     params: ["AccessId": accessId, "Tid": deviceId],
                     response: responseHandler)
    }
    
    /// 临时访问
    /// 终端用户与设备没有强绑定关联关系; 允许终端用户短时或一次性临时访问设备; 当终端用户与设备有强绑定关系时，可以不用调用此接口
    /// - Parameters:
    ///   - deviceIds: 设备id数组 0 < count <= 100
    ///   - TTL: 授权分钟数
    ///   - responseHandler: 回调
    func temporaryVisit(deviceIds: [String], TTL: Int, responseHandler: IVTencentNetworkResponseHandler) {
        let accessId = UserDefaults.standard.value(forKey: demo_accessId)!
        self.request(methodType: .POST,
                     action: "CreateDevToken",
                     params: ["AccessId": accessId,
                              "Tids.N": deviceIds,
                              "TtlMinutes": TTL],
                     response: responseHandler)
    }
    
    
    func buyCloudStoragePackage(packageID: String, deviceId: String, responseHandler: IVTencentNetworkResponseHandler) {
        let accessId = UserDefaults.standard.string(forKey: demo_accessId)!
        self.request(methodType: .POST,
                     action: "CreateStorage",
                     params: ["PkgId": packageID,
                              "Tid": deviceId,
                              "UserTag": accessId],
                     response: responseHandler)
    }
}

