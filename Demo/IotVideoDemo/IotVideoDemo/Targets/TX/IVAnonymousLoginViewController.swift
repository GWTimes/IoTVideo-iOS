//
//  IVAnonymousLoginViewController.swift
//  IotVideoDemo
//
//  Created by zhaoyong on 2020/10/26.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo
import IVDevTools

class IVAnonymousLoginViewController: UIViewController {
    @IBOutlet weak var tmpSecretIDTF: UITextField!
    @IBOutlet weak var tmpSecretKeyTF: UITextField!
    @IBOutlet weak var TidTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // 最终版本将会去掉这两行
        tmpSecretKeyTF.text = IVConfigMgr.allConfigs.first(where: {$0.key == "IOT_TEST_SECRECT_KEY" && $0.enable})?.value
        tmpSecretIDTF.text = IVConfigMgr.allConfigs.first(where: {$0.key == "IOT_TEST_SECRECT_ID" && $0.enable})?.value
        
        // Do any additional setup after loading the view.
    }
    

    @IBAction func loginAction(_ sender: Any) {
        
        guard let secretId = tmpSecretIDTF.text, let secretKey = tmpSecretKeyTF.text, let tid = TidTextField.text else {
            ivHud("请将登陆信息填写完整")
            return
        }
        
        UserDefaults.standard.do {
            $0.setValue(secretId, forKey: demo_secretId)
            $0.setValue(secretKey, forKey: demo_secretKey)
        }
        

        let hud = ivLoadingHud()
        IVTencentNetwork.shared.AnonymousLogin(tid: tid, oldAccessToken: nil) { (json, error) in
            hud.hide()
            guard let loginJson = IVDemoNetwork.handlerError(json, error) else {
                UserDefaults.standard.do {
                    $0.removeObject(forKey: demo_accessToken)
                    $0.removeObject(forKey: demo_accessId)
                }
                return
            }
            if let accessId = loginJson["Response"]["AccessId"].string,
               let accessToken = loginJson["Response"]["AccessToken"].string {
                //注册IoTVideo SDK
                IoTVideo.sharedInstance.register(withAccessId: accessId, accessToken: accessToken)
                let expireTime = loginJson["Response"]["ExpireTime"].doubleValue
                UserDefaults.standard.do {
                    $0.set(accessToken, forKey: demo_accessToken)
                    $0.set(accessId, forKey: demo_accessId)
                    $0.set(expireTime, forKey: demo_expireTime)
                    $0.set("匿名", forKey: demo_userName)
                    $0.set(1, forKey: demo_loginType)
                    $0.set(tid, forKey: demo_AnonymousDev)
                }
                
                IVNotiPost(.deviceListChange(by: .reload))
                self.dismiss(animated: true, completion: nil)
            }
        }
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
