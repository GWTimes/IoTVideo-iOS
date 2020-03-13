//
//  IVLoginVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/2.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IVAccountMgr
import IoTVideo


class IVLoginVC: UIViewController {    
    @IBOutlet weak var accountTextField: UITextField!
    @IBOutlet weak var pwdAccount: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        if let type = IoTVideo.sharedInstance.options?[IVOptionKey.hostType] as? String {
            self.title = type == "0" ? "登录（测试服）" : "登录（正式服）"
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let window = (UIApplication.shared.delegate as! AppDelegate).window
        window?.addSubview(devToolsAssistant)
        window?.bringSubviewToFront(devToolsAssistant)
    }
    
    @IBAction func login(_ sender: Any) {
        let hud = ivLoadingHud(isMask: true)
        accountTextField.resignFirstResponder()
        pwdAccount.resignFirstResponder()
        IVAccountMgr.shared.login(account: accountTextField.text ?? "", password: pwdAccount.text ?? "") { (json, error) in
            hud.hide()
            if let error = error {
                showError(error)
                return
            }
            let model = IVJson.decode(json: json!, type: IVModel<LoginModel>.self)
            if let accessToken = model?.data?.accessToken, let accessId = model?.data?.accessId {
             
                //注册IoTVideo SDK
                IoTVideo.sharedInstance.register(withAccessId: accessId, accessToken: accessToken)
                let expireTime = model?.data?.expireTime
                let userName = model?.data?.nick
                UserDefaults.standard.do {
                    $0.set(accessToken, forKey: demo_accessTokenKey)
                    $0.set(accessId,    forKey: demo_accessIdKey)
                    $0.set(expireTime,  forKey: demo_expireTimeKey)
                    $0.set(userName,    forKey: demo_userName)
                }
                
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func resetPwd(_ sender: Any) {
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let id = segue.identifier {
            let vc = segue.destination as! IVRegisterVC
            if id == "register" {
                vc.comeInType = .register
            } else if id == "resetPwd" {
                vc.comeInType = .findBackPwd
            }
        }
    }
}

struct LoginModel: Codable {
    var headUrl: String?
    var nick: String?
    var accessToken: String?
    var accessId: String?
    var expireTime: Int = 0
}

