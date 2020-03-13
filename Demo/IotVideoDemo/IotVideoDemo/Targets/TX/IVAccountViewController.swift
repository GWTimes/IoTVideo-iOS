//
//  IVAccountViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/3/11.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo

class IVAccountViewController: UITableViewController {
        
    let accountInfo = [
        "userName" : UserDefaults.standard.string(forKey: demo_userName) ?? "(空)",
        "accessID" : IoTVideo.sharedInstance.accessId ?? "(空)",
        "terminalID" : IoTVideo.sharedInstance.terminalId ?? "(空)",
        "accessToken" : IoTVideo.sharedInstance.accessToken ?? "(空)",
        "secretKey" : IVTencentNetwork.shared.secretKey,
        "secretID" : IVTencentNetwork.shared.secretId,
        "Token" : IVTencentNetwork.shared.token
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func copyAccountInfo(_ sender: Any) {
        let copyStr = accountInfo.description.replacingOccurrences(of: ",", with: ",\n")
        UIPasteboard.general.string = copyStr
        IVPopupView(title: "已复制到剪贴板", message: copyStr, input: nil, actions: [.iKnow()]).show()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let key = cell.textLabel?.text {
            cell.detailTextLabel?.text = accountInfo[key]
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0.01 : UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let cell = tableView.cellForRow(at: indexPath)
            let pasteboard = UIPasteboard.general
            pasteboard.string = cell?.detailTextLabel?.text
            ivHud("\(cell!.textLabel!.text!) 已复制")
        } else {
            DispatchQueue.global().async {
                IoTVideo.sharedInstance.unregister()
            }
            UserDefaults.standard.do {
                $0.removeObject(forKey: demo_accessTokenKey)
                $0.removeObject(forKey: demo_accessIdKey)
                $0.removeObject(forKey: demo_expireTimeKey)
            }
            let board = UIStoryboard(name: "IVLogin", bundle: nil)
            let loginVC = board.instantiateViewController(withIdentifier: "LogNav") as! UINavigationController
            loginVC.modalPresentationStyle = .fullScreen
            topVC()?.present(loginVC, animated: true, completion: nil)
            self.navigationController?.popToRootViewController(animated: false)
        }
    }
}
