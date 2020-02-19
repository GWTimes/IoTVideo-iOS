//
//  IVMsgGetVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2020/1/4.
//  Copyright © 2020 gwell. All rights reserved.
//

import UIKit
import IoTVideo.IVMessageMgr

class IVMsgGetVC: UITableViewController, IVDeviceAccessable {
    var device: IVDevice!
    var dataSource = [[String: AnyHashable]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        let hud = ivLoadingHud()
        IVMessageMgr.sharedInstance.getDataOfDevice(device.deviceID, path: "") { (json, error) in
            hud.hide()
            guard let json = json else {
                let path = Bundle.main.path(forResource: "msgFile", ofType: "json")
                let url = URL(fileURLWithPath: path!)
                let data = try! Data(contentsOf: url)
                self.getDataSource(by: data)
                return
            }
            
            let data = json.data(using: .utf8)!
            self.getDataSource(by: data)
        }
    }
    
    func getDataSource(by data:Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            let jsonData = json as! [String: AnyHashable]
            let keyArray  = [String](jsonData.keys).sorted()
            let canUseKeys = ["ProReadonly", "ProWritable"]
            for key in keyArray {
                if canUseKeys.contains(key) {
                    dataSource.append(["key": key, "value": [String]((jsonData[key] as! [String: AnyHashable]).keys).sorted()])
                }
            }
            tableView.reloadData()
        } catch let error {
            logWarning(error.localizedDescription)
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let subDatas = dataSource[section]["value"] as! [String]
        return subDatas.count
    }
    

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IVMsgGetCell", for: indexPath)
        
        let subDatas = dataSource[indexPath.section]["value"] as! [String]
        cell.textLabel?.text = subDatas[indexPath.row]
        // Configure the cell...

        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
        label.text = dataSource[section]["key"] as? String
        label.textAlignment = .center
        return label
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionKey = dataSource[indexPath.section]["key"] as! String
        let subDatas = dataSource[indexPath.section]["value"] as! [String]
        let subKey = subDatas[indexPath.row]
        let path = sectionKey + "." + subKey
        let hud = ivLoadingHud()
        IVMessageMgr.sharedInstance.getDataOfDevice(self.device.deviceID, path: path) { (json, err) in
            hud.hide()
            let message = "json:\(json ?? "") \n error:\(String(describing: err))"
            logInfo("物模型获取 \n \(path).setVal \n \(message)")
            showAlert(msg: path + "\n" + message)
        }
    }
}
