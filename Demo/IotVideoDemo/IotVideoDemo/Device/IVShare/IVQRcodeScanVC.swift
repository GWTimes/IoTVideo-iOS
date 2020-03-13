//
//  IVQRcodeScanVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/3.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo
import IVAccountMgr

class IVQRcodeScanVC: UIViewController {
    var qrMgr:IVQRCodeHelper?
    override func viewDidLoad() {
        super.viewDidLoad()

          // Do any additional setup after loading the view.
//        IVQRCodeHelper.startScan(withPreView: self.view, cropRect: CGRect.zero) { (string) in
//            print("qrScan：",string ?? "")
//                       if let string = string {
//                           let alert = UIAlertController(title: "扫码结果", message: string, preferredStyle: .alert)
//                           let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
//                           alert.addAction(ok)
//                           self.present(alert, animated: true, completion: nil)
//                       }
//        }
        
        qrMgr = IVQRCodeHelper(preView: self.view, cropRect: CGRect.zero) { (string) in
            print("qrScan：",string ?? "")
            if let string = string {
                
                IVAccountMgr.shared.getQRCodeSharingInfo(QRCodeToken: string) { (json, error) in
                    if let error = error {
                        print(error)
                        showError(error)
                        return
                    }
                    print(json!)
                    showAlert(msg: json!)
//                    let model = IVJson.decode(json: json!, type: QRShare.self)
                    
//                    if let ownerId = model?.data?.ownerUserId, let deviceId = model?.data?.did {
//                        let alert = UIAlertController(title: model?.data?.deviceName, message: "主人ID: \(ownerId)\n" + "设备ID: \(deviceId)",preferredStyle: .alert)
//                        let ok = UIAlertAction(title: "接受分享", style: .default, handler: { _ in
//                            IVAccountMgr.shared.acceptSharing(ownerId: ownerId, deviceId: deviceId, accept: true) { (acceptJson, acceptError) in
//                                if let acceptError = acceptError {
//                                    print(acceptError)
//                                    return
//                                }
//                                print(acceptJson!)
//                                alert.dismiss(animated: true, completion: nil)
//                            }
//                        })
//                        let cancel = UIAlertAction(title: "不接受分享", style: .cancel, handler: nil)
//                        alert.addAction(ok)
//                        alert.addAction(cancel)
//                        self.present(alert, animated: true, completion: nil)
//                    }
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.qrMgr?.startScan()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

struct QRShare: Codable {
    var data: QRShareData?
    var code: Int = 0
    var msg: String?
}

struct QRShareData: Codable {
    var did: String?
    var deviceName: String?
    var ownerUserId: String?
}
