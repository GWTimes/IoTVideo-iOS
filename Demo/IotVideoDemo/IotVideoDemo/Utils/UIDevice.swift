//
//  UIDevice.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/9/27.
//  Copyright © 2018年 Tencentcs. All rights reserved.
//

import UIKit

extension UIDevice {
    /// 强制旋转屏幕方向
    @objc static func setOrientation(_ orientation: UIDeviceOrientation) {
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    /// 是否酷酷的刘海屏系列
    @objc static var isIPhoneXSeries: Bool {
        if #available(iOS 11.0, *) {
            return (UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0) > 0
        }
        return false
    }
}
