//
//  IVMineDeviceTableVC.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/12/18.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IVAccountMgr
import IoTVideo

class IVMineDeviceTableVC: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let type = IoTVideo.sharedInstance.options?[IVOptionKey.hostType] as? String {
            self.title = type == "0" ? "我的设备（测试服）" : "我的设备（正式服）"
        }
        
        NotificationCenter.default.addObserver(forName: .deviceOnline, object: nil, queue: nil) { [weak self](noti) in
            guard let `self` = self else { return }
            self.tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return userDeviceList.count;
    }

  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MineDeviceCell", for: indexPath)
        cell.textLabel?.text = userDeviceList[indexPath.row].devId
        let isOnline = (userDeviceList[indexPath.row].online == true)
        cell.imageView?.image = UIImage(named: isOnline ? "tabBar_icon_device_S" : "tabBar_icon_device_N")
        cell.textLabel?.textColor = isOnline ? #colorLiteral(red: 0, green: 0.4141984238, blue: 0.9501903553, alpha: 1) : #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        cell.detailTextLabel?.textColor = isOnline ? #colorLiteral(red: 0, green: 0.4141984238, blue: 0.9501903553, alpha: 1) : #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)

        return cell
    }
   
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dstVC = segue.destination as? IVDeviceMgrViewController,
            let selectedRow = tableView.indexPathForSelectedRow?.row {
            let dev = userDeviceList[selectedRow]
            dstVC.device = IVDevice(dev)
        }
    }
}



