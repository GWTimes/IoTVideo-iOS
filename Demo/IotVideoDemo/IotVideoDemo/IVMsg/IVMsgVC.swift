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
    
    var refresh: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addProUserProperty)), animated: true)
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        requestNewIoTModel()
        addRefreshControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.enableAutoToolbar = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        IQKeyboardManager.shared.enableAutoToolbar = true
    }
    
    /// 添加下拉刷新
    func addRefreshControl() {
        refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(requestNewIoTModel), for: .valueChanged)
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refresh
        } else {
            tableView.addSubview(refresh)
        }
    }
    
    //获取最新的物模型，根据最新的物模型动态配置
    //开发者拿到的物模型应该是最新且稳定的，可以根据文档设置具体物模型，而无需先获取所有模型
    @objc func requestNewIoTModel() {
        let hud = ivLoadingHud()
        // path 传空则为获取整个物模型
        IVMessageMgr.sharedInstance.readProperty(ofDevice: device.deviceID, path: "") { [self] (json, error) in
            hud.hide()
            DispatchQueue.main.async {[weak self] in
                self?.refresh.endRefreshing()
            }
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
            var datas = [[String: AnyHashable]]()
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            let jsonData = json as! [String: AnyHashable]
            let keyArray  = [String](jsonData.keys).sorted()
            for key in keyArray {
                datas.append(["key": key, "value": [String]((jsonData[key] as! [String: AnyHashable]).keys).sorted()])
            }
            
            dataSource.removeAll()
            dataSource = datas
            
            //提前解出所有数据存储的目的是为了实现操作后里面更新本地数据（编辑操作设置的值将得到保存）
            for data in dataSource {
                let sectionKey = data["key"] as! String
                if sectionKey == "ProUser" { //当能获取到用户物模型相关的内容时，才可以使用新增用户物模型
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
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
    
    /// 新增用户物模型
    /// 新增的 subKey与现有一致 会直接覆盖
    @objc func addProUserProperty() {
        // 添加已有物模型会覆盖原来的内容
        pop = IVPopupView(title: "添加用户物模型 \n ProUser.", message: "属性不能以'_'开头，内容为json格式",input: ["不能以 '_' 开头", "{\"key\":\"value\"}"], actions: [.cancel(), .confirm({ (v) in
            let path = v.inputFields[0].text ?? ""
            let json = v.inputFields[1].text ?? ""
            let hud = ivLoadingHud()
            IVMessageMgr.sharedInstance.addProperty(ofDevice: self.device.deviceID, path: "ProUser.\(path)", json: json) { (json, error) in
                hud.hide()
                logDebug(json, error)
                if error != nil  {
                    let message = "json:\(json ?? "") \n error:\(String(describing: error))"
                    showAlert(msg: path + "\n" + message)
                } else {
                    showAlert(msg: "添加成功")
                    self.requestNewIoTModel()
                }
            }
        })])
        
        pop?.inputFields[0].text = "testProUser"
        pop?.inputFields[0].returnKeyType = .next
        pop?.inputFields[1].text = "{\"key\":\"value\"}"
        pop?.inputFields[1].returnKeyType = .send
        pop?.inputFields[1].delegate = self
        pop?.show()
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
                if msgType == .user_buildIn {
                    // 内置用户物模型编辑
                    self.showBuildInProEdit(with: index)
                    break
                }
                // 显示编辑操作弹窗
                self.showEditPopupView(with: index)
            case .read:
                // 显示查询结果
                self.showReadPropertyView(with: index)
            case .delete:
                // 删除用户自定义的物模型
                self.deleteUserProperty(with: index)
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
            var currentTextDic = detailData[subKey]
            
            //    用户物模型：用户自定义的 例子
            //    "testProUser":{"t":1600048390,"val":{"testKey":"testValue"}}
            //    自定义用户物模型 修改时使用的path为：ProUser.testProUser.val  使用的json 为: {"testKey":"new"}
            if path == "ProUser" { //编辑修改 用户物模型时，取出 val 字段内容
                currentTextDic = (currentTextDic as! [String: AnyHashable])["val"]
            }
            
            let currentTextData = try JSONSerialization.data(withJSONObject: currentTextDic ?? "", options: [])
            currentTextJson = String(data: currentTextData, encoding: .utf8) ?? ""
        } catch let error {
            logWarning(error)
        }
        
        var title = "物模型设置 \n "
        var msgPath = "\(path).\(subKey)"
        
        if path == "ProUser" {
            msgPath = "\(path).\(subKey).val"
        }
        title += msgPath
       
        
        pop = IVPopupView(title: title, input: [currentTextJson], actions: [.cancel(), .confirm({ (v) in
            let inJson = v.inputFields[0].text ?? ""
            let hud = ivLoadingHud()
            if path == "Action" {
                IVMessageMgr.sharedInstance.takeAction(ofDevice: self.device.deviceID, path: msgPath, json: inJson, timeout: 30) { (json, err) in
                    hud.hide()
                    guard err == nil else {
                        let message = "json:\(json ?? "") \n error:\(String(describing: err))"
                        showAlert(msg: path + "\n" + message)
                        return
                    }
                    showAlert(msg: path + "\n" + "设置成功")
                    
                    self.updateInputedJson(inJson, to: subKey)
                }
            } else if path == "ProWritable" || path == "ProUser" {
                IVMessageMgr.sharedInstance.writeProperty(ofDevice: self.device.deviceID, path: msgPath, json: inJson, timeout: 30) { (json, err) in
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
            if let json = json {
                self.updateInputedJson(json, to: subKey)
            }
            
        }
    }
    
    /// 删除用户物模型
    func deleteUserProperty(with index: IndexPath) {
        let sectionKey = self.dataSource[index.section]["key"] as! String
        var subDatas = self.dataSource[index.section]["value"] as! [String]
        let subKey = subDatas[index.row]
        let path = sectionKey + "." + subKey
        pop = IVPopupView(title: "是否删除此物模型", message: path, actions: [.cancel(), .confirm({ (v) in
            let hud = ivLoadingHud()
            IVMessageMgr.sharedInstance.deleteProperty(ofDevice: self.device.deviceID, path: path) { (json, error) in
                hud.hide()
                let msg = "删除物模型 \n" + path + "\n" + (error == nil ? "成功" : String(describing: error))
                logInfo(msg)
                showAlert(msg: msg)
                if error == nil {
                    subDatas.remove(at: index.row)
                    self.dataSource[index.section]["value"] = subDatas
                    self.tableView.reloadData()
                }
            }
        })])
        pop?.show()
    }
    
    //    用户物模型：内置
    //    "_buildIn":{"t":1599731880,"val":{"almEvtPushEna":0,"nickName":"testName"}
    //    内置使用 path: ProUser._buildIn.val.nickName  json: "newTestName"
    func showBuildInProEdit(with index: IndexPath) {
        let subDatas = self.dataSource[index.section]["value"] as! [String]
        let subKey = subDatas[index.row]
        
        let currentTextDic = detailData[subKey]
        let buildInPro = (currentTextDic as! [String: AnyHashable])["val"] as! [String: AnyHashable]
        
        let alertContr = UIAlertController(title: "内置用户物模型", message: nil, preferredStyle: .actionSheet)
        
        alertContr.addAction(UIAlertAction(title: "almEvtNoDisturb", style: .default){
            clickHandler in
            self.editBuildInUserPro(path:"ProUser._buildIn.val.almEvtNoDisturb" , json: buildInPro["almEvtNoDisturb"] as? String ?? "0")
        })
        
        // 字符串需写成 "\"value"\" 形式
        alertContr.addAction(UIAlertAction(title: "nickName", style: .default){
            clickHandler in
            self.editBuildInUserPro(path:"ProUser._buildIn.val.nickName" , json: "\"\(buildInPro["nickName"] as? String ?? "name")\"")
        })
        
        
        alertContr.addAction(UIAlertAction(title: "取消", style: .cancel){
            clickHandler in
            NSLog("点击了取消")
        })
        self.present(alertContr, animated: true, completion: nil)
    }
    
    func editBuildInUserPro(path: String, json: String) {
        self.pop = IVPopupView(title: path, input: [json], actions: [.cancel(), .confirm({ (v) in
            let inJson = v.inputFields[0].text ?? ""
            let hud = ivLoadingHud()
            IVMessageMgr.sharedInstance.writeProperty(ofDevice: self.device.deviceID, path: path, json: inJson, timeout: 30) { (json, err) in
                hud.hide()
                guard err == nil else {
                    let message = "json:\(json ?? "") \n error:\(String(describing: err))"
                    showAlert(msg: path + "\n" + message)
                    return
                }
                showAlert(msg: path + "\n" + "设置成功")
            }
        })])
        self.pop?.inputFields[0].text = json
        // 设置确定按钮为 发送
        self.pop?.inputFields[0].returnKeyType = .send
        // 转移代理至此，方便处理 发送按钮
        self.pop?.inputFields[0].delegate = self
        self.pop?.show()
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
        case user      = "ProUser"
        case user_buildIn = "ProUser._"
    }
    
    /// cell 操作模式
    enum IVMsgCellSenderType {
        /// 编辑
        case edit
        /// 查看
        case read
        /// 删除
        case delete
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    var sectionName: String! {
        didSet {
            msgType = IVMsgType(rawValue: sectionName) ?? .read
            if msgType == .user && nameLabel.text?.hasPrefix("_") ?? false {
                msgType = .user_buildIn
            }
        }
    }
    private var msgType: IVMsgType = .read {
        didSet {
            switch msgType {
            case .read, .const:
                actionButton.isHidden = true
                getButton.isHidden = false
                deleteButton.isHidden = true
            case .action:
                actionButton.isHidden = false
                getButton.isHidden = true
                deleteButton.isHidden = true
            case .readWrite, .user_buildIn:
                actionButton.isHidden = false
                getButton.isHidden = false
                deleteButton.isHidden = true
            case .user:
                actionButton.isHidden = false
                getButton.isHidden = false
                deleteButton.isHidden = false
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
    
    @IBAction func deleteSender(_ sender: Any) {
        actionBegin?(self.indexPath, msgType, .delete)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}


