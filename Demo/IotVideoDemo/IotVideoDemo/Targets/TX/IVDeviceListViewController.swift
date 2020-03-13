//
//  IVDeviceListViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/3/10.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import SwiftyJSON
import IoTVideo.IVMessageMgr

class IVDeviceListViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: .deviceOnline, object: nil, queue: nil) { [weak self](noti) in
            guard let `self` = self else { return }
            self.tableView.reloadData()
        }
    }
            
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UserDefaults.standard.string(forKey: demo_accessTokenKey)?.isEmpty ?? true {
            return
        }
        let hud = ivLoadingHud()
        IVTencentNetwork.shared.deviceList {(json, error) in
            if let error = error {
                hud.hide()
                showError(error)
                return
            }

            guard let json = parseJson(json) else {
                return
            }
             
            var newUserDeviceList: [IVDeviceModel] = []
            if let data = json["Response"]["Data"].array {
                for device in data {
                    let deviceModel = IVDeviceModel(devId: device["Tid"].stringValue,
                                                    deviceName: device["DeviceName"].stringValue,
                                                    shareType: IVDeviceShareType(rawValue: device["Role"].stringValue) ?? .owner)
                    newUserDeviceList.append(deviceModel)
                    
                    IVMessageMgr.sharedInstance.readProperty(ofDevice: deviceModel.devId!, path: "ProReadonly._online") { (json, error) in
                        guard let json = json else { return }
                        deviceModel.online = JSON(parseJSON: json).value("stVal")?.boolValue
                    }
                }
            }
            
            DispatchQueue.main.async {
                userDeviceList = newUserDeviceList
                self.tableView.reloadData()
            }
            
            hud.hide()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dstVC = segue.destination as? IVDeviceAccessable,
            let selectedRow = tableView.indexPathForSelectedRow?.row {
            let dev = userDeviceList[selectedRow]
            dstVC.device = IVDevice(dev)
        }
    }
}

extension IVDeviceListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userDeviceList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IVDeviceCell", for: indexPath) as! IVDeviceCell
        let isOnline = userDeviceList[indexPath.row].online ?? false
        
        cell.deviceIdLabel.text = userDeviceList[indexPath.row].devId
        cell.deviceIdLabel.textColor = isOnline ? UIColor(rgb: 0x3D7AFF) : .black
        cell.onlineLabel.text = isOnline ? "在线" : "离线"
        cell.onlineLabel.textColor = isOnline ? UIColor(rgb: 0x3D7AFF) : .darkGray
        cell.onlineIcon.isHighlighted = isOnline

        return cell
    }
        
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

class IVDeviceCell: UITableViewCell {
    @IBOutlet weak var deviceIdLabel: UILabel!
    @IBOutlet weak var onlineIcon: UIImageView!
    @IBOutlet weak var onlineLabel: UILabel!
}
