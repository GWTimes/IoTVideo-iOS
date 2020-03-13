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
        let accessId = UserDefaults.standard.value(forKey: demo_accessIdKey)!
        self.request(methodType: .POST,
                     action: "DescribeBindDev",
                     params: ["AccessId": accessId],
                     response: responseHandler)
    }
    
    //绑定设备
    //role: .owner 主人绑定设备
    //role: .guest 绑定别人分享的设备
    //forceBid: 默认true 是否踢掉之前的主人，true：踢掉；false：不踢掉。当role为owner时，可以不填
    func addDevice(deviceId: String, role: IVRole, forceBind: Bool = true, responseHandler: IVTencentNetworkResponseHandler) {
        let accessId = UserDefaults.standard.value(forKey: demo_accessIdKey)!
        self.request(methodType: .POST,
                     action: "CreateBinding",
                     params: ["AccessId": accessId,
                              "Tid": deviceId,
                              "Role": role.rawValue,
                              "ForceBind": forceBind],
                     response: responseHandler)
    }
    
    //解绑
    func deleteDevice(deviceId: String, role: IVRole, responseHandler: IVTencentNetworkResponseHandler) {
        let accessId = UserDefaults.standard.value(forKey: demo_accessIdKey)!
        self.request(methodType: .POST,
                     action: "DeleteBinding",
                     params: ["AccessId": accessId,
                              "Tid": deviceId,
                              "Role": role.rawValue],
                     response: responseHandler)
    }
}


//绑定设备
//role: .owner 主人绑定设备
//role: .guest 绑定别人分享的设备
//forceBid: 默认true 是否踢掉之前的主人，true：踢掉；false：不踢掉。当role为owner时，可以不填
func addDevice(deviceId: String, role: IVRole, forceBind: Bool = true, responseHandler: IVTencentNetworkResponseHandler) {
    IVTencentNetwork.shared.addDevice(deviceId: deviceId, role: role, forceBind: forceBind){ (json, error) in
        if let json = json  {
            let newJson = JSON(parseJSON: json)
            //订阅设备 --- 绑定设备后，让IoTVideo快速加入此设备
            let succ = IVNetConfig.subscribeDevice(withToken: newJson["Response"]["AccessToken"].stringValue)
            logDebug("subscribeDevice: ", succ)
        }
        
        responseHandler?(json, error)
    }
}
