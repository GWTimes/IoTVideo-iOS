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
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = IVNetConfig.lan.getDeviceList()
        timer = Timer.iv_scheduledTimer(withTimeInterval: 2.0, repeats: true, block: { [weak self](tim) in
            self?.dataSource = IVNetConfig.lan.getDeviceList()
            self?.tableView.reloadData()
        })
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timer.fireDate = .distantPast
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer.fireDate = .distantFuture
    }
    
    deinit {
        timer.invalidate()
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
        tableView.deselectRow(at: indexPath, animated: true)
        
        let dev = dataSource[indexPath.row]
        let dstVC = UIStoryboard(name: "IVDeviceMgr", bundle: .main).instantiateInitialViewController() as! IVDeviceAccessable
        dstVC.device = IVDevice(dev)

        if userDeviceList.contains(where: { $0.deviceID == dev.deviceID }) {
            self.navigationController?.pushViewController(dstVC, animated: true)
        } else {
            let alert = UIAlertController(title: nil, message: "您未拥有该设备，您希望如何操作？", preferredStyle: .alert)
            let bind = UIAlertAction(title: "普通绑定", style: .default) { (_) in
                let hud = ivLoadingHud()
                
                IVDemoNetwork.addDevice(dev.deviceID, forceBind: false, options: dev.reserve, responseHandler: { (data, error) in
                    hud.hide()
                    if data == nil { return }
                    IVNotiPost(.deviceListChange(by: .add))
                    self.backToDeviceList()
                })
            }
            
            let forseBind = UIAlertAction(title: "强制绑定（踢掉原主人）", style: .default) { (_) in
                let hud = ivLoadingHud()
                IVDemoNetwork.addDevice(dev.deviceID, forceBind: true, options: dev.reserve, responseHandler: { (data, error) in
                    hud.hide()
                    if data == nil { return }
                    IVNotiPost(.deviceListChange(by: .add))
                    self.backToDeviceList()
                })
            }
            
            let share = UIAlertAction(title: "分享该设备", style: .default) { _ in
                let hud = ivLoadingHud()
                
                IVDemoNetwork.addDevice(dev.deviceID, role: .guest, forceBind: true, options: dev.reserve, responseHandler: { (data, error) in
                    hud.hide()
                    if data == nil { return }
                    IVNotiPost(.deviceListChange(by: .add))
                    self.backToDeviceList()
                })
            }
            
            let cancel = UIAlertAction(title: "我再想想", style: .cancel, handler: nil)
            let debug = UIAlertAction(title: "☠️调试开发", style: .destructive) { _ in
                self.navigationController?.pushViewController(dstVC, animated: true)
            }
            
            alert.addAction(bind)
            alert.addAction(forseBind)
            alert.addAction(share)
            alert.addAction(cancel)
            alert.addAction(debug)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func backToDeviceList() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
}
