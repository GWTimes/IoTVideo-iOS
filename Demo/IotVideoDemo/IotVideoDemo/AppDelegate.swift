//
//  AppDelegate.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/11/19.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo
import UserNotifications
import IVDevTools
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    @objc static let shared = UIApplication.shared.delegate as! AppDelegate
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        logInfo(#function)

        // Override point for customization after application launch.
        registerLogger()
        registerRemoteNotification()
        
        //测试服调试
//        IoTVideo.sharedInstance.options[.hostType] = "0"
        IoTVideo.sharedInstance.options[.appVersion] = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        IoTVideo.sharedInstance.options[.appPkgName] = Bundle.main.bundleIdentifier!
        
        IoTVideo.sharedInstance.setup(launchOptions: launchOptions)
        IoTVideo.sharedInstance.delegate = self
        IoTVideo.sharedInstance.logLevel = IVLogLevel(rawValue: logLevel) ?? .DEBUG

        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.toolbarDoneBarButtonItemText = "完成"
//        UIApplication.shared.clearLaunchScreenCache()
        
        window?.backgroundColor = .white
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        logInfo(#function)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        logInfo(#function)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        logInfo(#function)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        logInfo(#function)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        logInfo(#function)
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logWarning("deviceToken:",error)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.reduce("", {$0 + String(format: "%02x", $1)})
        
        UserDefaults.standard.setValue(token, forKey: demo_deviceToken)
        guard IoTVideo.sharedInstance.accessToken != nil else {
            return
        }
        
    }
    
    func application(_ application: UIApplication, didChangeStatusBarOrientation oldStatusBarOrientation: UIInterfaceOrientation) {
        logInfo("didChangeStatusBarOrientation: %d",oldStatusBarOrientation)
    }
    
    /// 注册远程推送
    func registerRemoteNotification() {
        if #available(iOS 10.0, *) {
            UIApplication.shared.registerForRemoteNotifications()
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        } else {
            // Fallback on earlier versions
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert,.badge,.sound], categories: nil))
        }
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
        IVPopupView.showAlert(title: "SDK状态", message: "linkStatus: \(stStr)")
        if linkStatus == .kickOff {
            IVNotiPost(.logout(by: .kickOff))
        }
    }
    
    func didOutputLogMessage(_ message: String, level: IVLogLevel, file: String, func: String, line: Int32) {
        let lv = Level(rawValue: Int(level.rawValue))!
        IVLogger.log(lv, path: file, function: `func`, line: Int(line), message: message)
    }
}

public extension UIApplication {
    /// 修改LaunchScreen.storyboard 启动异常时调用 清除启动图缓存
    func clearLaunchScreenCache() {
        do {
            try FileManager.default.removeItem(atPath: NSHomeDirectory()+"/Library/SplashBoard")
        } catch {
            logWarning("Failed to delete launch screen cache: \(error)")
        }
    }
}

