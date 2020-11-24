//
//  IVCloudStorageBuyPkgViewController.swift
//  IotVideoDemo
//
//  Created by zhaoyong on 2020/10/28.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit

class IVCloudStorageBuyPkgViewController: IVDeviceAccessableTVC {
    let pkgs = IVDemoNetwork.cloudStoragePkgs
    var keys = [String]()
    var values = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        keys = Array(pkgs.keys).sorted(by: >)
        for key in keys {
            values.append(pkgs[key] ?? "need fix bug")
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pkgs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "reuseIdentifier")
        }
        cell!.textLabel?.text =  values[indexPath.row]
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        IVPopupView(title: "您确定购买此云存套餐吗？", message:values[indexPath.row], input: nil, actions: [.cancel(), .confirm({ (_) in
            let hud = ivLoadingHud()
            IVDemoNetwork.buyCloudStoragePackage(self.keys[indexPath.row], deviceId: self.device.deviceID) { (data, err) in
                hud.hide()
                guard let _ = data else {
                    return
                }
                ivHud("购买成功")
            }
        })]).show()
    }
}
