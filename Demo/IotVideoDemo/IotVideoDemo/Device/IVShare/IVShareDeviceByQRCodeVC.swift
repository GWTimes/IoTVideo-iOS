//
//  IVQRCodeCreateVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/3.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IVAccountMgr
import IoTVideo
import SwiftyJSON

class IVShareDeviceByQRCodeVC: UIViewController, IVDeviceAccessable {
    var device: IVDevice!
    @IBOutlet weak var didTF: UITextField!
    @IBOutlet weak var devNameTF: UITextField!
    @IBOutlet weak var userNameTF: UITextField!
    @IBOutlet weak var QRCodeImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let device = device {
            didTF.text      = device.deviceID
            devNameTF.text  = device.deviceName
            userNameTF.text = UserDefaults.standard.string(forKey: demo_userName)
        } 
    }
    
    @IBAction func createQRCode(_ sender: UIButton) {
        
        logInfo("deviceID:", device.deviceID)
        
        view.endEditing(true)
        let hud = ivLoadingHud()
        IVAccountMgr.shared.deviceList { (json, error) in
            if let error = error {
                hud.hide()
                showError(error)
                return
            }
            let devices: [IVDeviceModel] = json!.ivArrayDecode(IVDeviceModel.self) as! [IVDeviceModel]
            var find = false
            var has = false
            devices.forEach { (model) in
                if model.devId == self.device.deviceID {
                    if model.shareType == .owner  {
                        find = true
                    }
                    has = true
                }
            }
            
            if !has {
                hud.hide()
                showAlert(msg: "非法设备，请刷新重试")
                return
            }
            
            if has && !find {
                hud.hide()
                showAlert(msg: "非设备主人不能分享")
                return
            }
            
            
            IVAccountMgr.shared.shareDevieForQRCode(deviceId: self.device.deviceID, deviceName: self.devNameTF.text ?? "", userName: self.userNameTF.text ?? "") { (json, error) in
                hud.hide()
                guard let json = json else {
                    showError(error!)
                    return
                }
                let token = JSON(parseJSON: json)["data"]["qrcodeToken"].intValue
                showAlert(msg: "获取二维码token: \(token)")
                self.QRCodeImage.image = IVQRCodeHelper.createShareDeviceQRCode(withToken: String(token), qrSize: self.QRCodeImage.bounds.size)
                
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
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
