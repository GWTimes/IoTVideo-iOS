//
//  IVHud.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2020/1/7.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import MBProgressHUD


func safe_main_async(_ execute: @escaping () -> Void) {
    if Thread.isMainThread {
        execute()
    } else {
        DispatchQueue.main.async {
            execute()
        }
    }
}

func ivHud(_ msg: String?, icon: String? = nil,inView view: UIView? = nil, isMask mask: Bool = false)  {
    safe_main_async({
        guard let showView = view ?? UIApplication.shared.windows.last else {return}
        let hud = MBProgressHUD.showAdded(to: showView, animated: true)
        hud.label.text = msg
        hud.label.numberOfLines = 0
        if let icon = icon {
            hud.customView = UIImageView(image: UIImage(named: icon))
            hud.mode = .customView
        } else {
            hud.mode = .text
        }
        if mask {
            hud.backgroundView.color = UIColor(white: 0, alpha: 0.4)
            hud.isUserInteractionEnabled = true
        } else {
            hud.isUserInteractionEnabled = true
        }
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 1.5)
    })
}

func ivLoadingHud(_ msg: String? = nil, inView view: UIView? = nil,  isMask mask: Bool = false) -> MBProgressHUD {
    if !Thread.current.isMainThread {
        var obj: MBProgressHUD!
        DispatchQueue.main.sync {
            obj = ivLoadingHud(msg, inView: view, isMask: mask)
        }
        return obj
    }
    let showView = view ?? UIApplication.shared.keyWindow!
    let hud = MBProgressHUD.showAdded(to: showView, animated: true)
    hud.label.text = msg
    hud.mode = .indeterminate
    if mask {
        hud.backgroundView.color = UIColor(white: 0, alpha: 0.4)
        hud.isUserInteractionEnabled = true
    } else {
        hud.isUserInteractionEnabled = true
    }
    hud.removeFromSuperViewOnHide = true
    return hud
}


extension MBProgressHUD {
    func hide() {
        safe_main_async({
            self.hide(animated: true)
        })
    }
}

func handleWebCallback(json: String?, error: Error?) {
    if let error = error {
        showError(error)
        return
    }
    showAlert(msg: json!)
}

func showError(_ error: Error) {
    safe_main_async({
        let error = error as NSError
        if error.code == 401 {
            UserDefaults.standard.do {
                $0.removeObject(forKey: demo_accessToken)
                $0.removeObject(forKey: demo_accessId)
                $0.removeObject(forKey: demo_expireTime)
            }
            let board = UIStoryboard(name: "IVLogin", bundle: nil)
            let loginVC = board.instantiateViewController(withIdentifier: "LogNav") as! UINavigationController
            loginVC.modalPresentationStyle = .fullScreen
            topVC()?.present(loginVC, animated: true, completion: nil)
        } else {
            showAlert(msg: "\(error)", title: "请求失败")
        }
    })
}

func showAlert(msg: String?, title: String = "请求结果") {
    safe_main_async({
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        topVC()?.present(alert, animated: true, completion: nil)
    })
}

func showBanner(msg: String?, title: String = "状态更新") {
    safe_main_async({
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        topVC()?.present(alert, animated: true, completion: nil)
    })
}

func topVC() -> UIViewController? {
    var topVC = UIApplication.shared.keyWindow?.rootViewController
    while topVC?.presentedViewController != nil {
        topVC = topVC?.presentedViewController
    }
    return topVC
}
