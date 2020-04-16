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
struct IVDevice {
    var deviceID: String = ""
    var productID: String = ""
    var deviceName: String = ""
    var serialNumber: String = ""
    var version: String = ""
    var macAddr: String = ""
    
    init(_ device: IVDeviceModel) {
        self.deviceID = device.devId ?? ""
        self.productID = ""
        self.deviceName = device.deviceName ?? ""
        self.serialNumber = ""
        self.version = ""
        self.macAddr = ""
    }

    init(_ device: IVLANDevice) {
        self.deviceID = device.deviceID
        self.productID = device.productID
        self.deviceName = device.deviceID
        self.serialNumber = device.serialNumber
        self.version = device.version
        self.macAddr = device.macAddr
    }
}

// 来自服务器
class IVDeviceModel: Codable {
    var deviceMode: String?
    var shareType: IVDeviceShareType = .owner
    var devId: String?
    var url: String?
    var deviceName: String?
    var deviceType: String?
    
    var online: Bool? = false {
        didSet {
            logInfo("Device: \(devId ?? "???") Online:\(online ?? false)")
            NotificationCenter.default.post(name: .deviceOnline, object: self)
        }
    }
    
    init(devId: String!,deviceName: String!, shareType: IVDeviceShareType) {
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


var userDeviceList: [IVDeviceModel] = []

enum IVDeviceShareType: String, Codable {
    case owner
    case guest
}

//用户角色
enum IVRole: String {
    case owner = "owner"
    case guest = "guest"
}

extension NSNotification.Name {
    static let deviceOnline = Notification.Name("deviceOnline")
}


protocol IVDeviceAccessable where Self: UIViewController {
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


class IVDeviceAccessableTVC : UITableViewController, IVDeviceAccessable {
    var device: IVDevice!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dstVC = segue.destination as? IVDeviceAccessable {
            dstVC.device = device
        }
    }
}

class IVDeviceAccessableVC : UIViewController, IVDeviceAccessable {
    var device: IVDevice!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dstVC = segue.destination as? IVDeviceAccessable {
            dstVC.device = device
        }
    }
}
