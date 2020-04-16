//
//  IVCloudStorageViewController.swift
//  IotVideoDemoTX
//
//  Created by ZhaoYong on 2020/3/18.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo.IVMessageMgr
import SwiftyJSON

class IVCloudStorageViewController: IVDeviceAccessableTVC {
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {  // "031400005e05dd490dfbc385ebd1a7e4"
            IVMessageMgr.sharedInstance.readProperty(ofDevice: device.deviceID, path: "ProWritable._cloudStoage") { (json, error) in
                if let error = error {
                    showAlert(msg: "查询失败 \(error)")
                    return
                }
                
                var message = ""
                if let json = json,
                    let utcExpire = JSON(parseJSON: json).value("setVal.utcExpire")?.doubleValue {
                    if Date().timeIntervalSince1970 < utcExpire {
                        message = "当前套餐仍然在有效期内，新套餐将在当前套餐到期时自动生效。"
                    }
                }
                
                IVPopupView(title: "您确定购买云存套餐吗？", message: message, input: nil, actions: [.cancel(), .confirm({ (_) in
                    let hud = ivLoadingHud()
                    IVDemoNetwork.buyCloudStoragePackage("yc1m3d", deviceId: self.device.deviceID) { (data, err) in
                        hud.hide()
                        guard let _ = data else {
                            return
                        }
                        ivHud("购买成功")
                    }
                })]).show()

            }
        }
    }
    
}
