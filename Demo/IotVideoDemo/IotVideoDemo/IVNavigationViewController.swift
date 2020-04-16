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

let kDidReceiveEvent   = "IOT_VIDEO_DEMO_DID_RECEIVE_EVENT_KEY"   //!< 收到Event通知key
let kDidUpdateProperty = "IOT_VIDEO_DEMO_DID_UPDATE_PROPERTT_KEY" //!< 收到属性更新通知key

class IVNavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        IVMessageMgr.sharedInstance.delegate = self
        
        let accessToken = UserDefaults.standard.string(forKey: demo_accessToken)
        let accessId = UserDefaults.standard.string(forKey: demo_accessId)
        if let accessToken = accessToken, let accessId = accessId, !accessToken.isEmpty, !accessId.isEmpty {
            IoTVideo.sharedInstance.register(withAccessId: accessId, accessToken: accessToken)
        }
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
        self.isNavigationBarHidden = false
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
        
        let noti = Notification(name: .IVMessageDidReceiveEvent,
                                object: nil,
                                userInfo: ["body": IVReceiveEventNoti(event: event, topic: topic)])
        NotificationCenter.default.post(noti)
        
    }
    
    func didUpdateProperty(_ json: String, path: String, deviceId: String) {
        logInfo("属性更新 devid:\(deviceId) path:\(path) json:\(json)")
        ivHud("属性更新 devid:\(deviceId) path:\(path) json:\(json)")
        
        if let dev = userDeviceList.first(where: { $0.devId == deviceId }),
            let online = JSON(parseJSON: json).value("_online"), online.exists(),
            let stVal = online.value("stVal")?.boolValue {
            dev.online = stVal
        }
        
        let noti = Notification(name: .IVMessageDidUpdateProperty,
                                object: nil,
                                userInfo: ["body": IVUpdatePropertyNoti(deviceId: deviceId, path: path, json: json)])
        NotificationCenter.default.post(noti)
    }
}


extension Notification.Name {
    /// IVMessage 收到事件
    static let IVMessageDidReceiveEvent = Notification.Name(rawValue: kDidReceiveEvent)
    
    /// IVMessage 收到状态更新
    static let IVMessageDidUpdateProperty = Notification.Name(rawValue: kDidUpdateProperty)
}


struct IVReceiveEventNoti {
    var event: String
    var topic: String
}

struct IVUpdatePropertyNoti {
    var deviceId: String
    var path: String
    var json: String
}
