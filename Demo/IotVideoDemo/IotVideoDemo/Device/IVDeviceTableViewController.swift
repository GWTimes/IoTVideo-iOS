//
//  IVDeviceTableViewController.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/18.
//  Copyright © 2019 gwell. All rights reserved.
//

import UIKit
import IoTVideo
import IVAccountMgr
import SwiftyJSON
import IVVAS

class IVDeviceTableViewController: UITableViewController {
    
    static var mineDevice: [IVDeviceModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return super.numberOfSections(in: tableView)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return super.tableView(tableView, numberOfRowsInSection: section)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if IoTVideo.sharedInstance.accessToken?.isEmpty ?? true {
            return
        }
        let hud = ivLoadingHud()
        if IoTVideo.sharedInstance.accessToken != nil {
            IVAccountMgr.shared.deviceList { (json, error) in
                hud.hide()
                if let error = error {
                    showError(error)
                    return
                }
                IVDeviceTableViewController.mineDevice = json!.ivArrayDecode(IVDeviceModel.self) as! [IVDeviceModel]
                IVDeviceTableViewController.mineDevice.forEach { (dev) in
                    guard let deviceId = dev.did else { return }
                    IVMessageMgr.sharedInstance.readProperty(ofDevice: deviceId, path: "ProReadonly._online") { (json, error) in
                        guard let json = json else { return }
                        dev.online = JSON(parseJSON: json).value("stVal")?.boolValue
                    }
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 3  && indexPath.row == 0 {
            IVVAS.shared.testP2PRequest { (json, error) in
                IVLog.logInfo("\(String(describing: json)),\(String(describing: error))")
                showAlert(msg: "\(String(describing: json)),\(String(describing: error))")
            }
        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let segueId = segue.identifier {
            if segueId == "IVMineDeviceTableVC" {
                let vc = segue.destination as! IVMineDeviceTableVC
                vc.dataSource = IVDeviceTableViewController.mineDevice
            } else if segueId == "IVLANDeviceTableVC" {
                let vc = segue.destination as! IVLANDeviceTableVC
                vc.mineDeviceId = IVDeviceTableViewController.mineDevice.compactMap{$0.devId}
            }
        }
    }
}
