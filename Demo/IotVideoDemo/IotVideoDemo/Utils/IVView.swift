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
    /// 第一视图控制器
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
    
    /// 递归获取所有子视图
    /// - Parameters:
    ///   - depth: 递归深度[0, .max]
    /// - Returns: 获取结果
    private func recursiveSubviews(depth: UInt = 20) -> [UIView] {
        if subviews.count > 0, depth > 0 {
        return subviews.flatMap { subView -> [UIView] in
                var result = subView.recursiveSubviews(depth: depth - 1)
            result.append(subView)
            return result
        }
        } else {
            return subviews
        }
    }
    
    /// 递归获取所有指定类型的子视图
    /// - Parameters:
    ///   - type: 子视图类型
    ///   - depth: 递归深度[0, .max]
    /// - Returns: 获取结果
    func recursiveSubviews<T: UIView>(of type: T.Type, depth: UInt = 20) -> [T] {
        return recursiveSubviews(depth: depth).compactMap({ $0 as? T })
    }
}

extension UIView {
    
    @discardableResult
    @objc func addTapGesture(numberOfTapsRequired: Int = 1, numberOfTouchesRequired: Int = 1, _ action: @escaping (UIGestureRecognizer) -> Void) -> UITapGestureRecognizer {
        let tap = UITapGestureRecognizer(target: self, action: #selector(gestureRecognizerHandler(gesture:)))
        tap.numberOfTapsRequired = numberOfTapsRequired
        tap.numberOfTouchesRequired = numberOfTouchesRequired
        addGesture(tap, action: action)
        return tap
    }
    
    @discardableResult
    @objc func addLongPressGesture(numberOfTapsRequired: Int = 0, numberOfTouchesRequired: Int = 1, minimumPressDuration: TimeInterval = 0.5, allowableMovement: CGFloat = 10, _ action: @escaping (UIGestureRecognizer) -> Void) -> UILongPressGestureRecognizer {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(gestureRecognizerHandler(gesture:)))
        longPress.numberOfTapsRequired = numberOfTapsRequired
        longPress.numberOfTouchesRequired = numberOfTouchesRequired
        longPress.minimumPressDuration = minimumPressDuration
        longPress.allowableMovement = allowableMovement
        addGesture(longPress, action: action)
        return longPress
    }

    @discardableResult
    @objc func addPinchGesture(_ action: @escaping (UIGestureRecognizer) -> Void) -> UIPinchGestureRecognizer {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(gestureRecognizerHandler(gesture:)))
        addGesture(pinch, action: action)
        return pinch
    }

    @discardableResult
    @objc func addPanGesture(minimumNumberOfTouches: Int = 1, maximumNumberOfTouches: Int = .max, _ action: @escaping (UIGestureRecognizer) -> Void) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(gestureRecognizerHandler(gesture:)))
        pan.minimumNumberOfTouches = minimumNumberOfTouches
        pan.maximumNumberOfTouches = maximumNumberOfTouches
        addGesture(pan, action: action)
        return pan
    }

    @discardableResult
    @objc func addSwipeGesture(numberOfTouchesRequired: Int = 1, direction: UISwipeGestureRecognizer.Direction = .right, _ action: @escaping (UIGestureRecognizer) -> Void) -> UISwipeGestureRecognizer {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(gestureRecognizerHandler(gesture:)))
        swipe.numberOfTouchesRequired = numberOfTouchesRequired
        swipe.direction = direction
        addGesture(swipe, action: action)
        return swipe
    }

    @discardableResult
    @objc func addRotationGesture(_ action: @escaping (UIGestureRecognizer) -> Void) -> UIRotationGestureRecognizer {
        let rota = UIRotationGestureRecognizer(target: self, action: #selector(gestureRecognizerHandler(gesture:)))
        addGesture(rota, action: action)
        return rota
    }

    @discardableResult
    @objc func addScreenEdgePanGesture(_ action: @escaping (UIGestureRecognizer) -> Void) -> UIScreenEdgePanGestureRecognizer {
        let screenEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(gestureRecognizerHandler(gesture:)))
        addGesture(screenEdgePan, action: action)
        return screenEdgePan
    }

    private func addGesture(_ gesture: UIGestureRecognizer, action: @escaping (UIGestureRecognizer) -> Void){
        let key = UnsafeRawPointer(Unmanaged.passUnretained(gesture).toOpaque())
        objc_setAssociatedObject(self, key, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        isUserInteractionEnabled = true
        addGestureRecognizer(gesture)
    }

    @objc private func gestureRecognizerHandler(gesture: UIGestureRecognizer) {
        let key = UnsafeRawPointer(Unmanaged.passUnretained(gesture).toOpaque())
        if let action = objc_getAssociatedObject(self, key) as? ((UIGestureRecognizer)->()) {
            action(gesture)
        }
    }
}

extension UIView {
    func addBlurEffect(style: UIBlurEffect.Style = .dark, alpha: CGFloat = 1.0) {
        let blurEffect = UIBlurEffect(style: style)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.alpha = alpha
        visualEffectView.frame = bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(visualEffectView, at: 0)
    }
    
//    //创建高斯模糊效果的背景
//    func addBlurBackground (image: UIImage, view: UIView, blurRadius: Float) {
//        //处理原始NSData数据
//        let originImage = CIImage(cgImage: image.cgImage! )
//        //创建高斯模糊滤镜
//        let filter = CIFilter(name: "CIGaussianBlur")
//        filter?.setValue(originImage, forKey: kCIInputImageKey)
//        filter?.setValue(NSNumber(value: blurRadius), forKey: "inputRadius")
//        //生成模糊图片
//        let context = CIContext(options: nil)
//        let result:CIImage = filter?.value(forKey: kCIOutputImageKey) as! CIImage
//        let blurImage = UIImage(cgImage: context.createCGImage(result, from: result.extent)!)
//        //将模糊图片加入背景
//        let w = frame.width
//        let h = frame.height
//        let blurImageView = UIImageView(frame: CGRect(x: -w/2, y: -h/2, width: 2*w, height: 2*h)) //模糊背景是界面的4倍大小
//        blurImageView.contentMode = .scaleAspectFill
//        blurImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        blurImageView.image = blurImage
//        insertSubview(blurImageView, belowSubview: view)
//    }
}

extension UIStackView {
    
    open override var backgroundColor: UIColor? {
        didSet {
            setBackground(color: backgroundColor)
        }
    }
    
    func setBackground(color: UIColor?, cornerRadius: CGFloat = 0.0) {
        let bgv = subviews.first(where: { $0.tag == 65889 }) ?? UIView(frame: bounds)
        bgv.tag = 65889
        bgv.backgroundColor = color
        bgv.layer.cornerRadius = cornerRadius
        bgv.layer.masksToBounds = true
        bgv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(bgv, at: 0)
    }
}

