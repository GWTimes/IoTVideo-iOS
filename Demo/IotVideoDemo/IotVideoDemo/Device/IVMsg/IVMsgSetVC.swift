//
//  IVMsgSetVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2020/1/4.
//  Copyright © 2020 gwell. All rights reserved.
//

import UIKit
import IoTVideo.IVMessageMgr

class IVMsgSetVC: UITableViewController, IVDeviceAccessable {
    var device: IVDevice!
    
    var dataSource = [[String: AnyHashable]]()
    var jsonData = [String: AnyHashable]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let hud = ivLoadingHud()
        IVMessageMgr.sharedInstance.readProperty(ofDevice: device.deviceID, path: "") { (json, error) in
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
            jsonData = json as! [String: AnyHashable]
            let keyArray  = [String](jsonData.keys).sorted()
            let canUseKeys = ["Action", "ProWritable"]
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
        // #warning Incomplete implementation, return the number of sections
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let subDatas = dataSource[section]["value"] as! [String]
        return subDatas.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IVMsgSetCell", for: indexPath)
        
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
        let path = sectionKey
        var currentTextJson = "";
        do {
            let currentTextDic = (jsonData[sectionKey] as! [String: AnyHashable])[subKey] as! [String: AnyHashable]
            let currentTextData = try JSONSerialization.data(withJSONObject: currentTextDic, options: [])
            currentTextJson = String(data: currentTextData, encoding: .utf8) ?? ""
        } catch let error {
            logWarning(error)
        }
        
       
        let pop = IVPopupView(title: "物模型设置 \n \(path).\(subKey) ", input: [currentTextJson], actions: [.cancel(), .confirm({ (v) in
            let inJson = v.inputFields[0].text ?? ""
            let hud = ivLoadingHud()
            IVMessageMgr.sharedInstance.writeProperty(ofDevice: self.device.deviceID, path: "\(path).\(subKey)", json: inJson, timeout: 30) { (json, err) in
                hud.hide()
                let message = "json:\(json ?? "") \n error:\(String(describing: err))"
                showAlert(msg: path + "\n" + message)
            }
        })])
        pop.inputFields[0].text = currentTextJson
        pop.show()
        /*
        if sectionKey == "Action" {
            let pop = IVPopupView(title: "物模型设置 \n \(path)", input: ["json"], actions: [.cancel(), .confirm({ v in
                var inJson = v.inputFields[0].text ?? ""
                
                if subKey == "_otaVersion" {
                    inJson = "\"\(inJson)\""
                }
                let hud = ivLoadingHud()
                IVMessageMgr.sharedInstance.setDataToDevice(self.device.deviceID, path: (path + ".ctlVal"), json: inJson, timeout: 30) { (json, err) in
                    hud.hide()
                    let message = "json:\(json ?? "") \n error:\(String(describing: err))"
                    logInfo("物模型设置 \n \(path).setVal \n \(message)")
                    showAlert(msg: path + "\n" + message)
                }
            })])
            pop.inputFields[0].text = "1"
            pop.show()
        }
        
        if sectionKey == "ProWritable" {
            let canUseSubKeys = ["_otaMode", "_logLevel", "_cloudStoage"]
            if canUseSubKeys.contains(subKey) {
                let pop = IVPopupView(title: "物模型设置 \n \(path).setVal", input: ["json"], actions: [.cancel(), .confirm({ v in
                    let inJson = v.inputFields[0].text ?? ""
                    let hud = ivLoadingHud()
                    IVMessageMgr.sharedInstance.setDataToDevice(self.device.deviceID, path: (path + ".setVal"), json: inJson, timeout: 30) { (json, err) in
                        hud.hide()
                        let message = "json: \(json ?? "") \n error:\(String(describing: err))"
                        logInfo("物模型设置 \n \(path).setVal \n \(message)")
                        showAlert(msg: path + "\n" + message)
                    }
                })])
                pop.inputFields[0].text = "1"
                pop.show()
            }
        }
 */
    }
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
