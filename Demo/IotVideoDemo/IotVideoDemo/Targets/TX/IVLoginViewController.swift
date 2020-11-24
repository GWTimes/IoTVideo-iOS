//
//  IVLoginViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/3/10.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo
import SwiftyJSON
import IVDevTools

class IVLoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var tmpSecretIDTF: UITextField!
    @IBOutlet weak var tmpSecretKeyTF: UITextField!
    @IBOutlet weak var tokenTF: UITextField!
    @IBOutlet weak var userNameTF: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = (using_test_web_host ? "登录（测试服）" : "登录（正式服）")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let window = (UIApplication.shared.delegate as! AppDelegate).window
        window?.addSubview(devToolsAssistant)
        window?.bringSubviewToFront(devToolsAssistant)
        
        // 最终版本将会去掉这两行
        tmpSecretKeyTF.text = IVConfigMgr.allConfigs.first(where: {$0.key == "IOT_TEST_SECRECT_KEY" && $0.enable})?.value
        tmpSecretIDTF.text = IVConfigMgr.allConfigs.first(where: {$0.key == "IOT_TEST_SECRECT_ID" && $0.enable})?.value
        
    }
    
    @IBAction func loginBtnClicked(_ sender: UIButton) {
        let hud = ivLoadingHud(isMask: true)
        
        //正常登陆：腾讯控制台获取的 id,key和用户名
        //临时授权登陆：腾讯控制台获取的 临时id,key,token和用户名
        let account = TXAccount(userName: userNameTF.text ?? "",
                                secretId: tmpSecretIDTF.text ?? "",
                                secretKey: tmpSecretKeyTF.text ?? "",
                                tempToken: tokenTF.text ?? "")
        

        IVTencentNetwork.shared.register(account: account) {[weak self](regJson, error) in
            
            guard let regJson = IVDemoNetwork.handlerError(regJson, error) else {
                hud.hide()
                return
            }
            
            let login = {
                if let accessId = regJson["Response"]["AccessId"].string {
                    IVTencentNetwork.shared.login(accessId: accessId) { (loginJson, error) in
                        hud.hide()
                        
                        guard let loginJson = IVDemoNetwork.handlerError(loginJson, error) else {
                            UserDefaults.standard.do {
                                $0.removeObject(forKey: demo_accessToken)
                                $0.removeObject(forKey: demo_accessId)
                            }
                            return
                        }
                        
                        if let accessToken = loginJson["Response"]["AccessToken"].string {
                            //注册IoTVideo SDK
                            IoTVideo.sharedInstance.register(withAccessId: accessId, accessToken: accessToken)
                            let expireTime = loginJson["Response"]["ExpireTime"].doubleValue
                            UserDefaults.standard.do {
                                $0.set(accessToken, forKey: demo_accessToken)
                                $0.set(accessId, forKey: demo_accessId)
                                $0.set(expireTime, forKey: demo_expireTime)
                                $0.set(self?.userNameTF.text ?? "", forKey: demo_userName)
                                $0.set(0, forKey: demo_loginType)
                            }
                            
                            IVNotiPost(.deviceListChange(by: .reload))
                            self?.dismiss(animated: true, completion: nil)
                        }
                    }
                } else {
                    hud.hide()
                }
            }
            
            if regJson["Response"]["NewRegist"].boolValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    login()
                })
            } else {
                login()
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
}
