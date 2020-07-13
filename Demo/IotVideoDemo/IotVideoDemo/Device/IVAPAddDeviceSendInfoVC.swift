//
//  IVAPAddDeviceSendInfoVC.swift
//  IotVideoDemoDev
//
//  Created by zhaoyong on 2020/5/20.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo
import MBProgressHUD
import SwiftyJSON



class IVAPAddDeviceSendInfoVC: UIViewController {

    @IBOutlet weak var deviceInfoLabel: UILabel!
    @IBOutlet weak var currentAPLabel: UILabel!
    @IBOutlet weak var helpView: UIView!
    @IBOutlet weak var sendBtn: UIButton!
        
    var hud: MBProgressHUD?
    var preInfo: APPreInfo!
    var device: IVLANDevice? = nil {
        didSet {
            guard let device = self.device else {
                sendBtn.isEnabled = false
                helpView.isHidden = false
                deviceInfoLabel.isHidden = true
                return
            }
            sendBtn.isEnabled = true
            helpView.isHidden = true
            
            deviceInfoLabel.isHidden = false
            deviceInfoLabel.text = """
            DeviceId: \(device.deviceID)
            
            Version: \(device.version)
            
            MAC: \(device.macAddr)
            """
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentAPLabel.text = IVWifiTool.currentSSID
        NotificationCenter.default.addObserver(self, selector: #selector(waitForAPConnection), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc func waitForAPConnection() {
        let hud = ivLoadingHud("等待连接AP", isMask: true)
        IVDelayWork.async(wait: { [weak self](canceled: inout Bool) -> Bool in
            guard let `self` = self else {
                canceled = true
                return false
            }
            let ssid = IVWifiTool.currentSSID
            let conn = ssid?.uppercased().hasPrefix("IOT") ?? false
            
            
            print("设备ip: \(IVNetConfig.lan.getDeviceList().first?.ipAddr ?? "0")")
            
            let apDev = conn ? IVNetConfig.lan.getDeviceList().first(where: { IVWifiTool.isSameNetwork($0.ipAddr, IVWifiTool.ipAddr) }) : nil
            
            DispatchQueue.main.async {[weak self] in
                hud.label.text = conn ? "扫描AP设备" : "等待连接AP"
                self?.currentAPLabel.text = ssid
                logDebug(hud.label.text as Any, apDev as Any)
            }
            
            guard let dev = apDev else { return false }
            
            DispatchQueue.main.async {[weak self] in
                self?.device = dev
            }
            return true
        }, execute: { [weak self](succ) in
            hud.hide()
            logDebug(succ ? "已连接AP设备 \(self?.device as Any)" : "未连接AP设备")
            ivHud(succ ? "已连接AP设备" : "未连接AP设备");
        }, deadline: .now() + 60, interval: 0.5)
    }
    
    @IBAction func goSysSetting(_ sender: Any) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL(string: "App-Prefs:")!, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL(string: "prefs:")!)
        }
    }
    
    @IBAction func sendAction(_ sender: Any) {
        let hud = ivLoadingHud("正在发送配网信息",isMask: true)
        IVNetConfig.lan.sendWifiName(preInfo.ssid, wifiPassword: preInfo.pwd, language: .CN, token: preInfo.token, extraInfo: nil, toDevice: self.device!.deviceID) { (success, error) in
            logDebug(success, error ?? "")
            hud.hide()
            if success {
                self.registerDeviceNetConfig()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 40) {
                    self.hud?.hide()
                }
                
            } else {
                self.hud?.hide()
                ivHud("发送失败，\(error!)");
            }
        }
    }
        
    func registerDeviceNetConfig() {
        self.hud = ivLoadingHud("等待设备上线", isMask: true)
        IVNetConfig.registerDeviceOnlineCallback { [weak self](devId, error) in
            guard let `self` = self else { return }
            let err: NSError = error as NSError
            self.hud?.hide()
            if err.code == 0 || err.code == 8023 {
                let hud = ivLoadingHud("正在绑定设备", isMask: true)
                IVDemoNetwork.addDevice(devId!, responseHandler: { [weak self](data, error) in
                    hud.hide()
                    guard let `self` = self, let succ = data as? Bool else { return }
                    
                    IVPopupView(title: "添加结果", message: succ ? "成功" : "失败", actions: [.iKnow({ (_) in
                        if succ {
                            self.navigationController?.popToRootViewController(animated: true)
                            IVNotiPost(.deviceListChange(by: .add))
                        }
                    })]).show()
                })
            } else {
                showError(error)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
