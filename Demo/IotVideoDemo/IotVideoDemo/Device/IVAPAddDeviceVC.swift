//
//  IVAPAddDeviceVC.swift
//  IotVideoDemoDev
//
//  Created by zhaoyong on 2020/5/15.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo
import CoreLocation

 struct APPreInfo {
    let ssid: String
    let pwd: String
    let token: String
}

class IVAPAddDeviceVC: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var ssidTF: UITextField!
    @IBOutlet weak var pwdTF: UITextField!
    
    @IBOutlet weak var nextStepBtn: UIButton!
    @IBOutlet weak var tokenLabel: UILabel!
    var netToken: String?
    
    
    var work: (() -> Void)?
    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        return locationManager
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(getWifiSSIDInfo), name: UIApplication.didBecomeActiveNotification, object: nil)
         getNetConfigToken()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getWifiSSIDInfo()
    }
    
    @IBAction func getToken(_ sender: Any) {
        getNetConfigToken()
    }
    
    func getNetConfigToken() {
        let hud = ivLoadingHud("正在获取token")
        IVNetConfig.getToken { (token, error) in
            logDebug(token ?? "", error ?? "")
            hud.hide()
            guard let token = token else {
                showError(error!)
                return
            }
            self.netToken = token
            self.tokenLabel.text = token
        }
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        guard let ssid = ssidTF.text, !ssid.isEmpty else {
            ivHud("请填写wifi 名称")
            return
        }
        
        guard let token = netToken, !token.isEmpty else {
             ivHud("请重新获取 token")
             return
         }
 
        let pwd = self.pwdTF.text ?? ""
        
        IVWifiTool.save(wifi: ssid, pwd)
         
        requestAuthorization {
            let vc = UIStoryboard(name: "IVAPAddDevice", bundle: Bundle.main).instantiateViewController(withIdentifier: "IVAPAddDeviceSendInfoVC") as! IVAPAddDeviceSendInfoVC
            
            let info = APPreInfo(ssid: ssid, pwd: pwd, token: token)
            vc.preInfo = info
            self.navigationController?.pushViewController(vc, animated: true)
        }
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
