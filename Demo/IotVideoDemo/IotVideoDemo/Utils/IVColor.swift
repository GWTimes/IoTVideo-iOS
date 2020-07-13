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
}
