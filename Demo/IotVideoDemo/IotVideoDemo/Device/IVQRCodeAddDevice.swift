//
//  IVQRCodeAddDevice.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo.IVNetConfig
import IoTVideo.IVMessageMgr
import SwiftyJSON
import CoreLocation


//设备扫手机的二维码
class IVQRCodeAddDevice: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var ssidTF: UITextField!
    @IBOutlet weak var pwdTF: UITextField!
    @IBOutlet weak var QRImgView: UIImageView!
    var work: (() -> Void)?
    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        return locationManager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
         NotificationCenter.default.addObserver(self, selector: #selector(getWifiSSIDInfo), name: UIApplication.didBecomeActiveNotification, object: nil)
        getWifiSSIDInfo()
    
        IVNetConfig.registerDeviceOnlineCallback { (devId, error) in
            let err: NSError = error as NSError
            if err.code == 0 || err.code == 8023 {
                let hud = ivLoadingHud()
                
                IVDemoNetwork.addDevice(devId!, responseHandler: { (data, error) in
                    hud.hide()
                    guard let succ = data as? Bool, error == nil else { return }
                    
                    IVPopupView(title: "添加结果", message: succ ? "成功" : "失败", input: nil, actions: [.iKnow({ (_) in
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
        // 监听设备配网结果
//        NotificationCenter.default.addObserver(forName: .iVMessageDidReceiveEvent, object: nil, queue: nil) { (noti) in
//
//            guard let eventModel = noti.userInfo?[IVNotiBody] as? IVReceiveEvent else { return }
//
//            guard eventModel.topic == "EVENT_SYS/NetCfg_OK",
//                let devId = JSON(parseJSON: eventModel.event)["data"]["devid"].string else { return }
//
//            let hud = ivLoadingHud()
//
//            IVDemoNetwork.addDevice(devId, responseHandler: { (data, error) in
//                hud.hide()
//                guard let succ = data as? Bool, error == nil else { return }
//
//                IVPopupView(title: "添加结果", message: succ ? "成功" : "失败", input: nil, actions: [.iKnow({ (_) in
//                    if succ {
//                        self.navigationController?.popToRootViewController(animated: true)
//                        IVNotiPost(.deviceListChange(by: .add))
//                    }
//                })]).show()
//            })
//        }
        
    }
    
    
    @objc func getWifiSSIDInfo() {
        if #available(iOS 13.0, *) {
            requestAuthorization { [weak self] in
               self?.setSSIDTextfield(ssid: IVWifiTool.currentSSID)
            }
        } else {
           setSSIDTextfield(ssid: IVWifiTool.currentSSID)
        }
    }
    
    func setSSIDTextfield(ssid: String?) {
        ssidTF.text = ssid
        let pwd = IVWifiTool.read(wifi: ssid ?? "")
        pwdTF.text = pwd
    }
    
    
    @IBAction func createQRCode(_ sender: Any) {
        view.endEditing(true)
        let hud = ivLoadingHud()
        
        let ssid = self.ssidTF.text ?? ""
        let pwd  = self.pwdTF.text  ?? ""
        
        IVWifiTool.save(wifi: ssid, pwd)
        
        IVNetConfig.getToken { (token, error) in
            hud.hide()
            if let error = error {
                showError(error)
                return
            }
            self.QRImgView.image = IVNetConfig.qrCode.createQRCode(withWifiName: ssid,
                                                                   wifiPassword: pwd,
                                                                   reserve: IoTVideo.sharedInstance.accessId,
                                                                   language: .EN,
                                                                   token: token!,
                                                                   extraInfo: nil,
                                                                   qrSize: self.QRImgView.frame.size)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    
    func requestAuthorization(_ work: @escaping () -> Void) {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            DispatchQueue.main.async(execute: work)
        case .denied,.restricted:
            showAlert(msg: "请前往设置开启定位权限", title: "提示")
        case .notDetermined:
            requestLoationPermissionWithHandle(work)
        default:
            showAlert(msg: "未知错误", title: "提示")
        }
    }
    
    func requestLoationPermissionWithHandle(_ handle: @escaping () -> Void) {
         work = handle
         locationManager.requestWhenInUseAuthorization()
     }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if let work = work {
            requestAuthorization(work)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

