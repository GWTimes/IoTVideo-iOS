//
//  IVCloudStorageViewController.swift
//  IotVideoDemoTX
//
//  Created by ZhaoYong on 2020/3/18.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit

class IVCloudStorageViewController: IVDeviceAccessableTVC {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {  // "031400005e05dd490dfbc385ebd1a7e4"
            let hud = ivLoadingHud()
            IVDemoNetwork.buyCloudStoragePackage("yc1m3d", deviceId: self.device.deviceID) { (data, err) in
                hud.hide()
                guard let _ = data else {
                    return
                }
                ivHud("购买成功")
            }
        }
    }
    
}
