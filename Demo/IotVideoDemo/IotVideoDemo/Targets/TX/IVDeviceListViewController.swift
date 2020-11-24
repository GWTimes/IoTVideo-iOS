//
//  IVDeviceListViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/3/10.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import SwiftyJSON
import IoTVideo

class IVDeviceListViewController: UITableViewController {
    
    @IBOutlet weak var addDeviceView: UIView?
    var refresh: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = using_test_web_host ? "设备列表(测试服)" : "用户设备列表"
        addDeviceView?.isHidden = false
        addRefreshControl()
        loadDeviceList()
        addObserverForDeviceOnline()
        addObserverForDeviceListChange()
        addLongPressGesture()
    }
    
    /// 加载设备列表
    @objc func loadDeviceList() {
        if UserDefaults.standard.string(forKey: demo_accessToken)?.isEmpty ?? true { return }
        
        let hud = ivLoadingHud()
        
        if let expireTime = UserDefaults.standard.value(forKey:  demo_expireTime) as? Int {
            if Int(Date().timeIntervalSince1970) > expireTime {
                if let nav = self.navigationController as? IVNavigationViewController {
                    nav.jumpToLoginView()
                }
            }
        }
        
        // 匿名Token 登录
        if let loginType = UserDefaults.standard.value(forKey: demo_loginType) as? Int, loginType == 1, let tid = UserDefaults.standard.value(forKey: demo_AnonymousDev) as? String {
            
            addDeviceView?.isHidden = true
            
            let deviceModel = IVDeviceModel(devId: tid, deviceName: "匿名设备", shareType: .guest)
            
            IVMessageMgr.sharedInstance.readProperty(ofDevice: deviceModel.devId!, path: "ProReadonly._online") { (json, error) in
                if let json = json {
                    deviceModel.online = JSON(parseJSON: json)["stVal"].intValue
                }
                userDeviceList = [IVDevice(deviceModel)]
                DispatchQueue.main.async {
                    self.addDeviceView?.isHidden = !userDeviceList.isEmpty
                    self.tableView.reloadData()
                    hud.hide()
                    self.refresh.endRefreshing()
                }
            }
            return
        }
        
        // 正常登录
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
                dev.online = online.intValue
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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "addDevice" {
            if let loginType = UserDefaults.standard.value(forKey: demo_loginType) as? Int, loginType == 1 {
                return false
            }
        }
        return true 
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
        let color: UIColor = (device.online == 1 ? UIColor(rgb: 0x3D7AFF) : (device.online == 2 ? .orange : .darkGray))
        
        cell.deviceIdLabel.text = device.deviceID
        cell.deviceIdLabel.textColor = color
        cell.deviceNameLabel.text = device.deviceName
        cell.deviceNameLabel.textColor = color
        cell.onlineLabel.text = (device.online == 1 ? "在线" : (device.online == 2 ? "休眠" : "离线"))
        cell.onlineLabel.textColor = color
        cell.onlineIcon.isHighlighted = (device.online == 1)
        cell.deviceRoleLabel.text = device.shareType.rawValue
        cell.deviceRoleLabel.textColor = color
        
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
