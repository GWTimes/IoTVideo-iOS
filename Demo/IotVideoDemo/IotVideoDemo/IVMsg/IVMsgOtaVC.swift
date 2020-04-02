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
    
    @IBOutlet weak var newVersionLabel: UILabel!
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
            self.newVersionLabel.text = self.newVersion
            
            showAlert(msg: self.newVersion)
            
            let alert = UIAlertController(title: "当前待更新版本：", message: "\(self.newVersion!) \n 是否确认更新至该版本？", preferredStyle: .alert)
            let ok = UIAlertAction(title: "确认更新", style: .default) { (_) in
                let hud = ivLoadingHud()
                IVMessageMgr.sharedInstance.takeAction(ofDevice: self.device.deviceID, path: "Action._otaVersion", json: "{\"ctlVal\":\"\(self.newVersion!)\"}") { (json, err) in
                    hud.hide()
                    
                    if let err = err {
                        showAlert(msg: "error:\(String(describing: err))")
                        return
                    }
                    
                    self.updateProgressView.isHidden = false
                    self.timer = Timer(timeInterval: 0.5, target: self, selector: #selector(self.getUpdateProgress), userInfo: nil, repeats: true)
                    self.timer?.fire()
                }
            }
            let cancel = UIAlertAction(title: "暂不更新", style: .cancel, handler: nil)
            alert.addAction(ok)
            alert.addAction(cancel)
            self .present(alert, animated: true, completion: nil)
        }
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
