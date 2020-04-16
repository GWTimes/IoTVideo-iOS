//
//  IVQRCodeAddDevice.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo.IVNetConfig
import IoTVideo.IVMessageMgr
import SwiftyJSON

//设备扫手机的二维码
class IVQRCodeAddDevice: UIViewController {
    
    @IBOutlet weak var ssidTF: UITextField!
    @IBOutlet weak var pwdTF: UITextField!
    @IBOutlet weak var QRImgView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // 监听设备配网结果
        NotificationCenter.default.addObserver(forName: .IVMessageDidReceiveEvent, object: nil, queue: nil) { (noti) in
            
            guard let eventModel = noti.userInfo?["body"] as? IVReceiveEventNoti else {
                return
            }
            
            guard eventModel.topic == "EVENT_SYS/NetCfg_OK",
                let devId = JSON(parseJSON: eventModel.event)["dev_tid"].string else { return }
            
            let hud = ivLoadingHud()
            
            IVDemoNetwork.addDevice(devId, responseHandler: { (data, error) in
                hud.hide()
                guard let succ = data as? Bool, error == nil else { return }
                
                IVPopupView(title: "添加结果", message: succ ? "成功" : "失败", input: nil, actions: [.iKnow({ (_) in
                    if succ {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                })]).show()
            })
        }
    }
    
    @IBAction func createQRCode(_ sender: Any) {
        view.endEditing(true)
        let hud = ivLoadingHud()
        IVNetConfig.qrCode.createQRCode(withWifiName: ssidTF.text ?? "", wifiPwd: pwdTF.text, qrSize: QRImgView.frame.size, completionHandler: { (image, error) in
            hud.hide()
            if let error = error {
                showError(error as NSError)
                return
            }
            self.QRImgView.image = image
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

