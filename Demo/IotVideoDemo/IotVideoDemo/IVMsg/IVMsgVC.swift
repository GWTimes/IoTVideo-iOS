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
    // 存储 section 和对应的操作 path
    var dataSource = [[String: AnyHashable]]()
    // 具体path对应的内容
    var detailData = [String: AnyHashable]()
    
    var pop: IVPopupView?
    
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
        // path 传空则为获取整个物模型
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
            let jsonData = json as! [String: AnyHashable]
            let keyArray  = [String](jsonData.keys).sorted()
            for key in keyArray {
                dataSource.append(["key": key, "value": [String]((jsonData[key] as! [String: AnyHashable]).keys).sorted()])
            }
        
            //提前解出所有数据存储的目的是为了实现操作后里面更新本地数据（编辑操作设置的值将得到保存）
            for data in dataSource {
                let sectionKey = data["key"] as! String
                let subKeys = data["value"] as! [String]
                for subKey in subKeys {
                    detailData[subKey] = (jsonData[sectionKey] as! [String: AnyHashable])[subKey] as? [String: AnyHashable]
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "IVMsgCellID", for: indexPath) as! IVMsgCell
        
        // Configure the cell...
        let subDatas = dataSource[indexPath.section]["value"] as! [String]
        cell.nameLabel.text = subDatas[indexPath.row]
        cell.indexPath = indexPath
        cell.sectionName = dataSource[indexPath.section]["key"] as? String
        
        // cell 按钮点击事件
        cell.actionBegin = { index, msgType, senderType in
            switch senderType {
            case .edit:
                // 显示编辑操作弹窗
                self.showEditPopupView(with: index)
            case .read:
                // 显示查询结果
                self.showReadPropertyView(with: index)
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

//MARK: 物模型操作
extension IVMsgVC {
    // 编辑弹窗
    func showEditPopupView(with index: IndexPath) {
        
        let sectionKey = self.dataSource[index.section]["key"] as! String
        let subDatas = self.dataSource[index.section]["value"] as! [String]
        let subKey = subDatas[index.row]
        let path = sectionKey
        var currentTextJson = "";
        do { // 读取当前操作内容并转成 string
            let currentTextDic = detailData[subKey]
            let currentTextData = try JSONSerialization.data(withJSONObject: currentTextDic ?? "", options: [])
            currentTextJson = String(data: currentTextData, encoding: .utf8) ?? ""
        } catch let error {
            logWarning(error)
        }
        
        pop = IVPopupView(title: "物模型设置 \n \(path).\(subKey) ", input: [currentTextJson], actions: [.cancel(), .confirm({ (v) in
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
                    
                    self.updateInputedJson(inJson, to: subKey)
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
                    
                    self.updateInputedJson(inJson, to: subKey)
                }
            }
        })])
        pop?.inputFields[0].text = currentTextJson
        // 设置确定按钮为 发送
        pop?.inputFields[0].returnKeyType = .send
        // 转移代理至此，方便处理 发送按钮
        pop?.inputFields[0].delegate = self
        pop?.show()
    }
    
    /// 显示查询结果
    func showReadPropertyView(with index: IndexPath) {
        let sectionKey = self.dataSource[index.section]["key"] as! String
        let subDatas = self.dataSource[index.section]["value"] as! [String]
        let subKey = subDatas[index.row]
        let path = sectionKey + "." + subKey
        let hud = ivLoadingHud()
        IVMessageMgr.sharedInstance.readProperty(ofDevice: self.device.deviceID, path: path) { (json, err) in
            hud.hide()
            let message = "json:\(json ?? "") \n error:\(String(describing: err))"
            logInfo("物模型获取 \n \(path) \n \(message)")
            showAlert(msg: path + "\n" + message)
        }
    }
    
    /// 更新本地json
    func updateInputedJson(_ inJson: String, to subKey: String) {
        do {
            let data = inJson.data(using: .utf8)!
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            let newCurrentJsonDic = json as! [String: AnyHashable]
            self.detailData[subKey] = newCurrentJsonDic
        } catch let error {
            logWarning(error)
        }
    }
}

//MARK: UITextFieldDelegate 发送事件处理
extension IVMsgVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let btn = pop?.actions.first(where: {$0.title(for: .normal) == "确定"}) {
            btn.sendActions(for: .touchUpInside)
        }
        textField.resignFirstResponder()
        return true
    }
}

//MARK: IVMsgCell
class IVMsgCell: UITableViewCell {
    
    typealias ActionBeginClosure = (_ indexPaht: IndexPath, _ msgType: IVMsgType, _ senderType: IVMsgCellSenderType) -> Void
   
    enum IVMsgType: String {
        case const     = "ProConst"
        case read      = "ProReadonly"
        case action    = "Action"
        case readWrite = "ProWritable"
    }
    
    /// cell 操作模式
    enum IVMsgCellSenderType {
        /// 编辑
        case edit
        /// 查看
        case read
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    var sectionName: String! {
        didSet {
            msgType = IVMsgType(rawValue: sectionName) ?? .read
        }
    }
    private var msgType: IVMsgType = .read {
        didSet {
            switch msgType {
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
        actionBegin?(self.indexPath, msgType, .edit)
    }
    
    @IBAction func getSender(_ sender: Any) {
        actionBegin?(self.indexPath, msgType, .read)
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}


