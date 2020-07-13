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
    
    @IBOutlet weak var addDeviceView: UIView?
    var refresh: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadDeviceList()
        addRefreshControl()
        addObserverForDeviceOnline()
        addObserverForDeviceListChange()
        addLongPressGesture()
    }
    
    /// 加载设备列表
    @objc func loadDeviceList() {
        if UserDefaults.standard.string(forKey: demo_accessToken)?.isEmpty ?? true { return }
        
        let hud = ivLoadingHud()
        
        IVDemoNetwork.deviceList { (data, error) in
            hud.hide()
            guard let data = data else {
                self.refresh.endRefreshing()
                return
            }
            
            DispatchQueue.main.async {
                let list = data as? [IVDeviceModel] ?? []
                userDeviceList = list.map{ IVDevice($0) }
                self.addDeviceView?.isHidden = !userDeviceList.isEmpty
                self.tableView.reloadData()
                hud.hide()
                self.refresh.endRefreshing()
            }
        }
    }
    
    /// 添加下拉刷新
    func addRefreshControl() {
        refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(loadDeviceList), for: .valueChanged)
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refresh
        } else {
            tableView.addSubview(refresh)
        }
    }
    
    
    /// 监听设备在线状态变更
    func addObserverForDeviceOnline() {
        NotificationCenter.default.addObserver(forName: .iVMessageDidUpdateProperty, object: nil, queue: nil) { [weak self](noti) in
            guard let `self` = self else { return }
            guard let propertyModel = noti.userInfo?[IVNotiBody] as? IVUpdateProperty else { return }
            
            if let dev = userDeviceList.first(where: { $0.deviceID == propertyModel.deviceId }),
                let online = JSON(parseJSON: propertyModel.json).ivValue("stVal", property: "_online", path: propertyModel.path) {
                dev.online = online.boolValue
                self.tableView.reloadData()
            }
        }
    }
    
    /// 监听设备列表变化
    func addObserverForDeviceListChange() {
        NotificationCenter.default.addObserver(forName: .ivDeviceListChange, object: nil, queue: nil) { [weak self](noti) in
            guard let `self` = self else { return }
            if noti.userInfo?[IVNotiBody] as? IVDeviceListChangeReason == IVDeviceListChangeReason.delete {
                self.tableView.reloadData()
            } else {
                self.loadDeviceList()
            }
        }
    }
    
    /// 增加长按复制设备ID到剪切板
    func addLongPressGesture() {
        tableView.addLongPressGesture { [unowned self](gesture) in
            if gesture.state == .began {
                let point = gesture.location(in: self.tableView)
                let indexPath = self.tableView.indexPathForRow(at: point)
                guard let cellIndex = indexPath?.row  else { return }
                UIPasteboard.general.string = userDeviceList[cellIndex].deviceID
                ivHud("设备ID已复制")
            }
        }
    }
    
    
    /// 传递设备列表
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dstVC = segue.destination as? IVDeviceAccessable,
            let selectedRow = tableView.indexPathForSelectedRow?.row {
            dstVC.device = userDeviceList[selectedRow]
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension IVDeviceListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userDeviceList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IVDeviceCell", for: indexPath) as! IVDeviceCell
        
        let device = userDeviceList[indexPath.row]
        let isOnline = device.online
        let titleColor = isOnline ? UIColor(rgb: 0x3D7AFF) : .darkGray
        let subColor = isOnline ? UIColor(rgb: 0x3D7AFF) : .darkGray
        
        cell.deviceIdLabel.text = device.deviceID
        cell.deviceIdLabel.textColor = titleColor
        cell.deviceNameLabel.text = device.deviceName
        cell.deviceNameLabel.textColor = titleColor
        cell.onlineLabel.text = isOnline ? "在线" : "离线"
        cell.onlineLabel.textColor = subColor
        cell.onlineIcon.isHighlighted = isOnline
        cell.deviceRoleLabel.text = device.shareType.rawValue
        cell.deviceRoleLabel.textColor = subColor
        
        return cell
    }
        
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 60
//    }
}


class IVDeviceCell: UITableViewCell {
    @IBOutlet weak var deviceIdLabel: UILabel!
    @IBOutlet weak var onlineIcon: UIImageView!
    @IBOutlet weak var onlineLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var deviceRoleLabel: UILabel!
}
