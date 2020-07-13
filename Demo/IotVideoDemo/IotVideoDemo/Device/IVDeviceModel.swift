//
//  IVDevice.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/12/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo

// 来自设备
class IVDevice: NSObject {
    var deviceID: String = ""
    var productID: String = ""
    var deviceName: String = ""
    var serialNumber: String = ""
    var version: String = ""
    var macAddr: String = ""
    var shareType: IVRole = .owner
    var online: Bool = false
    var ipAddr: String = ""
    var sourceNum: Int = 1 // 源个数
    
    init(_ device: IVDeviceModel) {
        self.deviceID = device.devId ?? ""
        self.productID = ""
        self.deviceName = device.deviceName ?? ""
        self.serialNumber = ""
        self.version = ""
        self.macAddr = ""
        self.shareType = device.shareType
        self.online = device.online ?? false
        self.ipAddr = ""
    }

    init(_ device: IVLANDevice) {
        self.deviceID = device.deviceID
        self.productID = device.productID
        self.deviceName = device.deviceID
        self.serialNumber = device.serialNumber
        self.version = device.version
        self.macAddr = device.macAddr
        self.shareType = .owner
        self.online = true
        self.ipAddr = device.ipAddr
    }
}

// 来自服务器
class IVDeviceModel: Codable {
    var deviceMode: String?
    var shareType: IVRole = .owner
    var devId: String?
    var url: String?
    var deviceName: String?
    var deviceType: String?
    
    var online: Bool? = false {
        didSet {
            logInfo("Device: \(devId ?? "???") Online:\(online ?? false)")
            IVNotiPost(.deviceOnline(online ?? false))
        }
    }
    
    init(devId: String!,deviceName: String!, shareType: IVRole) {
        self.devId = devId
        self.deviceMode = ""
        self.shareType = shareType
        self.url = ""
        self.deviceName = deviceName
        self.deviceType = ""
        self.online = false
    }
    
    init(_ device: IVDevice) {
        self.devId = device.deviceID
        self.deviceMode = ""
        self.shareType = .owner
        self.url = ""
        self.deviceName = device.deviceName
        self.deviceType = ""
        self.online = false
    }
    
    convenience init(_ device: IVLANDevice) {
        self.init(IVDevice(device))
    }
}


var userDeviceList: [IVDevice] = []

//用户角色
enum IVRole: String, Codable {
    case owner
    case guest
}



@objc protocol IVDeviceAccessable where Self: UIViewController {
    var device: IVDevice! { get set }
}


struct PlayListData: Codable {
    var palyList = [IVCSPlaybackItem]()
}

struct IVCSPlaybackItem: Codable {
    var starttime: Int = 0
    var endtime: Int = 0
    var m3u8Url: String?
}

struct IVCSMarkItem: Codable {
    var dateTime: Int = 0
    var playable: Bool = false
}

class IVDeviceAccessableTVC : UITableViewController, IVDeviceAccessable {
     @objc var device: IVDevice!
//    var deviceList: [IVDevice] {
//        let userDevs = userDeviceList.map { IVDevice($0) }
//        return userDevs.isEmpty ? [IVDevice(device)] : userDevs
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dstVC = segue.destination as? IVDeviceAccessable {
            dstVC.device = device
        }
    }
}

class IVDeviceAccessableVC : UIViewController, IVDeviceAccessable {
     @objc var device: IVDevice!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dstVC = segue.destination as? IVDeviceAccessable {
            dstVC.device = device
        }
    }
}

