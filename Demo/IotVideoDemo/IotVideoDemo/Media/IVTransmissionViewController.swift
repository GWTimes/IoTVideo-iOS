//
//  IVTransmissionViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/5/25.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo

/// 自定义分包数据的包头
struct IVPkgHeader: Hashable {
    /// 数据包标签
    var tag: Int64 = 0
    /// 数据类型
    var type: PkgType = .text
    /// 数据包序号
    var pkgIdx: Int32 = 0
    /// 数据包的大小，不含此包头
    var pkgSize: Int32 = 0
    /// 数据包总个数
    var totalPkg: Int32 = 0
    /// 数据包总大小
    var totalSize: Int32 = 0
    
    func archive() -> Data {
        return withUnsafeBytes(of: self) { Data($0) }
    }
    
    static func unarchive(data: Data) -> IVPkgHeader {
        return data.withUnsafeBytes { $0.load(as: IVPkgHeader.self) }
    }
    
    enum PkgType: Int32 {
        case text
        case image
    }
}

class IVTransmissionViewController: UIViewController, IVDeviceAccessable {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendTextBtn: UIButton!
    @IBOutlet weak var rcvTextV: UITextView!
    
    var selImg: UIButton?
    @IBOutlet weak var sendImgBtn: UIButton!
    @IBOutlet weak var rcvImgV: UIImageView!
    @IBOutlet weak var imgVindicator: UIActivityIndicatorView!
    @IBOutlet weak var rcvProgLabel: UILabel!
    
    var rcvData: [Int64 : [(IVPkgHeader, Data)]] = [:]
    
    var device: IVDevice!
    var trans: IVTransmission?
    
    let hud = ivLoadingHud()
    
    var status: IVConnStatus = .disconnected {
        didSet {
            [sendTextBtn, sendImgBtn].forEach { (btn) in
                btn?.isEnabled = (status == .connected)
                btn?.layer.borderWidth = 1
                btn?.layer.borderColor = (status == .connected) ? UIColor.systemBlue.cgColor : UIColor.lightGray.cgColor
            }

            if status == .connecting || status == .disconnecting {
                hud.show(animated: true)
            } else {
                hud.hide(animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        trans = IVTransmission(deviceId: device.deviceID)
        trans?.delegate = self
        trans?.connect()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        trans?.disconnect()
    }
    
    @IBAction func sendTextClicked(_ sender: UIButton) {
        if let data = textField.text?.data(using: .utf8) {
            rcvTextV.text = nil

            let succ = trans?.send(data, tag: Int64(data.hashValue), type: .text) ?? false
            
            logInfo("发送文本", "size:\(data.count) \(succ ? "成功" : "失败")")
            IVPopupView(title: "发送文本", message: "size:\(data.count) \(succ ? "成功" : "失败")").show()
        }
        self.view.endEditing(true)
    }
    
    @IBAction func selImgClicked(_ sender: UIButton) {
        selImg?.layer.borderColor = .none
        selImg?.layer.borderWidth = 0.0
        selImg?.transform = .identity
        sender.layer.borderColor = UIColor.systemBlue.cgColor
        sender.layer.borderWidth = 2
        sender.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        selImg = sender
    }
    
    @IBAction func sendImgClicked(_ sender: UIButton) {
        if let idx = selImg?.tag {
            rcvImgV.image = nil
            imgVindicator.startAnimating()
            rcvProgLabel.text = String(format: "回传进度 %d%%", 0)
            
            let imgname = ["timg", "timg-2"]
            let url = Bundle.main.url(forResource: imgname[idx], withExtension: "jpeg")!
            let data = try! Data(contentsOf: url)
            
            let succ = trans?.send(data, tag: Int64(url.hashValue), type: .image) ?? false
            
            logInfo("发送图片", "size:\(data.count) \(succ ? "成功" : "失败")")
            IVPopupView(title: "发送图片", message: "size:\(data.count) \(succ ? "成功" : "失败")").show()
        }
        self.view.endEditing(true)
    }
    
}

extension IVTransmission {
    
    func send(_ data: Data, tag: Int64, type: IVPkgHeader.PkgType) -> Bool {
        var pkgIdx: Int32 = 0
        let headerSize = MemoryLayout<IVPkgHeader>.size
        let maxPkgSize = Int(MAX_PKG_BYTES) - headerSize
        let totalPkg: Int32 = Int32(data.count / maxPkgSize + (data.count % maxPkgSize > 0 ? 1 : 0))
        
        var header = IVPkgHeader()
        
        for lowIdx in stride(from: data.startIndex, to: data.endIndex, by: maxPkgSize) {
            let upIdx = min(lowIdx + maxPkgSize, data.endIndex)
            let pkgDat = data.subdata(in: lowIdx..<upIdx)
            
            header.tag       = tag
            header.pkgIdx    = pkgIdx
            header.pkgSize   = Int32(pkgDat.count)
            header.totalPkg  = totalPkg
            header.totalSize = Int32(data.count)
            header.type = type
            let headerDat = header.archive()
            
            let wrapdata = headerDat + pkgDat
            if !send(wrapdata) { return false }
            
            logInfo("sendImg", header)
            
            pkgIdx += 1
        }
        return true
    }
}

extension IVTransmissionViewController: IVConnectionDelegate {
    func connection(_ connection: IVConnection, didUpdate status: IVConnStatus) {
        logInfo("IVConnStatus", status.rawValue)
        self.status = status
    }
    
    func connection(_ connection: IVConnection, didReceiveError error: Error) {
        logInfo(error)
    }
    
    func connection(_ connection: IVConnection, didReceive data: Data) {
        let header: IVPkgHeader = .unarchive(data: data)
        
        if header.pkgSize > 0 {
            let start = data.count - Int(header.pkgSize)
            if (start > 0) {
                let pkginfo = (header, data.suffix(from: start))
                if rcvData[header.tag]?.isEmpty ?? true {
                    rcvData[header.tag] = [pkginfo]
                } else {
                    rcvData[header.tag]?.append(pkginfo)
                }
                logInfo("收到数据", header)
            } else {
                IVPopupView(title: "收到数据错误", message: "\(header) \(data[...20])").show()
                logError("收到数据错误", header, data[...20])
                rcvData[header.tag] = nil
            }
        }

        let pkgs = rcvData[header.tag] ?? []
        let rcvSiz = pkgs.reduce(0, { $0 + $1.0.pkgSize })
        
        if header.type == .image {
            rcvProgLabel.text = String(format: "回传进度 %d%%", Int(Double(rcvSiz) / Double(header.totalSize) * 100.0))
        }

        // 已经接收完
        if rcvSiz == header.totalSize {
            let fulldat = pkgs.sorted(by: { $0.0.pkgIdx < $1.0.pkgIdx }).reduce(Data()) { $0 + $1.1 }
            
            if header.type == .image {
                if let img = UIImage(data: fulldat) {
                    rcvImgV.image = img
                    imgVindicator.stopAnimating()
                } else {
                    IVPopupView(title: "图片已损坏").show()
                    logError("图片已损坏", header, data[...20])
                }
            } else {
                rcvTextV.text = fulldat.string(with: .utf8)
            }
            rcvData[header.tag] = nil
        }
    }
}
