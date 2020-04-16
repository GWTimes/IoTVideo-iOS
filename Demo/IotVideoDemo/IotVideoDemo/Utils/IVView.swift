//
//  IVView.swift
//  IotVideoDemoDev
//
//  Created by JonorZhang on 2020/4/14.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit

// MAKR: -
extension UIView {
    @objc var nextViewController: UIViewController? {
        var responder = next
        while responder != nil {
            if let vc = responder as? UIViewController { return vc }
            responder = responder?.next
        }
        return nil
    }

    /// 视图本身是否可见
    var isVisible: Bool {
        if isHidden { return false }
        if !isOpaque  { return false }
        if alpha <= 0.01 { return false }
        if bounds.size.width == 0 || bounds.size.height == 0 { return false }
        return true
    }

    /// 视图作为容器是否可见（并且子控件可见）
    var isVisibleAsContainer: Bool {
        if !isVisible { return false }
        if subviews.count == 0 { return false }
        if subviews.filter({ !$0.isVisible }).count == 0 { return false }
        return true
    }
    
    func getAllSubviews() -> [UIView] {
        return subviews.flatMap { subView -> [UIView] in
            var result = subView.getAllSubviews()
            result.append(subView)
            return result
        }
    }
    
    func getAllSubviews<T: UIView>(of type: T.Type) -> [T] {
        return getAllSubviews().compactMap({ $0 as? T })
    }
}

extension UIView {
    @objc enum Gesture: Int {
        case longPress
        case tap
        case pin
        
        var actionForGestureKey: UnsafeRawPointer {
            switch self {
            case .longPress:
                return UnsafeRawPointer(bitPattern: "actionForLongPress".hashValue)!
            case .tap:
                return UnsafeRawPointer(bitPattern: "actionForTap".hashValue)!
            case .pin:
                return UnsafeRawPointer(bitPattern: "actionForPin".hashValue)!
            }
        }
    }
    
    @objc func addGesture(_ gesture: Gesture, action: ((UIGestureRecognizer)->())?) -> UIGestureRecognizer {
        isUserInteractionEnabled = true
        objc_setAssociatedObject(self, gesture.actionForGestureKey, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        switch gesture {
        case .longPress:
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandler(gesture:)))
            longPress.minimumPressDuration = 1
            addGestureRecognizer(longPress)
            return longPress
        case .tap:
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapHandler(gesture:)))
            addGestureRecognizer(tap)
             return tap
        case .pin:
            let pin = UIPinchGestureRecognizer(target: self, action: #selector(pinHandler(gesture:)))
            addGestureRecognizer(pin)
            return pin
            
        }
    }
    
    @objc private func longPressHandler(gesture: UILongPressGestureRecognizer) {
        if let action = objc_getAssociatedObject(self, Gesture.longPress.actionForGestureKey) as? ((UIGestureRecognizer)->()) {
            action(gesture)
        }
    }
    
    @objc private func tapHandler(gesture: UITapGestureRecognizer) {
        if let action = objc_getAssociatedObject(self, Gesture.tap.actionForGestureKey) as? ((UIGestureRecognizer)->()) {
            action(gesture)
        }
    }
    @objc private func pinHandler(gesture: UIPinchGestureRecognizer) {
        if let action = objc_getAssociatedObject(self, Gesture.pin.actionForGestureKey) as? ((UIGestureRecognizer)->()) {
            action(gesture)
        }
    }
}
