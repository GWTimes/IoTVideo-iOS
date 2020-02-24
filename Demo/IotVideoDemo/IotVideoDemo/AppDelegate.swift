//
//  AppDelegate.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/11/19.
//  Copyright © 2019 gwell. All rights reserved.
//

import UIKit
import IoTVideo
import UserNotifications
import IVDevTools
import IVNetwork

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    @objc var allowRotation: Bool = false
    @objc static let shared = UIApplication.shared.delegate as! AppDelegate
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        registerLogger()
        window?.backgroundColor = .white
        if #available(iOS 10.0, *) {
            UIApplication.shared.registerForRemoteNotifications()
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        } else {
            // Fallback on earlier versions
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert,.badge,.sound], categories: nil))
        }
        
          //kIoTVideoHostType: 0 测试p2p服务器，测试web服务器
//        Sdk 启动
//        1、userinfo nil  -> p2p,web，云回放等均使用内置 正式 服务器
//        2、userinfo kIoTVideoHostKey -> p2p 使用传入的地址 web，云回放等均未内置 正式 服务器
//        3、userinfo kIoTVideoHostType 0 -> p2p,web，云回放等均使用内置 测试 服务器  不为0，为其他则和 （1、） 保持一致
        if let type = IVConfigMgr.allConfigs.filter({$0.enable && $0.key == kIoTVideoHostType}).first?.value {
             IoTVideo.sharedInstance.setupIvCid("103", productId: "440234147841", userInfo: [kIoTVideoHostType: type])
        } else {
            //默认测试服务器
            IoTVideo.sharedInstance.setupIvCid("103", productId: "440234147841", userInfo: [kIoTVideoHostType: "0"])
        }
        
        IoTVideo.sharedInstance.logCallback = logMessage
//        sleep(1)
//        UIApplication.shared.clearLaunchScreenCache()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
        
        IVNetwork.shared.request(methodType: .PUT, urlString: "user/pushTokenBind", params: ["xingeToken": token]) { (json, error) in
            
        }
    }
    
    func application(_ application: UIApplication, didChangeStatusBarOrientation oldStatusBarOrientation: UIInterfaceOrientation) {
        logInfo("didChangeStatusBarOrientation: %d",oldStatusBarOrientation)
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if allowRotation {
            return .allButUpsideDown
        } else {
            return .portrait
        }
    }
    
}

public extension UIApplication {

    func clearLaunchScreenCache() {
        do {
            try FileManager.default.removeItem(atPath: NSHomeDirectory()+"/Library/SplashBoard")
        } catch {
            print("Failed to delete launch screen cache: \(error)")
        }
    }

}
