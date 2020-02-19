//
//  IVPlayerVC.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/12/18.
//  Copyright © 2019 gwell. All rights reserved.
//

import UIKit
import IVAccountMgr
import IoTVideo.IVMessageMgr

protocol IVDeviceAccessable {
    var device: IVDevice! { get set }
}

class IVDeviceAccessVC: UITableViewController, IVDeviceAccessable {
    var device: IVDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = device.deviceID
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell") ?? UITableViewCell(style: .default, reuseIdentifier: "InfoCell")
            cell.textLabel?.text = """
                            deviceID:     \(device.deviceID)
                            tencentID:    \(device.tencentID)
                            productID:    \(device.productID)
                            deviceName:   \(device.deviceName)
                            serialNumber: \(device.serialNumber)
                            version:      \(device.version)
                            macAddr:      \(device.macAddr)
                            """
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.textColor = .lightGray
            cell.selectionStyle = .none
            
            return cell
        } else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return  UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            break
        case 1:
            break
        case 2:
            if indexPath.row == 1 { //解绑设备
                clickedUnbind()
            }
        case 3:
            
            if indexPath.row == 0 {
//                IVPopupView(title: "物模型获取", input: ["ST._online"], actions: [.cancel(), .confirm({ v in
//                    var inJson = v.inputFields[0].text ?? "ST._online"
//                    if inJson.isEmpty { inJson = "ST._online"}
//
//                    IVMessageMgr.sharedInstance.getDataForDevice(self.device.deviceID, path: inJson, timeout: 0) { (json, err) in
//                        let message = json ?? err?.localizedDescription ?? "[msg]"
//                        showAlert(msg: message)
//                    }
//                })]).show()
                
            } else if indexPath.row == 1 {
//                let popv = IVPopupView(title: "物模型设置", input: ["path", "json"], actions: [.cancel(), .confirm({ v in
//                    let inPath = v.inputFields[0].text ?? ""
//                    let inJson = v.inputFields[1].text ?? ""
//
//                    IVMessageMgr.sharedInstance.setDataToDevice(self.device.deviceID, path: inPath, json: inJson, timeout: 0) { (json, err) in
//                        let message = json ?? err?.localizedDescription ?? "[msg]"
//                        showAlert(msg: message)
//                    }
//                })])
//                popv.inputFields[0].text = "CO._otaVersion"//"SP._cloudStoage.setVal"//"SP._otaMode.setVal"//"CO._otaVersion.ctlVal"//"CO.cameraOn"
//                popv.inputFields[1].text = "{\"ctlVal\":\"\"}"//"1"//"{\"ctlVal\":1}"
//                popv.show()
                
            } else if indexPath.row == 2 {
                IVPopupView(title: "透传数据给设备", input: ["data"], actions: [.cancel(), .confirm({ v in
                    let data = v.inputFields[0].text?.data(using: .utf8) ?? Data()
                    let hud = ivLoadingHud()
                    IVMessageMgr.sharedInstance.sendData(toDevice: self.device.deviceID, data: data, withoutResponse: { (data, err) in
                        hud.hide()
                        let message = data?.string(with: .utf8) ?? err?.localizedDescription ?? "[msg]"
                        showAlert(msg: message)
                    })
                })]).show()
            } else if indexPath.row == 3 {
                IVPopupView(title: "透传数据给服务器", input: ["GET/NetCfg_Token", "data"], actions: [.cancel(), .confirm({ v in
                    var inPath = v.inputFields[0].text ?? "GET/NetCfg_Token"
                    if inPath.isEmpty { inPath = "GET/NetCfg_Token"}

                    let data = v.inputFields[1].text?.data(using: .utf8) ?? Data()
                    let hud = ivLoadingHud()
                    IVMessageMgr.sharedInstance.sendData(toServer: inPath, data: data, timeout: 0) { (data, err) in
                        hud.hide()
                        let message = data?.string(with: .utf8) ?? err?.localizedDescription ?? "[msg]"
                        showAlert(msg: message)
                    }
                })]).show()
            } else if indexPath.row == 4 {
                getPlaybackList(0)
            }
            
        default:
            break
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if var dstVC = segue.destination as? IVDeviceAccessable {
            dstVC.device = device
        }
    }
    
    func clickedUnbind() {
        let unbind = IVPopupAction(title: "解绑", style: .destructive, handler: { _ in
            IVAccountMgr.shared.deleteDevice(deviceId: self.device.tencentID) { (json, error) in
                if let error = error {
                    showAlert(msg: "\(error)")
                    return
                }
                self.navigationController?.popToRootViewController(animated: true)
            }
        })
        IVPopupView(message: "确认解绑设备？", actions: [unbind, .cancel()]).show()
    }
    
    func getPlaybackList(_ pageIndex: UInt) {
        IVPlaybackPlayer.getPlaybackList(ofDevice: device.deviceID, pageIndex: pageIndex, countPerPage: 6, startTime: 0, endTime: Date().timeIntervalSince1970, completionHandler: { page, error in
            logDebug(page as Any, error as Any)

            var actions: [IVPopupAction] = [.confirm()]
            if let page = page, page.pageIndex < page.totalPage - 1 {
                actions.append(IVPopupAction(title: "Next Page", style: .default, handler: { [weak self](v) in
                    self?.getPlaybackList(pageIndex + 1)
                }))
            }
            let msg = page?.description ?? error?.localizedDescription ?? "??"
            
            IVPopupView(title: "回放列表", message: msg, input: nil, actions: actions).show()
        });
    }
}
