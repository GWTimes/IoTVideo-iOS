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
    var newVersion: String? {
        didSet {
            self.newVersionLabel.text = newVersion
        }
    }
    
    var dataSource = [[String: AnyHashable]]()
    var jsonData = [String: AnyHashable]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updatePersentProgress.transform = CGAffineTransform(scaleX: 1.0, y: 2.5)

        requestNewIoTModel()
        addUpdateObserver()
    }
    
    //获取最新的物模型，根据最新的物模型动态配置
    //开发者拿到的物模型应该是最新且稳定的，可以根据文档设置具体物模型，而无需先获取所有模型
    func requestNewIoTModel() {
        let hud = ivLoadingHud()
        IVMessageMgr.sharedInstance.readProperty(ofDevice: device.deviceID, path: "") { (json, error) in
            hud.hide()
            guard let json = json else {
                ivHud(error?.localizedDescription)
                return
            }
            
            let data = json.data(using: .utf8)!
            self.getDataSource(by: data)
        }
    }
    
    //解析对应数据
    func getDataSource(by data:Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            jsonData = json as! [String: AnyHashable]
            let keyArray  = [String](jsonData.keys).sorted()
            let canUseKeys = ["ProReadonly", "Action"] //过滤当前OTC需要用到的组别
            for key in keyArray {
                if canUseKeys.contains(key) {
                    dataSource.append(["key": key, "value": [String]((jsonData[key] as! [String: AnyHashable]).keys).sorted()])
                }
            }
            
        } catch let error {
            logWarning(error.localizedDescription)
        }
    }
    
    //MARK: 查询更新信息
    @IBAction func searchNewVersion(_ sender: Any) {
        let hud = ivLoadingHud()
        
        //获取最新的查询服务器版本的json,此处为开发实时适配物模型的变更做的工作
        //开发者使用时物模型应该已经稳定，可以直接使用如:
        // "{\"stVal\":\"\"}" 这样的json字符串直接查询，具体需要根据对应物模型文档
        // Action._otaVersion 的 stVal 填空字符串即为查询可升级的最新固件版本号
        var searchTextJson = ""
        do {
            let searchTextDic = (self.jsonData["Action"] as! [String: AnyHashable])["_otaVersion"] as! [String: AnyHashable]
            let searchTextData = try JSONSerialization.data(withJSONObject: searchTextDic, options: [])
            searchTextJson = String(data:searchTextData, encoding: .utf8) ?? ""
        } catch let error {
            logWarning(error)
        }
        
        IVMessageMgr.sharedInstance.takeAction(ofDevice: self.device.deviceID, path: "Action._otaVersion", json: searchTextJson) { (json, err) in
            hud.hide()
            
            if let err = err {
                showAlert(msg: "error:\(String(describing: err))")
                return
            }
            
            ivHud("发送成功")
        }
    }
    
    
    // 监听升级查询结果通知
    func addUpdateObserver() {
        NotificationCenter.default.addObserver(forName: .IVMessageDidUpdateProperty, object: nil, queue: nil) { (noti) in
            guard let propertyModel = noti.userInfo?["body"] as? IVUpdatePropertyNoti else {
                return
            }
            
            // 升级版本通知(最新的返回 Action._otaVersion)
            if propertyModel.path == "ProReadonly._otaVersion" || propertyModel.path == "Action._otaVersion" {
                
                var newVersion = ""
                
                if let new = JSON(parseJSON: propertyModel.json)["ctlVal"].string  { //兼容旧版本
                    newVersion = new
                }
                
                if let new = JSON(parseJSON: propertyModel.json)["stVal"].string {
                    newVersion = new
                }
                
                guard !newVersion.isEmpty else {
                    //                showAlert(msg: "当前无可升级版本")
                    ivHud("当前无可升级版本")
                    return
                }
                
                self.newVersion = newVersion
                self.handNewVersion()
            }
            
            // 更新进度
            if propertyModel.path == "ProReadonly._otaUpgrade" || propertyModel.path == "Action._otaUpgrade" {
                guard let persent = JSON(parseJSON: propertyModel.json)["stVal"].int else {
                    logWarning("OTA升级进度解析失败")
                    return
                }
                UIView.animate(withDuration: 0.5) {
                    self.updatePersentLabel.text = "\(persent)%"
                    self.updatePersentProgress.progress = Float(persent) / 100.0
                }
                
                if persent == 100 {
                    ivHud("升级完成，设备正在重启，请稍候", isMask: true, delay: 10)
                    NotificationCenter.default.addObserver(forName: .IVMessageDidUpdateProperty, object: nil, queue: nil) { (noti) in
                        guard let onlineModel = noti.userInfo?["body"] as? IVUpdatePropertyNoti else {
                            return
                        }
                        if onlineModel.deviceId == self.device.deviceID && onlineModel.path == "ProReadonly._online" {
                            showAlert(msg: "更新完成,设备已经重启")
                        }
                    }
                }
            }
        }
    }
    
    //处理新版本
    func handNewVersion() {
        let alert = UIAlertController(title: "当前待更新版本：", message: "\(self.newVersion!) \n 是否确认更新至该版本？", preferredStyle: .alert)
        let ok = UIAlertAction(title: "确认更新", style: .default) { (_) in
            let hud = ivLoadingHud()
            
            // Action._otaUpgrade 的 ctlVal/stVal 填空 1 即为升级到最新固件版本
            var upgradeTextJson = ""
            do {
                var upgradeTextDic = (self.jsonData["Action"] as! [String: AnyHashable])["_otaUpgrade"] as! [String: AnyHashable]
                if let _ = upgradeTextDic["ctlVal"] as? Int {
                    upgradeTextDic["ctlVal"] = 1 //设置升级标志位 旧
                } else {
                    upgradeTextDic["stVal"] = 1 //设置升级标志位 新
                }
                
                let upgradeTextData = try JSONSerialization.data(withJSONObject: upgradeTextDic, options: [])
                upgradeTextJson = String(data: upgradeTextData, encoding: .utf8) ?? ""
            } catch let error {
                logWarning(error)
            }
            
            IVMessageMgr.sharedInstance.takeAction(ofDevice: self.device.deviceID, path: "Action._otaUpgrade", json: upgradeTextJson) { (json, err) in
                hud.hide()
                
                if let err = err {
                    showAlert(msg: "error:\(String(describing: err))")
                    return
                }
                
                self.updateProgressView.isHidden = false
            }
        }
        let cancel = UIAlertAction(title: "暂不更新", style: .cancel, handler: nil)
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        logDebug(#file,"deinit")
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
