//
//  IVMsgOtaVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2020/3/12.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo.IVMessageMgr
import SwiftyJSON

class IVMsgOtaVC: UIViewController, IVDeviceAccessable {
    var device: IVDevice!
    @IBOutlet weak var updateProgressView: UIStackView!
    @IBOutlet weak var updatePersentLabel: UILabel!
    @IBOutlet weak var updatePersentProgress: UIProgressView!
    var newVersion: String?
    var timer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func searchNewVersion(_ sender: Any) {
        let hud = ivLoadingHud()
        IVMessageMgr.sharedInstance.takeAction(ofDevice: self.device.deviceID, path: "Action._otaVersion", json: "{\"ctlVal\":\"\"}") { (json, err) in
            hud.hide()
            
            if let err = err {
                showAlert(msg: "error:\(String(describing: err))")
                return
            }
            
            guard let json = json, json.count > 0 else {
                showAlert(msg: "当前无可升级版本")
                return
            }
            
            self.newVersion = JSON(parseJSON: json)["stVal"].stringValue
            
            showAlert(msg: self.newVersion)
        }
    }
    
    @IBAction func update(_ sender: Any) {
        guard let newVersion = self.newVersion else {
            showAlert(msg: "当前无可升级版本")
            return
        }
        let pop = IVPopupView(title: "OTA升级", message: "输入可升级的版本号", input: ["{\"ctlVal\":\"\(newVersion)\"}"], actions:[ .cancel(), .confirm({ v in
            let hud = ivLoadingHud()
            IVMessageMgr.sharedInstance.takeAction(ofDevice: self.device.deviceID, path: "Action._otaVersion", json: v.inputFields[0].text ?? "") { (json, err) in
                hud.hide()
                
                if let err = err {
                    showAlert(msg: "error:\(String(describing: err))")
                    return
                }
                
                self.updateProgressView.isHidden = false
                self.timer = Timer(timeInterval: 0.5, target: self, selector: #selector(self.getUpdateProgress), userInfo: nil, repeats: true)
                self.timer?.fire()
            }
        })])
        pop.inputFields[0].text = "{\"ctlVal\":\"\(newVersion)\"}"
        pop.show()
    }
    
    @objc func getUpdateProgress() {
        IVMessageMgr.sharedInstance.readProperty(ofDevice: self.device.deviceID, path: "ProReadonly._otaUpgrade", completionHandler: { (json, err) in
            
            if let err = err {
                showAlert(msg: "error:\(String(describing: err))")
                self.updateProgressView.isHidden = true
                self.timer?.invalidate()
                self.timer = nil
                return
            }
            
            let updatePersent = JSON(parseJSON: json!)["stVal"].float ?? 0
            self.updatePersentLabel.text = "\(updatePersent)%"
            self.updatePersentProgress.progress = updatePersent / 100
            
            while updatePersent == 100 {
                self.timer?.invalidate()
                self.timer = nil
            }
        })
       
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
