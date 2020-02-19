//
//  IVAccountAPITestVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/2.
//  Copyright © 2019 gwell. All rights reserved.
//

import UIKit
import IVAccountMgr
import IoTVideo

class IVAccountAPITestVC: UITableViewController {
    fileprivate var dataArray = [IVAccountApi]()
    let IVRequest = IVAccountMgr.shared
    lazy var mainBoard = UIStoryboard(name: "Main", bundle: nil)
    override func viewDidLoad() {
        super.viewDidLoad()
        getDataArray()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return dataArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IVAccountAPITestVC", for: indexPath)
        cell.textLabel?.text = dataArray[indexPath.row].rawValue        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch dataArray[indexPath.row] {
        case .mobileResetPwd:
            let vc = mainBoard.instantiateViewController(withIdentifier: "IVRegisterVC") as! IVRegisterVC
            vc.comeInType = .findBackPwd
            self.navigationController?.pushViewController(vc, animated: true)
        case .emailResetPwd:
            let vc = mainBoard.instantiateViewController(withIdentifier: "IVRegisterEmailVC") as! IVRegisterEmailVC
            vc.comeInType = .findBackPwd
            self.navigationController?.pushViewController(vc, animated: true)
        case .modifyUserPwd:
            IVRequest.modifyPassword(oldPassword: "", newPassword: "", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .modifyUserInfo:
            // nick headUrl
            IVRequest.modifyUserInfo(modifiedInfo: ["nick":"IotVideo"], responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .queryUserInfo:
            IVRequest.getUserInfo(responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .replaceToken:
            IVRequest.updateaccessToken(responseHandler: { (json, error) in
                if let error = error {
                    showError(error)
                    return
                }
                let accessToken = json!.ivDecode(TokenModel.self)?.accessToken
                guard let token = accessToken else {
                    showAlert(msg: "更新的token为空")
                    return
                }
                IoTVideo.sharedInstance.updateToken(token)
            })
        case .findUser:
            IVRequest.findUserInfo(account: "13043471371", mobileArea: "86", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .sharedUsersList:
            IVRequest.getVisitorList(deviceId: "", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .shareByAccount:
            
            IVRequest.shareDeviceForVisitor(deviceId: "", accountId: "", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .shareByQRCode:
            IVRequest.getQRCodeSharingInfo(QRCodeToken: "token", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
            //        case .acceptShare:
            //            IVRequest.acceptSharing(ownerId: "", deviceId: "", accept: true, responseHandler: { (json, error) in
            //                handleWebCallback(json: json, error: error)
        //            })
 
        case .shareCancel:
            IVRequest.cancelSharing(deviceId: "", accountId: "12313231231", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
//        case .deviceBind:
//            IVRequest.addDevice(deviceId: "", responseHandler: { (json, error) in
//                handleWebCallback(json: json, error: error)
//            })
//        case .deviceUnbind:
//            IVRequest.deleteDevice(deviceId: "", responseHandler: { (json, error) in
//                handleWebCallback(json: json, error: error)
//            })
        case .deviceList:
            let hud = ivLoadingHud()
            IVRequest.deviceList(responseHandler: { (json, error) in
                hud.hide()
                handleWebCallback(json: json, error: error)
            })
        case .appUpdateInfo:
            let hud = ivLoadingHud()
            IVRequest.appUpdateInfo(responseHandler:{ (json, error) in
                hud.hide()
                handleWebCallback(json: json, error: error)
            })
        case .logout:
            let hud = ivLoadingHud()
            IVRequest.logout { (json, error) in
                hud.hide()
                IoTVideo.sharedInstance.unregister()
                if let error = error {
                    showError(error)
                    return
                }
                UserDefaults.standard.do {
                    $0.removeObject(forKey: demo_accessTokenKey)
                    $0.removeObject(forKey: demo_accessIdKey)
                    $0.removeObject(forKey: demo_expireTimeKey)
                }
                let board = UIStoryboard(name: "Login", bundle: nil)
                let loginVC = board.instantiateViewController(withIdentifier: "LogNav") as! UINavigationController
                loginVC.modalPresentationStyle = .fullScreen
                self.present(loginVC, animated: true, completion: nil)
            }
        default:
            break
        }
    }
}

extension IVAccountAPITestVC {
    func getDataArray() {
        dataArray = [.modifyUserPwd,
                     .modifyUserInfo,
                     .queryUserInfo,
//                     .replaceToken,
//                     .sharedUsersList,
                     //                     .shareByQRCode,
            //                     .acceptShare,
//            .shareQRCodeToken,
            
//            .shareCancel,
//            .deviceBind,
//            .deviceUnbind,
            .deviceList,
            .appUpdateInfo,
            .logout]
    }
}

/// 账户相关API 25
fileprivate enum IVAccountApi: String {
    
    //MARK:-  用户管理
    
    /// 发送手机验证码
    case mobileCheckCode  = "发送手机验证码"
    /// 发送邮箱验证码
    case emailCheckCode   = "发送邮箱验证码"
    /// 手机注册
    case mobileRegister   = "手机注册"
    /// 邮箱注册
    case emailRegister    = "邮箱注册"
    /// 登录
    case login            = "登录"
    /// 登出
    case logout           = "登出"
    /// 第三方登录
    case thirdLogin       = "第三方登录"
    /// 第三方绑定
    case thirdBind        = "第三方绑定"
    /// 第三方解绑
    case thirdUnbind      = "第三方解绑"
    /// 手机重置密码
    case mobileResetPwd   = "手机重置密码"
    /// 邮箱重置密码
    case emailResetPwd    = "邮箱重置密码"
    /// 修改密码
    case modifyUserPwd    = "修改密码"
    /// 修改用户信息
    case modifyUserInfo   = "修改用户信息"
    /// 查询用户信息
    case queryUserInfo    = "查询用户信息"
    /// 更新用户accessToken
    case replaceToken     = "更新用户accessToken"
    /// 根据手机或邮箱或用户id查找用户
    case findUser         = "根据手机或邮箱或用户id查找用户"
    
    
    //    MARK:-  问题反馈与系统消息
    
    /// 上传app日志文件 put
    case uploadLog        = "上传app日志文件"
    /// APP获取上传到腾讯云存的cos的授权信息 put
    case getCosAuthInfo   = "APP获取上传到腾讯云存的cos的授权信息"
    /// 提交反馈信息 post
    case feedback         = "提交反馈信息"
    /// 查询反馈信息列表 get
    case feedbackList     = "查询反馈信息列表"
    /// 查询反馈详情 get
    case feedbackDetail   = "查询反馈详情"
    /// 查询系统消息列表 get
    case noticeList       = "查询系统消息列表"
    /// 查询系统消息详情 get
    case noticeDetail     = "查询系统消息详情"
    
    //MARK:-  设备分享
    
    /// 查询设备被分享给的用户列表 get
    case sharedUsersList  = "查询设备被分享给的用户列表"
    /// 分享邀请-账号方式 post
    case shareByAccount   = "分享邀请-账号方式"
    /// 分享邀请-扫描二维码方式 post
    case shareByQRCode    = "分享邀请-扫描二维码方式"
    /// 分享邀请-接受分享 post
    case acceptShare      = "分享邀请-接受分享"
    /// 生成分享二维码,获取二维码token
    case shareQRCodeToken = "生成分享二维码,获取二维码token"
    /// 取消设备分享，分享者和被分享者共用
    case shareCancel      = "取消设备分享，分享者和被分享者共用"
    
    
    //MARK:- 设备管理
    /// 绑定设备
    case deviceBind       = "绑定设备"
    /// 解绑设备
    case deviceUnbind     = "解绑设备"
    /// 查看设备列表
    case deviceList       = "查看设备列表"
    
    /// 公版app获取升级地址
    case appUpdateInfo    = "公版app获取升级地址"
}


struct TokenModel: Codable {
    var accessToken: String
    var expireTime: Int = 0
}

struct UserModel: Codable {
    var userName: String?
    var ivUid: String?
    var headUrl: String?
    var nick: String?
}
