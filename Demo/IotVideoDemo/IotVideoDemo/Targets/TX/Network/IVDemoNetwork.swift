//
//  IVDemoNetwork.swift
//  IotVideoDemoTX
//
//  Created by ZhaoYong on 2020/3/16.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation
import IoTVideo.IVNetConfig
import SwiftyJSON

public typealias IVDemoNetworkResponseHandler = ((_ data: Any?, _ error: Error?) -> Void)?

struct IVDemoNetwork {
    
    /// 绑定设备
    /// - Parameters:
    ///   - deviceId: 设备id
    ///   - forceBind: 默认true 是否踢掉之前的主人，true：踢掉；false：不踢掉。当role为owner时，可以不填
    ///   - responseHandler: 回调
    static func addDevice(_ deviceId: String, forceBind: Bool = true, responseHandler: IVDemoNetworkResponseHandler) {
        let accessId = UserDefaults.standard.string(forKey: demo_accessId)!
        IVTencentNetwork.shared.addDevice(accessId: accessId, deviceId: deviceId, role: .owner, forceBind: forceBind){ (json, error) in
            guard let json = IVDemoNetwork.handlerError(json, error) else {
                responseHandler?(nil, error)
                return
            }
            
            //订阅设备 --- 绑定设备后，让IoTVideo快速加入此设备
            let succ = IVNetConfig.subscribeDevice(withToken: json["Response"]["AccessToken"].stringValue, deviceId: deviceId)
            logDebug("subscribeDevice: ", succ)
            
            responseHandler?(true, nil)
        }
    }
    
    
    /// 解绑设备
    /// - Parameters:
    ///   - deviceId: 设备id
    ///   - role: 用户角色
    ///   - responseHandler: 回调
    static func deleteDevice(_ deviceId: String, role: IVRole, responseHandler: IVDemoNetworkResponseHandler) {
        let accessId = UserDefaults.standard.string(forKey: demo_accessId)!
        IVTencentNetwork.shared.deleteDevice(deviceId: deviceId, accessId: accessId, role: role) { (json, error) in
            guard let _ = IVDemoNetwork.handlerError(json, error) else {
                responseHandler?(nil, error)
                return
            }
            responseHandler?(true, error)
        }
    }
    
    /// 获取设备列表
    /// - Parameter responseHandler: 回调
    static func deviceList(responseHandler: IVDemoNetworkResponseHandler) {
        IVTencentNetwork.shared.deviceList { (json, err) in
            guard let json = IVDemoNetwork.handlerError(json, err) else {
                responseHandler?(nil, err)
                return
            }
            
            var newUserDeviceList: [IVDeviceModel] = []
            if let data = json["Response"]["Data"].array {
                for device in data {
                    let deviceModel = IVDeviceModel(devId: device["Tid"].stringValue,
                                                    deviceName: device["DeviceName"].stringValue,
                                                    shareType: IVDeviceShareType(rawValue: device["Role"].stringValue) ?? .owner)
                    newUserDeviceList.append(deviceModel)
                    
                    IVMessageMgr.sharedInstance.readProperty(ofDevice: deviceModel.devId!, path: "ProReadonly._online") { (json, error) in
                        guard let json = json else { return }
                        deviceModel.online = JSON(parseJSON: json).value("stVal")?.boolValue
                    }
                }
            }
            responseHandler?(newUserDeviceList, nil)
        }
    }
    
    /// 获取分享者列表
    ///
    /// 仅主人可用
    /// - Parameters:
    ///   - deviceId: 设备id
    ///   - responseHandler: 回调
    static func getVisitorList(of deviceId: String, responseHandler: IVDemoNetworkResponseHandler) {
        IVTencentNetwork.shared.getVisitorList(deviceId: deviceId){ (json, err) in
            guard let json = IVDemoNetwork.handlerError(json, err) else {
                responseHandler?(nil, err)
                return
            }
            let data = json["Response"]["Data"]
                .arrayValue
                .filter{$0["Role"].stringValue == IVRole.guest.rawValue}
                .map{$0["AccessId"].stringValue}
            responseHandler?(data, nil)
        }
    }
    
    
    
    /// 分享设备
    /// - Parameters:
    ///   - deviceId: 设备id
    ///   - accessId: 接受者的accessid
    ///   - responseHandler: 回调
    /// 此接口尽量由分享者自己去调用，然后订阅设备（即主人根据分享者账号，分享，分享者同意分享操作后调用此接口）
    /// demo内为设备主人调用然后分享者重新登录完成分享操作
    static func shareDevice(_ deviceId: String, to accessId: String, responseHandler: IVDemoNetworkResponseHandler) {
        IVTencentNetwork.shared.addDevice(accessId: accessId, deviceId: deviceId, role: .guest, forceBind: false){ (json, error) in
            guard let _ = IVDemoNetwork.handlerError(json, error) else {
                responseHandler?(nil, error)
                return
            }
            //这里没有调用订阅，是因为订阅需要分享者自己去调用
            responseHandler?(true, nil)
        }
    }
    
    /// 取消分享
    /// - Parameters:
    ///   - deviceId: 设备id
    ///   - accessId: 用户id
    ///   - role: accessId的用户角色
    ///   - responseHandler: 回调
    static func cancelSharing(_ deviceId: String, accessId: String, role: IVRole, responseHandler: IVDemoNetworkResponseHandler) {
        IVTencentNetwork.shared.deleteDevice(deviceId: deviceId, accessId: accessId, role: role) { (json, error) in
            guard let _ = IVDemoNetwork.handlerError(json, error) else {
                responseHandler?(nil, error)
                return
            }
            responseHandler?(true, error)
        }
    }
    
    static func buyCloudStoragePackage(_ packageID: String, deviceId: String, responseHandler: IVDemoNetworkResponseHandler) {
        IVTencentNetwork.shared.buyCloudStoragePackage(packageID: packageID, deviceId: deviceId) { (json, error) in
            guard let _ = IVDemoNetwork.handlerError(json, error) else {
                responseHandler?(nil, error)
                return
            }
            responseHandler?(true, error)
        }
    }
}

extension IVDemoNetwork {
    
    static func handlerError(_ json: String?,_ error: Error?) -> JSON? {
        
        if let error = error {
            showError(error)
            return nil
        }
        
        let json = JSON(parseJSON: json!)
        if let errorCode = json["Response"]["Error"]["Code"].string {
            let errMsg = "\(errorCode) : \(json["Response"]["Error"]["Message"].stringValue)"
            print(errMsg)
            ivHud(errMsg)
            return nil
        }
        return json
    }
}


