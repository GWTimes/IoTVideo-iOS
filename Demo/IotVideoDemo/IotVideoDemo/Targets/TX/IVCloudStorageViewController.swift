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
    @IBOutlet weak var currentPkg: UILabel!
    @IBOutlet weak var endTime: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resetDes()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getCurrentPgk()
    }
    
    private func getCurrentPgk() {
        IVMessageMgr.sharedInstance.readProperty(ofDevice: device.deviceID, path: "ProWritable._cloudStoage") { (json, error) in
            if let error = error {
                logError("查询云存状态失败",error)
                self.resetDes()
                return
            }
            
            if let json = json,
               let utcExpire = JSON(parseJSON: json).value("setVal.utcExpire")?.doubleValue, let serviceType = JSON(parseJSON: json).value("setVal.serviceType")?.intValue {
                if Date().timeIntervalSince1970 < utcExpire {
                    let fmt = DateFormatter()
                    fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let expireString = fmt.string(from: Date(timeIntervalSince1970: utcExpire))
                    self.endTime.text = expireString
                    self.currentPkg.text = serviceType == 1 ? "全时云存":"事件云存"
                }
            } else {
                self.resetDes()
            }
        }
    }
    
    func resetDes() {
        DispatchQueue.main.async {
            self.currentPkg.text = "暂无可用套餐"
            self.endTime.text = ""
        }
    }
}


