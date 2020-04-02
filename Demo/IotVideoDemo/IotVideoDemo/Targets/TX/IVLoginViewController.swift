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

class IVLoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var tmpSecretIDTF: UITextField!
    @IBOutlet weak var tmpSecretKeyTF: UITextField!
    @IBOutlet weak var tokenTF: UITextField!
    @IBOutlet weak var userNameTF: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let window = (UIApplication.shared.delegate as! AppDelegate).window
        window?.addSubview(devToolsAssistant)
        window?.bringSubviewToFront(devToolsAssistant)
        
    }

    @IBAction func loginBtnClicked(_ sender: UIButton) {
        let hud = ivLoadingHud(isMask: true)
        IVTencentNetwork.shared.register(tmpSecretID: tmpSecretIDTF.text ?? "", tmpSecretKey: tmpSecretKeyTF.text ?? "", token: tokenTF.text ?? " ", userName: userNameTF.text ?? " ") { [weak self](regJson, error) in

            guard let regJson = IVDemoNetwork.handlerError(regJson, error) else {
                hud.hide()
                return
            }
            
            let login = {
                if regJson["Response"]["CunionId"].string == self?.userNameTF.text, let accessId = regJson["Response"]["AccessId"].string {
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
                            }
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

