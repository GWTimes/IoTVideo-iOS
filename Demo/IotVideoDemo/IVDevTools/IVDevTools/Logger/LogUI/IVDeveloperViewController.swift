//
//  IVDeveloperViewController.swift
//  IVLogger
//
//  Created by JonorZhang on 2019/9/6.
//  Copyright © 2019 JonorZhang. All rights reserved.
//

import UIKit

func makeToast(_ msg: String) {
    let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
    IVDevToolsAssistant.shared.developerVC.present(alert, animated: true)
    DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: {
        alert.dismiss(animated: true)
    })
}

class IVDeveloperViewController: UITableViewController {
      
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "最小化", style: .plain, target: self, action: #selector(closeClicked))
    }
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if cell?.reuseIdentifier == "Minimize" {
            IVDevToolsAssistant.shared.minimize()
        } else if cell?.reuseIdentifier == "Suspend" {
            IVDevToolsAssistant.shared.suspend(content: .url(IVFileLogger.shared.currLogFileURL))
        }
    }
    
    
    @objc func closeClicked() {
        IVDevToolsAssistant.shared.minimize()
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as IVFileLogListTableViewController:
            vc.dataSource = IVFileLogger.shared.getAllFileURLs(pathExtension: segue.identifier!)
            vc.title = segue.identifier! + "列表"
        default:
            break
        }
    }
    
    deinit {
        print(#function, "IVDeveloperViewController")
    }
}
