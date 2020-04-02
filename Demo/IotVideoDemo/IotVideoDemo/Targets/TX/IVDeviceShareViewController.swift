//
//  IVDeviceShareViewController.swift
//  IotVideoDemo
//
//  Created by zhaoyong on 2020/3/30.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit

class IVDeviceShareViewController: UIViewController, IVDeviceAccessable {
    var device: IVDevice!

    @IBOutlet weak var textView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.becomeFirstResponder()
        // Do any additional setup after loading the view.
    }
    

    @IBAction func shareAction(_ sender: Any) {
        textView.resignFirstResponder()
        IVDemoNetwork.shareDevice(self.device.deviceID, to: textView.text) { (result, error) in
            if result == nil {
                return
            }
            ivHud("分享成功")
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
