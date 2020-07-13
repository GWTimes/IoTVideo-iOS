//
//  UIControl.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/4/30.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit

extension UIControl {
    private class Target: NSObject {
        let event: Event
        let action: (UIControl) -> Void
        let key: UnsafeRawPointer
        
        init(event: Event, action: @escaping (UIControl) -> Void) {
            self.event = event
            self.action = action
            self.key = UnsafeRawPointer(bitPattern: event.rawValue)!
            super.init()
        }
        
        @objc func actionForEvent(_ obj: UIControl) {
            action(obj)
        }
        
    }
    
    private var actionForEventKey: UnsafeRawPointer { return UnsafeRawPointer(bitPattern: "actionForEvent".hashValue)! }
    
    @objc func addEvent(_ event: Event = .touchUpInside, action: @escaping (UIControl) -> Void) {
        let target = Target(event: event, action: action)
        objc_setAssociatedObject(self, target.key, target, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        addTarget(target, action: #selector(target.actionForEvent(_:)), for: event)
    }
}
