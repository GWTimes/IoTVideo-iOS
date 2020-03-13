//
//  IVVASBuyVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2020/1/11.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IVVAS

class IVVASBuyVC: UIViewController, IVDeviceAccessable{
    var device: IVDevice!
    
    @IBOutlet weak var beginTF: UITextField!
    @IBOutlet weak var endTF: UITextField!
    var datePicker: UIDatePicker!
    @IBOutlet weak var buyButton: UIButton!
    var chooseType: IVVASServiceType = .vss
    var currentTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker = UIDatePicker()
        datePicker.locale = Locale(identifier: "zh_CN")
        datePicker.addTarget(self, action: #selector(chooseDate(_:)), for: .valueChanged)
        self.beginTF.inputView = datePicker
        self.endTF.inputView = datePicker
        // Do any additional setup after loading the view.
    }
    
    @IBAction func chooseType(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            chooseType = .vss
        case 1:
            chooseType = .evs
        default:
            chooseType = .vss
        }
    }
    
    @objc func chooseDate(_ sender: UIDatePicker) {
        self.currentTextField?.text = "\(UInt32(sender.date.timeIntervalSince1970))"
        
        if let b = self.beginTF.text , let e = self.endTF.text, !b.isEmpty, !e.isEmpty {
            self.buyButton.isEnabled = true
        } else {
            self.buyButton.isEnabled = false
        }
    }
    
    @IBAction func buyAction(_ sender: Any) {
        self.currentTextField.resignFirstResponder()
        let begin = UInt32(self.beginTF.text ?? "0")!
        let end = UInt32(self.endTF.text ?? "0")!
        if end < begin {
            ivHud("服务结束时间不能大于开始时间")
            return
        }
        let len = end - begin;
        let hud = ivLoadingHud()
        IVVAS.shared.buyCloudPackage(deviceId: device.deviceID, packgageId: "yc1m3d", type: self.chooseType, startTime: self.beginTF.text!, endTime: self.endTF.text!, storageLen: "\(len)") { (json, error) in
            hud.hide()
             showAlert(msg: "\(String(describing: json)) \n \(String(describing: error))")
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.currentTextField?.resignFirstResponder()
    }
}

extension IVVASBuyVC: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.currentTextField = textField
        return true
    }
}
