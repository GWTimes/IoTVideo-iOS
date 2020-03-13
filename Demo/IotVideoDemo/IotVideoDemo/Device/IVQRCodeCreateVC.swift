//
//  IVQRCodeCreateVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/3.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IVAccountMgr
import IoTVideo

class IVQRCodeCreateVC: UIViewController {

    @IBOutlet weak var didTF: UITextField!
    
    @IBOutlet weak var devNameTF: UITextField!
    @IBOutlet weak var userNameTF: UITextField!
    @IBOutlet weak var QRCodeImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func createQRCode(_ sender: UIButton) {
        view.endEditing(true)
        IVAccountMgr.shared.shareDevieForQRCode(deviceId: didTF.text ?? "", deviceName: devNameTF.text ?? "", userName: userNameTF.text ?? "") { (json, error) in
            self.QRCodeImage.image = IVQRCodeHelper.createQRCode(with: "测试代码", qrSize: self.QRCodeImage.frame.size)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
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
