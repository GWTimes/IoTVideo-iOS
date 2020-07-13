//
//  IVWifiTool.swift
//  IotVideoDemoDev
//
//  Created by zhaoyong on 2020/5/15.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

struct IVWifiTool {
    private static let kDemoWifiList = "iot_demo_wifi_list"
    
    static func isSameNetwork(_ IP1: String?, _ IP2: String?) -> Bool {
        guard let IP1 = IP1, let IP2 = IP2 else { return false }
        let ip1 = IP1.split(separator: ".").prefix(upTo: 3)
        let ip2 = IP2.split(separator: ".").prefix(upTo: 3)
        return ip1 == ip2
    }
    
    static var currentSSID: String? {
        guard let wifiInterfaces = CNCopySupportedInterfaces() else { return nil }
        let interfaceArr = CFBridgingRetain(wifiInterfaces) as! Array<String>
        if interfaceArr.count > 0 {
            let interfaceName = interfaceArr[0] as CFString
            let ussafeInterfaceData = CNCopyCurrentNetworkInfo(interfaceName)
            if (ussafeInterfaceData != nil) {
                let interfaceData = ussafeInterfaceData as! Dictionary<String, Any>
                return interfaceData["SSID"] as? String
            }
        }
        return nil 
    };
    
    /// 本地缓存wifi信息
    /// - Parameters:
    ///   - ssid: ssid
    ///   - password: 密码
    static func save(wifi ssid: String, _ password: String) {
        var wifiList = UserDefaults.standard.dictionary(forKey: kDemoWifiList) as?  [String: String]
        if wifiList == nil {
            wifiList = [String: String]()
        }
        wifiList![ssid] = password
        UserDefaults.standard.setValue(wifiList, forKey: kDemoWifiList)
    }
    
    /// 读取本地缓存的wifi密码
    /// - Parameter ssid: ssid
    /// - Returns: 密码
    static func read(wifi ssid: String) -> String {
        if let wifiList = UserDefaults.standard.dictionary(forKey: kDemoWifiList) as? [String: String] {
            if let pwd = wifiList[ssid] {
              return pwd
            }
        }
        return ""
    }
    
    
   static var ipAddr: String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0 else {
            return nil
        }
        guard let firstAddr = ifaddr else {
            return nil
        }
         
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            // Check for IPV4 or IPV6 interface
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                // Check interface name
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    // Convert interface address to a human readable string
                    var addr = interface.ifa_addr.pointee
                    var hostName = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr,socklen_t(interface.ifa_addr.pointee.sa_len), &hostName, socklen_t(hostName.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostName)
                }
            }
        }
         
        freeifaddrs(ifaddr)
        return address
    }
}
