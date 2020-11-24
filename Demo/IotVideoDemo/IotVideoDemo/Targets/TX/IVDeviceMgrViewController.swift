//
//  IVDeviceMgrViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/3/11.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo.IVConnection

class IVDeviceMgrViewController: UITableViewController, IVDeviceAccessable, UITextFieldDelegate {
    var device: IVDevice!
    
    @IBOutlet weak var devSrcNumTF: UITextField!
    @IBOutlet weak var avconfigTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let index = userDeviceList.firstIndex(where: { $0.deviceID == device.deviceID }) {
            device = userDeviceList[index]
        }
        if let num = UserDefaults.standard.value(forKey: "\(device.deviceID)sourceNum") as? Int {
            device.sourceNum = num
            devSrcNumTF.text = "\(num)"
        }

        if let cfg = UserDefaults.standard.value(forKey: "\(device.deviceID)avconfig") as? String {
            device.avconfig = cfg
            avconfigTF.text = device.avconfig
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == devSrcNumTF {
            var num = Int(textField.text ?? textField.placeholder!) ?? 1
            if num < 1 { num = 1 }
            if num > 99 { num = 99 }
            textField.text = "\(num)"
            device.sourceNum = num
            UserDefaults.standard.set(num, forKey: "\(device.deviceID)sourceNum")
        } else if textField == avconfigTF {
            let cfg = textField.text ?? ""
            device.avconfig = cfg
            UserDefaults.standard.set(cfg, forKey: "\(device.deviceID)avconfig")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 { /*暂时屏蔽分享（YUNAPI接口对此方面支持还不够完善,最好是分享给某个用户后，推一条消息，让该用户以分享者身份去绑定并订阅该设备）*/
            return 1
        }
        if section == 1 { /*暂时屏蔽AI*/
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
                IVDemoNetwork.deleteDevice(self.device.deviceID, role: self.device.shareType) { (data, error) in
                    hud.hide()
                    if data == nil {
                        return
                    }
                    
                    userDeviceList.removeAll(where: {$0.deviceID == self.device.deviceID})
                    IVNotiPost(.deviceListChange(by: .delete))
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
