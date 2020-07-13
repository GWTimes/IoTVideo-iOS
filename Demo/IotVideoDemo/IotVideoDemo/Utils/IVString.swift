//
//  IVString.swift
//  Yoosee
//
//  Created by JonorZhang on 2020/6/22.
//  Copyright © 2020 Gwell. All rights reserved.
//

import Foundation
import UIKit.UIFont

// MAKR: - 字符串下标访问
extension String {
    
    subscript(idx: Int) -> Character {
        return self[self.index(startIndex, offsetBy: idx)]
    }
    
    subscript(idx: PartialRangeUpTo<Int>) -> String {
        let substr = self[..<index(startIndex, offsetBy: idx.upperBound)]
        return String(substr)
    }
    
    subscript(idx: PartialRangeThrough<Int>) -> String {
        let substr = self[...index(startIndex, offsetBy: idx.upperBound)]
        return String(substr)
    }
    
    subscript(idx: PartialRangeFrom<Int>) -> String {
        let substr = self[index(startIndex, offsetBy: idx.lowerBound)...]
        return String(substr)
    }
    
    subscript(idx: Range<Int>) -> String {
        let lower = index(startIndex, offsetBy: idx.lowerBound)
        let upper = index(startIndex, offsetBy: idx.upperBound)
        let substr = self[lower..<upper]
        return String(substr)
    }
    
    subscript(idx: ClosedRange<Int>) -> String {
        let lower = index(startIndex, offsetBy: idx.lowerBound)
        let upper = index(startIndex, offsetBy: idx.upperBound)
        let substr = self[lower...upper]
        return String(substr)
    }
}


// MARK: - 文本宽高计算
extension String {
    
    func heightWithFont(_ font: UIFont) -> CGFloat {
        return sizeWithFont(font).height
    }
    
    func widthWithFont(_ font: UIFont) -> CGFloat {
        return sizeWithFont(font).width
    }
    
    func sizeWithFont(_ font: UIFont) -> CGSize {
        let text = self as NSString
        return text.boundingRect(with: .zero, options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil).size
    }
}

// MARK: - 便利计算属性
extension String {
    
    var fullRange: NSRange {
        return NSRange(location: 0, length: count)
    }
}
