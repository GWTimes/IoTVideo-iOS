//
//  IVNewConfigViewController.swift
//  IVLogger
//
//  Created by Zhang on 2019/9/7.
//  Copyright © 2019 JonorZhang. All rights reserved.
//

import UIKit

class IVNewConfigViewController: UIViewController {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var keyField: UITextField!
    @IBOutlet weak var valueField: UITextView!
    @IBOutlet weak var saveBtn: UIButton!
    
    var config: Config?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameField.text = config?.name
        keyField.text = config?.key
        valueField.text = config?.value

        nameField.delegate = self
        keyField.delegate = self
        valueField.delegate = self
    }

    private func makeToast(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: {
            alert.dismiss(animated: true)
        })
    }
    
    @IBAction func saveConfigClicked(_ sender: Any) {
        guard let name = nameField.text, !name.isEmpty else {
            makeToast("请输入配置昵称")
            return
        }
        
        guard let key = keyField.text, !key.isEmpty else {
            makeToast("请输入变量名")
            return
        }

        guard let value = valueField.text, !value.isEmpty else {
            makeToast("请输入变量值")
            return
        }

        let newCfg = Config(name: name, key: key, value: value, enable: true)

        nameField.resignFirstResponder()
        keyField.resignFirstResponder()
        valueField.resignFirstResponder()
        
        if IVConfigMgr.existsCfg(name), config?.name != name {
            let alert = UIAlertController(title: nil, message: "已存在名为“\(name)”的配置文件，是否覆盖？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "覆盖", style: .destructive, handler: { _ in
                let name = self.config?.name ?? ""
                IVConfigMgr.updateCfg(name, newCfg)
                self.makeToast("覆盖成功,重启后生效")
                DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                    self.navigationController?.popViewController(animated: true)
                })
            }))
            present(alert, animated: true)
        } else {
            IVConfigMgr.addCfg(newCfg)
            self.makeToast("保存成功,重启后生效")
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
 

}

extension IVNewConfigViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension IVNewConfigViewController: UITextViewDelegate {
    
}
