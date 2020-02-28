//
//  IVVASGetPlaybackListVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2020/1/11.
//  Copyright © 2020 gwell. All rights reserved.
//

import UIKit
import IVVAS

class IVVASGetPlaybackListVC: UIViewController, IVDeviceAccessable {
    var device: IVDevice!
    var datePicker: UIDatePicker!
    @IBOutlet weak var endTF: UITextField!
    @IBOutlet weak var beginTF: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var tableview: UITableView!
    var currentTextField: UITextField!
    var dataSource = [IVPalyBackList]()
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker = UIDatePicker()
        datePicker.locale = Locale(identifier: "zh_CN")
        datePicker.addTarget(self, action: #selector(chooseDate(_:)), for: .valueChanged)
        self.beginTF.inputView = datePicker
        self.endTF.inputView = datePicker
        // Do any additional setup after loading the view.
    }
    
    @IBAction func searchList(_ sender: Any) {
        self.currentTextField.resignFirstResponder()
        let begin = UInt32(self.beginTF.text ?? "0")!
        let end = UInt32(self.endTF.text ?? "0")!
        if end < begin {
            ivHud("结束时间不能大于开始时间")
            return
        }
        dataSource = []
        let hud = ivLoadingHud()
        IVVAS.shared.getVideoPlaybackList(deviceId: device.tencentID,
                                          timezone: 28800,
                                          startTime: self.beginTF.text! + "000",
                                          endTime: self.endTF.text! + "000") { (json, error) in
                                            hud.hide()
//                                            showAlert(msg: "\(String(describing: json)) \n \(String(describing: error))")
                                            guard let json = json else {
                                                showAlert(msg: "\(String(describing: error))")
                                                return
                                            }
                                            self.dataSource = json.ivDecode(PlayListData.self)?.palyList ?? []
                                            if self.dataSource.isEmpty {
                                                showAlert(msg: "\(json) \n \(String(describing: error))")
                                            } else {
                                                self.tableview.reloadData()
                                            }
                                        
                                            
        }
    }
    
    @objc func chooseDate(_ sender: UIDatePicker) {
        
        self.currentTextField.text = "\(UInt32(sender.date.timeIntervalSince1970))"
        
        if let b = self.beginTF.text , let e = self.endTF.text, !b.isEmpty, !e.isEmpty {
            self.searchButton.isEnabled = true
        } else {
            self.searchButton.isEnabled = false
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.currentTextField.resignFirstResponder()
    }
}

extension IVVASGetPlaybackListVC: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.currentTextField = textField
        return true;
    }
}

extension IVVASGetPlaybackListVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "IVVASPLAYBACKCELL")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "IVVASPLAYBACKCELL")
        }
        cell?.textLabel?.text = "\(indexPath.row): " + (dataSource[indexPath.row].m3u8Url ?? "")
        return cell!
    }
}

extension IVVASGetPlaybackListVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row <= dataSource.count - 1 else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        ivHud(dataSource[indexPath.row].m3u8Url ?? "")
        let storyboard = UIStoryboard(name: "IVDeviceAccess", bundle: nil)
        let ijk = storyboard.instantiateViewController(withIdentifier: "IJKMediaViewController") as? IJKMediaViewController
        if let ijkVC = ijk {
            ijkVC.device = device
            ijkVC.playbackList = dataSource
            ijkVC.currentItem = dataSource[indexPath.row]
            self.navigationController?.pushViewController(ijkVC, animated: true)
        }
        
    }
}



struct PlayListData: Codable {
    var palyList = [IVPalyBackList]()
}

struct IVPalyBackList: Codable {
    var starttime: Int = 0
    var endtime: Int = 0
    var m3u8Url: String?
}
