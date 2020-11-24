//
//  UIColor.swift
//  IotVideoDemo
//
//  Created by WangShunXing on 2018/11/12.
//  Copyright © 2018年 Tencentcs. All rights reserved.
//

import UIKit

// MARK: - 便利构造
extension UIColor {
    convenience init(rgb: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0xFF00) >> 8) / 255.0
        let blue = CGFloat((rgb & 0xFF) >> 0) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // 随机色
    static var random: UIColor {
        let r = CGFloat(arc4random() % 256) / 255.0
        let g = CGFloat(arc4random() % 256) / 255.0
        let b = CGFloat(arc4random() % 256) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
    
    var toHexString: String {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            
            self.getRed(&r, green: &g, blue: &b, alpha: &a)
            
            return String(
                format: "%02X%02X%02X",
                Int(r * 0xff),
                Int(g * 0xff),
                Int(b * 0xff)
            )
        }

    convenience init(hexString: String) {
            let scanner = Scanner(string: hexString)
            scanner.scanLocation = 1
            
            var rgbValue: UInt64 = 0
            
            scanner.scanHexInt64(&rgbValue)
            
            let r = (rgbValue & 0xff0000) >> 16
            let g = (rgbValue & 0xff00) >> 8
            let b = rgbValue & 0xff
            
            self.init(
                red: CGFloat(r) / 0xff,
                green: CGFloat(g) / 0xff,
                blue: CGFloat(b) / 0xff, alpha: 1
            )
        }
}
