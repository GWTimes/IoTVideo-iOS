//
//  UIDeviceExt.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/9/27.
//  Copyright © 2018年 Tencentcs. All rights reserved.
//

import UIKit
import AudioToolbox

extension UIDevice {
    
    /// 是否支持3D Touch（iPhone6s 及以上，SE不支持）
    @objc static var support3DTouch: Bool {
        if #available(iOS 9.0, *) {
            return UIApplication.shared.keyWindow?.rootViewController?.traitCollection.forceTouchCapability == .available
        } else {
            return false
        }
    }
    
    /// 是否支持触感反馈（iPhone7 及以上机型）
    @objc static var supportFeedbackGenerator: Bool {
        if !isIPhone {
            return false
        }
        if #available(iOS 10.0, *) {
            return isIPhone7OrNewer
        } else {
            return false
        }
    }
    
    /// 是否酷酷的刘海屏系列
    @objc static var isIPhoneXSeries: Bool {
        if #available(iOS 11.0, *) {
            return (UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0) > 0
        }
        return false
    }
    
    /// 是否iPhone
    @objc static var isIPhone: Bool {
        return modelIdentifier.hasPrefix("iPhone")
    }
    
    /// 是否iPhone7以上
    @objc static var isIPhone7OrNewer: Bool {
        if !isIPhone {
            return false
        }
        return iPhoneModelMajorInteger >= 9
    }
    
    /// 型号主版本
    @objc static var iPhoneModelMajorInteger: Int {
        return Int(((modelIdentifier.components(separatedBy: ",").first as NSString?)?.substring(from: 6) ?? "")) ?? 0
    }
    
    /// 设备型号
    @objc static var modelIdentifier: String {
        var systemInfo = utsname()
        
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    /// 设备名称
    @objc static var modelName: String {
        switch modelIdentifier {
        case "iPod5,1":
            return "iPod Touch 5"
            
        case "iPod7,1":
            return "iPod Touch 6"
            
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":
            return "iPhone4"
            
        case "iPhone4,1":
            return "iPhone4s"
            
        case "iPhone5,1","iPhone5,2":
            return "iPhone5"
            
        case "iPhone5,3", "iPhone5,4":
            return "iPhone5c"
            
        case "iPhone6,1", "iPhone6,2":
            return "iPhone5s"
            
        case "iPhone7,2":
            return "iPhone6"
            
        case "iPhone7,1":
            return "iPhone6 Plus"
            
        case "iPhone8,1":
            return "iPhone6s"
            
        case "iPhone8,2":
            return "iPhone6s Plus"
            
        case "iPhone8,4":
            return "iPhoneSE"
            
        case "iPhone9,1", "iPhone9,3":
            return "iPhone7"
            
        case "iPhone9,2", "iPhone9,4":
            return "iPhone7 Plus"
            
        case "iPhone10,1", "iPhone10,4":
            return "iPhone8"
            
        case "iPhone10,5", "iPhone10,2":
            return "iPhone8 Plus"
            
        case "iPhone10,3", "iPhone10,6":
            return "iPhoneX"
            
        case "iPhone11,2":
            return "iPhoneXS"
            
        case "iPhone11,6":
            return "iPhoneXS MAX"
            
        case "iPhone11,8":
            return "iPhoneXR"
            
        case "iPhone12,1":
            return "iPhone11"
            
        case "iPhone12,3":
            return "iPhone11 ProMax"
            
        case "iPhone12,5":
            return "iPhone11 Pro"
            
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":
            return "iPad 2"
            
        case "iPad3,1", "iPad3,2", "iPad3,3":
            return "iPad 3"
            
        case "iPad3,4", "iPad3,5", "iPad3,6":
            return "iPad 4"
            
        case "iPad4,1", "iPad4,2", "iPad4,3":
            return "iPad Air"
            
        case "iPad5,3","iPad5,4":
            return "iPad Air 2"
            
        case "iPad2,5", "iPad2,6", "iPad2,7":
            return "iPad Mini"
            
        case "iPad4,4", "iPad4,5", "iPad4,6":
            return "iPad Mini 2"
            
        case "iPad4,7", "iPad4,8", "iPad4,9":
            return "iPad Mini 3"
            
        case "iPad5,1","iPad5,2":
            return "iPad Mini 4"
            
        case "iPad6,7","iPad6,8":
            return "iPad Pro"
            
        case "AppleTV5,3":
            return "Apple TV"
            
        case "i386","x86_64":
            return "Simulator"
            
        default:
            return modelIdentifier
        }
    }
}

extension UIDevice {
    
    /// 强制旋转屏幕方向
    @objc static func setOrientation(_ orientation: UIDeviceOrientation) {
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    /// 震动反馈
    @objc static func vibrate() {
        if supportFeedbackGenerator {
            if #available(iOS 10.0, *) {
                let feedBackGenertor = UIImpactFeedbackGenerator(style: .medium)
                feedBackGenertor.impactOccurred()
            }
        } else if support3DTouch {
            AudioServicesPlaySystemSound(SystemSoundID(1519)) //短震  3D Touch中的peek震动反馈
        } else {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) //长震 响铃震动
        }
    }
}
