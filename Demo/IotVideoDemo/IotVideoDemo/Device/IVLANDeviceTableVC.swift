//
//  IVLANDeviceTableVC.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/12/17.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo.IVNetConfig
import SwiftyJSON

class IVLANDeviceTableVC: UITableViewController {
    
    var dataSource: [IVLANDevice] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = IVNetConfig.lan.getDeviceList()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LANDeviceCell", for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row].deviceID
        cell.detailTextLabel?.text = "局域网"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dev = dataSource[indexPath.row]
        let dstVC = UIStoryboard(name: "IVDeviceMgr", bundle: .main).instantiateInitialViewController() as! IVDeviceAccessable
        dstVC.device = IVDevice(dev)

        if userDeviceList.contains(where: { $0.devId == dev.deviceID }) {
            self.navigationController?.pushViewController(dstVC, animated: true)
        } else {
            let alert = UIAlertController(title: nil, message: "您未拥有该设备，您希望如何操作？", preferredStyle: .alert)
            let ok = UIAlertAction(title: "添加为我的设备", style: .default) { (_) in
                let hud = ivLoadingHud()
                
                IVDemoNetwork.addDevice(dev.deviceID, responseHandler: { (data, error) in
                    hud.hide()
                    if data == nil { return }
                    
                    self.navigationController?.popToRootViewController(animated: true)
                })
            }
            
            let cancel = UIAlertAction(title: "我再想想", style: .cancel, handler: nil)
            let hacking = UIAlertAction(title: "☠️调试开发", style: .destructive) { _ in
                self.navigationController?.pushViewController(dstVC, animated: true)
            }
            alert.addAction(ok)
            alert.addAction(cancel)
            alert.addAction(hacking)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
