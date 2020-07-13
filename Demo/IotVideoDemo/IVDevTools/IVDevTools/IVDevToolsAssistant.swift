//
//  IVDevToolsAssistant.swift
//  IVLogger
//
//  Created by JonorZhang on 2019/12/25.
//  Copyright © 2019 JonorZhang. All rights reserved.
//

import UIKit

public class IVDevToolsAssistant: UIView {
  
    public static let shared = IVDevToolsAssistant(frame: CGRect(x: -32, y: 100, width: 64, height: 64))
    
    var isPinUp: Bool = false
    
    lazy var btn: UIButton = {
        let btn = UIButton(frame: self.bounds)
        btn.layer.cornerRadius = self.bounds.size.width / 2
        btn.backgroundColor = .blue
        return btn
    }()

    
    enum DispStyle {
        case minimize   // 最小化
        case suspend    // 悬浮
        case fullscreen // 全屏
    }
    var dispStyle = DispStyle.minimize {
        didSet {
            switch dispStyle {
            case .minimize:
                rootView = nil
            case .suspend:
                rootView = suspendVC.view
            case .fullscreen:
                rootView = developerVC.view
            }
        }
    }
    
    lazy var logo: UILabel = {
        let lb = UILabel(frame: self.bounds)
        lb.text = "🐞"
        lb.textAlignment = .center
        lb.font = .systemFont(ofSize: 50)
        return lb
    }()
    
    lazy var tapGes = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizer(_:)))
    lazy var panGes = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizer(_:)))
    lazy var longPressGes: UILongPressGestureRecognizer = {
        let lg = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognizer(_:)))
        lg.numberOfTouchesRequired = 1
        lg.minimumPressDuration = 1.0
        return lg
    }()

    var active: Bool = false {
        didSet {
//            if active == oldValue { return }
            let delay: DispatchTime = .now() + (active ? 0 : 1)
            DispatchQueue.main.asyncAfter(deadline: delay, execute: {[weak self] in
                guard let `self` = self else { return }
                UIView.animate(withDuration: 0.3) {
                    self.alpha = self.active ? 0.98 : 0.2
                }
            })
        }
    }

    let developerVC: UIViewController = {
        let storyboard = UIStoryboard(name: "IVDeveloperViewController", bundle: IVFileLogger.resourceBundle)
        let vc = storyboard.instantiateInitialViewController() as! UINavigationController
        vc.modalPresentationStyle = .overFullScreen
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return vc
    }()

    let suspendVC: IVSuspendViewController = {
        let vc = IVSuspendViewController()
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.alpha = 0.6
        return vc
    }()

    var rootView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            
            if let newView = rootView {
                newView.frame = self.bounds
                insertSubview(newView, at: 0)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
               
        backgroundColor = UIColor.init(white: 0, alpha: 0.5)
        layer.cornerRadius = frame.size.width / 2
        layer.masksToBounds = true
        addSubview(logo)
                
        addGestureRecognizer(tapGes)
        addGestureRecognizer(panGes)
        addGestureRecognizer(longPressGes)
        
        minimize()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var previousLocation: CGPoint?
    
    func touchUp(_ location: CGPoint) {
        switch dispStyle {
        case .minimize:
            if center.x < UIScreen.main.bounds.width/2 {
                center.x = 0
            } else {
                center.x = UIScreen.main.bounds.width
            }
            if frame.minY < 0 {
                frame.origin.y = 0
            } else if frame.maxY > UIScreen.main.bounds.height {
                frame.origin.y = UIScreen.main.bounds.height - frame.size.height
            }

        case .suspend:
            if center.x < 0 {
                center.x = 0
            } else if center.x > UIScreen.main.bounds.width  {
                center.x = UIScreen.main.bounds.width
            }
            if center.y < 0 {
                center.y = 0
            } else if center.y > UIScreen.main.bounds.height {
                center.y = UIScreen.main.bounds.height
            }
            
        case .fullscreen:
            break
        }
    }
                
    func minimize() {
        UIView.animate(withDuration: 0.3, animations: {
            self.frame = CGRect(x: -32, y: 100, width: 64, height: 64)
            self.layer.cornerRadius = self.frame.size.width / 2
            self.layer.masksToBounds = true
            self.tapGes.isEnabled = true
            self.panGes.isEnabled = true
            self.logo.alpha = 1.0
            self.active = false
        }) { _ in
            self.dispStyle = .minimize
        }
    }
    
    func suspend(content: LogContent) {
        dispStyle = .suspend
        UIView.animate(withDuration: 0.3) {
            let W: CGFloat = UIScreen.main.bounds.width*0.9, H: CGFloat = W*3/4
            self.frame = CGRect(x: (UIScreen.main.bounds.width - W)/2,
                                y: (UIScreen.main.bounds.height - H)/2,
                                width: W,
                                height: H)
            self.tapGes.isEnabled = false
            self.panGes.isEnabled = true
        }
    }

    func fullscreen() {
        dispStyle = .fullscreen
        UIView.animate(withDuration: 0.3) {
            self.frame = UIScreen.main.bounds
            self.layer.cornerRadius = 0
            self.tapGes.isEnabled = false
            self.panGes.isEnabled = false
            self.logo.alpha = 0.1
            self.active = true
        }
    }
    
    @objc func tapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        if (gestureRecognizer.state == .ended) {
            self.bounds.width < 100 ? self.fullscreen() : self.minimize()
        }
    }
    
    @objc func panGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        if dispStyle == .suspend, isPinUp  {
            return
        }
        
        switch gestureRecognizer.state {
        case .began:
            self.active = true
            previousLocation = gestureRecognizer.location(in: superview)
        case .changed:
            let location = gestureRecognizer.location(in: superview)
            let preLocation = previousLocation ?? location
            let dx = location.x - preLocation.x
            let dy = location.y - preLocation.y
            if (abs(dx) > 1 || abs(dy) > 1) {
                frame.origin.x += dx
                frame.origin.y += dy
                previousLocation = location
            }
        case .ended, .cancelled, .failed:
            let location = gestureRecognizer.location(in: superview)
            touchUp(location)
            if dispStyle == .minimize {
                self.active = false
            }
        default:
            break
        }
    }
    
    @objc func longPressGestureRecognizer(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            minimize()
        }
    }

}
