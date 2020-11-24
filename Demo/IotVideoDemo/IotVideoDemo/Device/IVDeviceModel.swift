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
    var sdkVer: String = ""
    var macAddr: String = ""
    var shareType: IVRole = .owner
    var online: Int = 0 // 0 offline, 1 online, 2 sleep
    var ipAddr: String = ""
    var sourceNum: Int = 1 // 源个数
    var avconfig: String = "" // -ar:[8000|16000|xx] -aenc:[aac|amr] -vr:[16|20|xx]

    init(_ device: IVDeviceModel) {
        self.deviceID = device.devId ?? ""
        self.productID = ""
        self.deviceName = device.deviceName ?? ""
        self.serialNumber = ""
        self.version = ""
        self.macAddr = ""
        self.shareType = device.shareType
        self.online = device.online ?? 0
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
        self.online = 1
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
    
    var online: Int? = 0 {
        didSet {
            logInfo("Device: \(devId ?? "???") Online:\(online ?? 0)")
            IVNotiPost(.deviceOnline(online ?? 0))
        }
    }
    
    init(devId: String!,deviceName: String!, shareType: IVRole) {
        self.devId = devId
        self.deviceMode = ""
        self.shareType = shareType
        self.url = ""
        self.deviceName = deviceName
        self.deviceType = ""
        self.online = 0
    }
    
    init(_ device: IVDevice) {
        self.devId = device.deviceID
        self.deviceMode = ""
        self.shareType = .owner
        self.url = ""
        self.deviceName = device.deviceName
        self.deviceType = ""
        self.online = 0
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


struct IVCSPlayListInfo: Codable {
    var list: [IVCSPlaybackItem]?
}

class IVCSPlaybackItem: Codable {
    var start: Int = 0
    var end: Int = 0
    var url: URL? = nil
    
    init(start: Int, end: Int) {
        self.start = start
        self.end = end
    }
}

struct IVCSMarkItems: Codable {
    var list: [IVCSMarkItem] = []
}

typealias IVCSMarkItem = Int

//struct IVCSMarkItem: Codable {
//    var dateTime: Int = 0
//}

struct IVCSPlayInfo: Codable {
    var startTime: Int = 0
    var endTime: Int = 0
    var url: String?
    // 播放结束标记， 表示此次播放是否把需要播放的文件播完，没有则需以返回的 endtime 为基准再次请求。false 表示未播放完，true 表示播放完成
    var endflag: Bool = true
}

struct IVCSEventsInfo: Codable {
    var imgUrlPrefix: String? // 图片及缩略图下载地址前缀
    var list: [IVCSEvent]?
}

struct IVCSEvent: Codable {
    var alarmId: String    // 事件id
    var firstAlarmType: Int // 告警触发时的告警类型
    var alarmType: Int // 告警有效时间内触发过的告警类型
    var startTime: Int
    var endTime: Int
    var imgUrlSuffix: String? // 告警图片下载地址后缀
    var thumbUrlSuffix: String? // 告警图片下载地址后缀
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

