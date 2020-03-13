//
//  IVSharedListVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2020/1/7.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IVAccountMgr
import SwiftyJSON
class IVSharedListVC: UITableViewController, IVDeviceAccessable {
    var device: IVDevice!
    var dataSource: [String]?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        let hud = ivLoadingHud()
        IVAccountMgr.shared.deviceList { (json, error) in
            if let error = error {
                hud.hide()
                showError(error)
                return
            }
            let devices: [IVDeviceModel] = json!.ivArrayDecode(IVDeviceModel.self) as! [IVDeviceModel]
            var find = false
            var has = false
            devices.forEach { (model) in
                if model.devId == self.device.deviceID {
                    if model.shareType == .owner  {
                        find = true
                    }
                    has = true
                }
            }
            
            if !has {
                hud.hide()
                showAlert(msg: "非法设备，请刷新重试")
                return
            }
            
            if has && !find {
                hud.hide()
                showAlert(msg: "非设备主人")
                return
            }
            IVAccountMgr.shared.getVisitorList(deviceId: self.device.deviceID) { (json, error) in
                hud.hide()
                guard let json = json else {
                    showError(error!)
                    return
                }
                self.dataSource = JSON(parseJSON: json)["data"]["users"].arrayValue.map{$0["ivUid"].stringValue}
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.dataSource?.count ?? 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IVSharedCell", for: indexPath)
        cell.textLabel?.text = self.dataSource?[indexPath.row]
        // Configure the cell...
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        IVPopupView(title: "取消分享", message: "取消此设备对该用户的分享", input: nil, actions: [.cancel(),.confirm({v in
            let hud = ivLoadingHud()
            IVAccountMgr.shared.cancelSharing(deviceId: self.device!.deviceID, accountId: self.dataSource![indexPath.row], responseHandler: { (json, error) in
                hud.hide()
                if let error = error {
                    showError(error)
                    return
                }
                ivHud("取消成功")
            })
        })]).show()
    }
}
