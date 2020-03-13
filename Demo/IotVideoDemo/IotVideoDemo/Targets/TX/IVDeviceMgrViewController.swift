//
//  IVDeviceMgrViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/3/11.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit

class IVDeviceMgrViewController: UITableViewController, IVDeviceAccessable {
    var device: IVDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        if cell?.textLabel?.text == "设备解绑" {
            let unbind = IVPopupAction(title: "解绑", style: .destructive, handler: { _ in
                
                IVTencentNetwork.shared.deleteDevice(deviceId: self.device.deviceID, role: .owner) { (json, error) in
                    if let error = error {
                        showAlert(msg: "\(error)")
                        return
                    }
                    guard let _ = parseJson(json) else {
                        return
                    }
                    
                    userDeviceList.removeAll(where: { $0.devId == self.device.deviceID })
                    self.navigationController?.popToRootViewController(animated: true)
                }
            })
            IVPopupView(message: "确认解绑设备？", actions: [unbind, .cancel()]).show()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dstVC = segue.destination as? IVDeviceAccessable {
            dstVC.device = device
        }
    }
    
}
