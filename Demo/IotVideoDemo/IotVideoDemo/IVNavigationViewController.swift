//
//  IVNavigationViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/3/12.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo
import IVAccountMgr
import SwiftyJSON

class IVNavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let accessToken = UserDefaults.standard.string(forKey: demo_accessTokenKey)
        let accessId = UserDefaults.standard.string(forKey: demo_accessIdKey)
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
        let board = UIStoryboard(name: "IVLogin", bundle: nil)
        let loginVC = board.instantiateViewController(withIdentifier: "LogNav") as! UINavigationController
        loginVC.modalPresentationStyle = .fullScreen
        self.present(loginVC, animated: true, completion: nil)
    }
}

extension IVNavigationViewController: IVMessageDelegate {
    func didReceiveEvent(_ event: String, topic: String) {
        logInfo("事件通知 \(topic) \n \(event)")
        ivHud("事件通知 \(topic) \n \(event)")
    }
    
    func didUpdateProperty(_ json: String, path: String, deviceId: String) {
        logInfo("状态通知 \(deviceId) \n \(path) \(json) ")
        ivHud("状态通知 \(deviceId) \n \(path) \(json)")
        if let dev = userDeviceList.first(where: { $0.devId == deviceId }),
            let online = JSON(parseJSON: json).value("_online.stVal")?.boolValue {
            dev.online = online
        }
    }
}
