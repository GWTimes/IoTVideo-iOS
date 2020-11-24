//
//  IVNavigationViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/3/12.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo
import SwiftyJSON


class IVNavigationViewController: UINavigationController {
        
    override func viewDidLoad() {
        super.viewDidLoad()

        IVMessageMgr.sharedInstance.delegate = self
        interactivePopGestureRecognizer?.isEnabled = true

        let accessToken = UserDefaults.standard.string(forKey: demo_accessToken)
        let accessId = UserDefaults.standard.string(forKey: demo_accessId)
        if let accessToken = accessToken, let accessId = accessId, !accessToken.isEmpty, !accessId.isEmpty {
            IoTVideo.sharedInstance.register(withAccessId: accessId, accessToken: accessToken)
        }
        
        addLogoutObserver()
    }
       
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if IoTVideo.sharedInstance.accessToken?.isEmpty ?? true {
            jumpToLoginView()
        } else {
            logInfo("ivToke:",IoTVideo.sharedInstance.accessToken!)
        }
        let window = (UIApplication.shared.delegate as! AppDelegate).window
        window?.addSubview(devToolsAssistant)
        window?.bringSubviewToFront(devToolsAssistant)
    }
    
    func jumpToLoginView() {
        DispatchQueue.global().async {
            IoTVideo.sharedInstance.unregister()
        }
        UserDefaults.standard.do {
            $0.removeObject(forKey: demo_accessToken)
            $0.removeObject(forKey: demo_accessId)
            $0.removeObject(forKey: demo_expireTime)
        }
        self.isNavigationBarHidden = false
        let board = UIStoryboard(name: "IVLogin", bundle: nil)
        let loginVC = board.instantiateViewController(withIdentifier: "LogNav") as! UINavigationController
        loginVC.modalPresentationStyle = .fullScreen
        self.present(loginVC, animated: true, completion: nil)
        self.popToRootViewController(animated: false)
    }
    
    func addLogoutObserver() {
        NotificationCenter.default.addObserver(forName: .ivLogout, object: nil, queue: .main) { (_) in
            self.jumpToLoginView()
        }
    }
}

extension IVNavigationViewController: IVMessageDelegate {
    func didReceiveEvent(_ event: String, topic: String) {
        logInfo("事件通知 \(event)")
        view.makeToast("事件通知 \(topic) \n \(event)", duration: 2, position: .top)

        IVNotiPost(.receiveEvent(IVReceiveEvent(event: event, topic: topic)))
    }
    
    func didUpdateProperty(_ json: String, path: String, deviceId: String) {
        logInfo("属性更新 devid:\(deviceId) path:\(path) json:\(json)")
        view.makeToast("属性更新 devid:\(deviceId) path:\(path) json:\(json)", duration: 1.5, position: .bottom)

        IVNotiPost(.updateProperty(IVUpdateProperty(deviceId: deviceId, path: path, json: json)))
    }
}




