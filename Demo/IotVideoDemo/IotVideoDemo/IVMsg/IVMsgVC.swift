//
//  IVMsgVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2020/1/4.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo.IVMessageMgr
import IQKeyboardManagerSwift

class IVMsgVC: UITableViewController, IVDeviceAccessable {
    var device: IVDevice!
    var dataSource = [[String: AnyHashable]]()
    var jsonData = [String: AnyHashable]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestNewIoTModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.enableAutoToolbar = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        IQKeyboardManager.shared.enableAutoToolbar = true
    }
    
    //获取最新的物模型，根据最新的物模型动态配置
    //开发者拿到的物模型应该是最新且稳定的，可以根据文档设置具体物模型，而无需先获取所有模型
    func requestNewIoTModel() {
        let hud = ivLoadingHud()
        IVMessageMgr.sharedInstance.readProperty(ofDevice: device.deviceID, path: "") { (json, error) in
            hud.hide()
            guard let json = json else {
                ivHud(error?.localizedDescription)
                return
            }
            
            let data = json.data(using: .utf8)!
            self.getDataSource(by: data)
        }
    }
    
    //解析对应数据
    func getDataSource(by data:Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            jsonData = json as! [String: AnyHashable]
            let keyArray  = [String](jsonData.keys).sorted()
            //            let canUseKeys = ["ProReadonly", "Action", "ProWritable"]
            for key in keyArray {
                //                if canUseKeys.contains(key) {
                dataSource.append(["key": key, "value": [String]((jsonData[key] as! [String: AnyHashable]).keys).sorted()])
                //                }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "IVMsgCellID", for: indexPath) as! IVMsgCell
        // Configure the cell...

        
        let subDatas = dataSource[indexPath.section]["value"] as! [String]
        cell.nameLabel.text = subDatas[indexPath.row]
        cell.indexPath = indexPath
        cell.sectionName = dataSource[indexPath.section]["key"] as? String
        
        cell.actionBegin = { index, actionType in
            switch actionType {
            case .action: do {
                let sectionKey = self.dataSource[index.section]["key"] as! String
                let subDatas = self.dataSource[index.section]["value"] as! [String]
                let subKey = subDatas[index.row]
                let path = sectionKey
                var currentTextJson = "";
                do {
                    let currentTextDic = (self.jsonData[sectionKey] as! [String: AnyHashable])[subKey] as! [String: AnyHashable]
                    let currentTextData = try JSONSerialization.data(withJSONObject: currentTextDic, options: [])
                    currentTextJson = String(data: currentTextData, encoding: .utf8) ?? ""
                } catch let error {
                    logWarning(error)
                }
                
                
                let pop = IVPopupView(title: "物模型设置 \n \(path).\(subKey) ", input: [currentTextJson], actions: [.cancel(), .confirm({ (v) in
                    let inJson = v.inputFields[0].text ?? ""
                    let hud = ivLoadingHud()
                    if path == "Action" {
                        IVMessageMgr.sharedInstance.takeAction(ofDevice: self.device.deviceID, path: "\(path).\(subKey)", json: inJson, timeout: 30) { (json, err) in
                            hud.hide()
                            guard err == nil else {
                                let message = "json:\(json ?? "") \n error:\(String(describing: err))"
                                showAlert(msg: path + "\n" + message)
                                return
                            }
                            showAlert(msg: path + "\n" + "设置成功")
                        }
                    } else if path == "ProWritable" {
                        IVMessageMgr.sharedInstance.writeProperty(ofDevice: self.device.deviceID, path: "\(path).\(subKey)", json: inJson, timeout: 30) { (json, err) in
                            hud.hide()
                            guard err == nil else {
                                let message = "json:\(json ?? "") \n error:\(String(describing: err))"
                                showAlert(msg: path + "\n" + message)
                                return
                            }
                            showAlert(msg: path + "\n" + "设置成功")
                        }
                    }
                })])
                pop.inputFields[0].text = currentTextJson
                pop.show()
                }
            default: do {
                let sectionKey = self.dataSource[index.section]["key"] as! String
                let subDatas = self.dataSource[index.section]["value"] as! [String]
                let subKey = subDatas[indexPath.row]
                let path = sectionKey + "." + subKey
                let hud = ivLoadingHud()
                IVMessageMgr.sharedInstance.readProperty(ofDevice: self.device.deviceID, path: path) { (json, err) in
                    hud.hide()
                    let message = "json:\(json ?? "") \n error:\(String(describing: err))"
                    logInfo("物模型获取 \n \(path) \n \(message)")
                    showAlert(msg: path + "\n" + message)
                }
                }
            }
        }
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
    }
}

class IVMsgCell: UITableViewCell {
    
    typealias ActionBeginClosure = (_ indexPaht: IndexPath, _ type: IVMsgActionType) -> Void
   
    enum IVMsgActionType: String {
        case const     = "ProConst"
        case read      = "ProReadonly"
        case action    = "Action"
        case readWrite = "ProWritable"
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    var sectionName: String! {
        didSet {
            actionType = IVMsgActionType(rawValue: sectionName) ?? .read
        }
    }
    private var actionType: IVMsgActionType = .read {
        didSet {
            switch actionType {
            case .read,.const:
                actionButton.isHidden = true
                getButton.isHidden = false
            case .action:
                actionButton.isHidden = false
                getButton.isHidden = true
            case .readWrite:
                actionButton.isHidden = false
                getButton.isHidden = false
            }
        }
    }
    var indexPath: IndexPath!
    var actionBegin: ActionBeginClosure?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func actionSender(_ sender: Any) {
        actionBegin?(self.indexPath, .action)
    }
    
    @IBAction func getSender(_ sender: Any) {
        actionBegin?(self.indexPath, .read)
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
