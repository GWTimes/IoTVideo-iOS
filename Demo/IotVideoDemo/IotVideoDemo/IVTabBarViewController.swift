//
//  IVTabBarViewController.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/3.
//  Copyright © 2019 gwell. All rights reserved.
//

import UIKit
import IoTVideo
import IVAccountMgr
import SwiftyJSON

class IVTabBarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.hidesBottomBarWhenPushed = true
        let accessToken = UserDefaults.standard.value(forKey: demo_accessTokenKey) as? String
        let accessId = UserDefaults.standard.value(forKey: demo_accessIdKey) as? String
        let expireTime = UserDefaults.standard.value(forKey: demo_expireTimeKey) as? TimeInterval
        if let accessToken = accessToken, let accessId = accessId, let expireTime = expireTime, !accessToken.isEmpty, !accessId.isEmpty {
            IoTVideo.sharedInstance.register(withAccessId: accessId, accessToken: accessToken)
            if expireTime - Date().timeIntervalSince1970 < 7 * 24 * 60 * 60 {
                DispatchQueue.global().async {
                    IVAccountMgr.shared.updateaccessToken { (json, error) in
                        guard let json = json else {
                            showError(error!)
                            return
                        }
                        let newJson = JSON(parseJSON: json)
                        UserDefaults.standard.do {
                            $0.set(newJson["data"]["accessToken"].string, forKey: demo_accessTokenKey)
                            $0.set(newJson["data"]["expireTime"].doubleValue, forKey:demo_expireTimeKey)
                        }
                        IoTVideo.sharedInstance.updateToken(newJson["data"]["accessToken"].string!)
                    }
                }
            }
        }
        
        IVMessageMgr.sharedInstance.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //        IoTVideo.sharedInstance.setupToken("010142271C6A0E01B6B84F626600000088BF8A936C85A3E5DF862E1D298FDECDF82E0FAEF9C5AAC21B1F47631242203BABDDE8D10054B143FC47BFE634676C88", accessId: "-9223371598768111613")
        if IoTVideo.sharedInstance.accessToken?.isEmpty ?? true {
            jumpToLoginView()
        } else {
            print("ivToke:",IoTVideo.sharedInstance.accessToken!)
        }
        let window = (UIApplication.shared.delegate as! AppDelegate).window
        window?.addSubview(devToolsAssistant)
        window?.bringSubviewToFront(devToolsAssistant)
    }
    
    
    func jumpToLoginView() {
        let board = UIStoryboard(name: "Login", bundle: nil)
        let loginVC = board.instantiateViewController(withIdentifier: "LogNav") as! UINavigationController
        loginVC.modalPresentationStyle = .fullScreen
        self.present(loginVC, animated: true, completion: nil)
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
}

extension IVTabBarViewController: IVMessageDelegate {
    func didReceiveEvent(_ event: String, topic: String) {
        logInfo("事件通知 \(topic) \n \(event)")
        ivHud("事件通知 \(topic) \n \(event)")
    }
    
    func didUpdateProperty(_ json: String, path: String, deviceId: String) {
        logInfo("状态通知 \(deviceId) \n \(path) \(json) ")
        ivHud("状态通知 \(deviceId) \n \(path) \(json)")
        if let dev = IVDeviceTableViewController.mineDevice.first(where: { $0.did == deviceId }),
            let online = JSON(parseJSON: json).value("_online.stVal")?.boolValue {
            dev.online = online
        }
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
    let error = error as NSError
    if error.code == 401 {
        UserDefaults.standard.do {
            $0.removeObject(forKey: demo_accessTokenKey)
            $0.removeObject(forKey: demo_accessIdKey)
            $0.removeObject(forKey: demo_expireTimeKey)
        }
        let board = UIStoryboard(name: "Login", bundle: nil)
        let loginVC = board.instantiateViewController(withIdentifier: "LogNav") as! UINavigationController
        loginVC.modalPresentationStyle = .fullScreen
        topVC()?.present(loginVC, animated: true, completion: nil)
    } else {
        showAlert(msg: "\(error)", title: "请求失败")
    }
}

func showAlert(msg: String?, title: String = "请求结果") {
    let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
    let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
    alert.addAction(ok)
    topVC()?.present(alert, animated: true, completion: nil)
}

func showBanner(msg: String?, title: String = "状态更新") {
    let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
    let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
    alert.addAction(ok)
    topVC()?.present(alert, animated: true, completion: nil)
}

func topVC() -> UIViewController? {
    var topVC = UIApplication.shared.keyWindow?.rootViewController
    while topVC?.presentedViewController != nil {
        topVC = topVC?.presentedViewController
    }
    return topVC
}
