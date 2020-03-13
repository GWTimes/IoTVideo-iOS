//
//  UIControl.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/4/30.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit

extension UIControl {
    private var actionForEventKey: UnsafeRawPointer { return UnsafeRawPointer(bitPattern: "actionForEvent".hashValue)! }
    
    @objc func addEvent(_ event: Event = .touchUpInside, action: ((UIControl)->())?) {
        objc_setAssociatedObject(self, actionForEventKey, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(self, action: #selector(actionForEvent(_:)), for: event)
    }
    
    @objc private func actionForEvent(_ obj: UIControl) {
        if let action = objc_getAssociatedObject(self, actionForEventKey) as? ((UIControl)->()) {
            action(obj)
        }
    }
}
