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
import IVAccountMgr
import SwiftyJSON

//设备扫手机的二维码
class IVQRCodeAddDevice: UIViewController {

    @IBOutlet weak var ssidTF: UITextField!
    @IBOutlet weak var pwdTF: UITextField!
    @IBOutlet weak var QRImgView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        IVMessageMgr.sharedInstance.delegate = self
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
}

extension IVQRCodeAddDevice: IVMessageDelegate {
    func didReceiveEvent(_ event: String, topic: String) {
        if topic == "EVENT_SYS/NetCfg_OK" {
            if let devId = JSON(parseJSON: event)["dev_tid"].string {
                IVAccountMgr.shared.addDevice(deviceId: devId) { (json, error) in
                    if let error = error {
                        showError(error)
                        return
                    }
                    showAlert(msg: json)
                }
            }
        }
    //topic   EVENT_SYS/NetCfg_OK
        /*event
         {
           "devid":"12312321312131"
            "dev_tid": "ab322342342423sdfds"
        }
        */
        
    }
}
