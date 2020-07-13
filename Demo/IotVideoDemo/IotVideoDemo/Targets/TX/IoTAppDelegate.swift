//
//  YSAppDelegate.swift
//  IotVideoDemoYS
//
//  Created by zhaoyong on 2020/6/15.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation
import IoTVideo
import IVDevTools

extension AppDelegate {
    func setupIoTVideo(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?)  {
        IoTVideo.sharedInstance.options[.appVersion] = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        IoTVideo.sharedInstance.options[.appPkgName] = Bundle.main.bundleIdentifier!
        
        IoTVideo.sharedInstance.setup(launchOptions: launchOptions)
        IoTVideo.sharedInstance.delegate = self
        IoTVideo.sharedInstance.logLevel = IVLogLevel(rawValue: logLevel) ?? .DEBUG
    }
}

extension AppDelegate: IoTVideoDelegate {
    func didUpdate(_ linkStatus: IVLinkStatus) {
        logInfo("linkStatus: \(linkStatus.rawValue)")
        let linkDesc: [IVLinkStatus : String] = [.online : "在线",
                                                 .offline : "离线",
                                                 .tokenFailed : "Token校验失败",
                                                 .kickOff : "账号被踢飞"]
        let stStr = linkDesc[linkStatus] ?? ""
        window?.makeToast("SDK状态:"+stStr, duration: 2, position: .top)
        if linkStatus == .kickOff {
            IVNotiPost(.logout(by: .kickOff))
        }
    }
    
    func didOutputLogMessage(_ message: String, level: IVLogLevel, file: String, func: String, line: Int32) {
        let lv = Level(rawValue: Int(level.rawValue))!
        IVLogger.log(lv, path: file, function: `func`, line: Int(line), message: message)
    }
}
