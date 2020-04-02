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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 { //暂时屏蔽分享（YUNAPI接口对此方面支持还不够完善）
            return 1
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        if cell?.textLabel?.text == "删除设备" {
            let unbind = IVPopupAction(title: "删除设备", style: .destructive, handler: { _ in
                let hud = ivLoadingHud()
                IVDemoNetwork.deleteDevice(self.device.deviceID, role: .owner) { (data, error) in
                    hud.hide()
                    if data == nil {
                        return
                    }
                    userDeviceList.removeAll(where: { $0.devId == self.device.deviceID })
                    self.navigationController?.popToRootViewController(animated: true)
                }
            })
            IVPopupView(message: "确认删除设备？", actions: [unbind, .cancel()]).show()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dstVC = segue.destination as? IVDeviceAccessable {
            dstVC.device = device
        }
    }
    
}
