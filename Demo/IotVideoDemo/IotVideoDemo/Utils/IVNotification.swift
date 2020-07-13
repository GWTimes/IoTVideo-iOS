//
//  IVNotification.swift
//  IotVideoDemoDev
//
//  Created by zhaoyong on 2020/4/26.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation

//MARK: Notification 扩展
extension Notification {
    /// 设备在线状态变化
    /// - Parameter online: 在线状态
    static func deviceOnline(_ online: Bool) -> Self {
        return Notification(name: .ivDeviceOnline, object: nil, userInfo: [IVNotiBody: online])
    }
    
    /// 设备列表变化
    /// - Parameter reason: 变化原因
    static func deviceListChange(by reason: IVDeviceListChangeReason) -> Self {
        return Notification(name: .ivDeviceListChange, object: nil, userInfo: [IVNotiBody: reason])
    }
    
    /// 收到服务器推送事件
    /// - Parameter event: 事件
    static func receiveEvent(_ event: IVReceiveEvent) -> Self {
        return Notification(name: .iVMessageDidReceiveEvent, object: nil, userInfo: [IVNotiBody: event])
    }
    
    /// 收到服务器属性更新
    /// - Parameter property: 属性
    static func updateProperty(_ property: IVUpdateProperty) -> Self {
        return Notification(name: .iVMessageDidUpdateProperty, object: nil, userInfo: [IVNotiBody: property])
    }
    
    /// 登出
    /// - Parameter reason: 登出原因
    static func logout(by reason: IVLogoutReason) -> Self {
        return Notification(name: .ivLogout, object: nil, userInfo: [IVNotiBody: reason])
    }
}


//MARK: 通知名称
extension NSNotification.Name {
    /// 设备离线/在线
    static let ivDeviceOnline = Notification.Name("DeviceOnline")
    /// 设备列表变化
    static let ivDeviceListChange = Notification.Name("DeviceListChange")
    
    /// IVMessage 收到事件
    static let iVMessageDidReceiveEvent = Notification.Name(rawValue: "MessageDidReceiveEvent")
    /// IVMessage 收到状态更新
    static let iVMessageDidUpdateProperty = Notification.Name(rawValue: "MessageDidUpdateProperty")
    
    /// 登出
    static let ivLogout = Notification.Name(rawValue: "Logout")
}



//MARK: 简写
/// 通知中心简写 NotificationCenter.default.post
func IVNotiPost(_ notification: Notification) {
    NotificationCenter.default.post(notification)
}

/// 通知userInfo body字段名
let IVNotiBody = "IVNotiBody"



//MARK: 相关枚举
/// 设备列表变化原因
enum IVDeviceListChangeReason {
    case reload
    case add
    case delete
}

/// 退出登录原因枚举
enum IVLogoutReason {
    /// 用户退出
    case user
    /// 登录过期
    case expired
    /// 被踢飞
    case kickOff
}

//MARK: 通知结构体
/// 服务器推送事件
struct IVReceiveEvent {
    var event: String
    var topic: String
}

/// 服务器推送属性更新
struct IVUpdateProperty {
    var deviceId: String
    var path: String
    var json: String
}
