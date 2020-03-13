//
//  IVShareDeviceByAccountVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/19.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IVAccountMgr
import SwiftyJSON

class IVShareDeviceByAccountVC: UIViewController, IVDeviceAccessable {
    var device: IVDevice!
    @IBOutlet weak var mobileAreaTF: UITextField!
    
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var mobielTF: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print(device ?? "")
    }
    
    @IBAction func emailShare(_ sender: Any) {
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

            IVAccountMgr.shared.findUserInfo(email: self.emailTF.text ?? "", responseHandler: { (jsonStr, error) in
                if let error = error {
                    hud.hide()
                    showError(error)
                    return
                }
                let json = JSON(parseJSON: jsonStr!)
                if let ivUid = json["data"]["ivUid"].string {
                    IVAccountMgr.shared.shareDeviceForVisitor(deviceId: self.device.deviceID, accountId: ivUid) { (jsonStr, error) in
                        hud.hide()
                        guard let json = jsonStr else {
                            showError(error!)
                            return
                        }
                        showAlert(msg: "分享成功： \(json)")
                    }
                } else {
                    hud.hide()
                    showAlert(msg: jsonStr)
                }
            })
           
        }
        
        
    }
    
    
    @IBAction func mobileShare(_ sender: Any) {
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
            
            IVAccountMgr.shared.findUserInfo(mobile: self.mobielTF.text ?? "", mobileArea: self.mobileAreaTF.text ?? "") { (jsonStr, error) in
                if let error = error {
                    hud.hide()
                    showError(error)
                    return
                }
                let json = JSON(parseJSON: jsonStr!)
                if let ivUid = json["data"]["ivUid"].string {
                    IVAccountMgr.shared.shareDeviceForVisitor(deviceId: self.device.deviceID, accountId: ivUid) { (jsonStr, error) in
                        hud.hide()
                        guard let json = jsonStr else {
                            showError(error!)
                            return
                        }
                        showAlert(msg: "分享成功： \(json)")
                    }
                } else {
                    hud.hide()
                    showAlert(msg: jsonStr)
                }
            }
        }
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
