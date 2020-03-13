//
//  IVKeychain.swift
//  IVAccountMgr
//
//  Created by ZhaoYong on 2020/1/10.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import Security

class IVKeychain: NSObject {
   
    /// keychain 保存数据
    /// - Parameters:
    ///   - data: 需要保存的数据
    ///   - identifier: key值，推荐域名反写拼接
    /// - Return: 存储结果
    class func saveData(_ data: Any, with identifier: String) -> Bool {
        let keychainQuery = self.createKeychainQuery(identifier)
        //删除旧数据
        SecItemDelete(keychainQuery)
        //设置数据
        keychainQuery.setValue(NSKeyedArchiver.archivedData(withRootObject: data), forKey: kSecValueData as String)
        //存储数据
        let saveState = SecItemAdd(keychainQuery, nil)
        if saveState == noErr {
            return true
        }
        return false
    }
    
    /// keychain 更新数据
    /// - Parameters:
    ///   - data: 需要更新的内容
    ///   - identifier: key值
    /// - Return: 更新结果
    class func updateData(_ data: Any, with identifier: String) -> Bool {
        let keychainQuery = self.createKeychainQuery(identifier)
        let updateKeychainQuery = NSMutableDictionary(capacity: 1)
        //设置数据
        updateKeychainQuery.setValue(NSKeyedArchiver.archivedData(withRootObject: data), forKey: kSecValueData as String)
        //更新数据
        let updateState = SecItemUpdate(keychainQuery, updateKeychainQuery)
        if updateState == noErr {
            return true
        }
        return false
    }
    
    /// keychain 查询数据
    /// - Parameter identifier: key值
    class func readData(_ identifier: String) -> Any {
        let keychainQuery = self.createKeychainQuery(identifier)
        //设置查询数据的参数
        keychainQuery.setValue(kCFBooleanTrue, forKey: kSecReturnData as String)
        keychainQuery.setValue(kSecMatchLimitOne, forKey: kSecMatchLimit as String)
        //创建数据引用
        var queryResult: AnyObject?
        //查询是否存在数据
        let readState = withUnsafeMutablePointer(to: &queryResult) { SecItemCopyMatching(keychainQuery, UnsafeMutablePointer($0))}
        var idObj: Any?
        if readState == errSecSuccess {
            if let data = queryResult as! NSData? {
                idObj = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as Any
            }
        }
        return idObj as Any
    }
    
    /// keychain 删除数据
    /// - Parameter identifier: key值
    class func deleteData(_ identifier: String) {
        let keychainQuery = self.createKeychainQuery(identifier)
        SecItemDelete(keychainQuery)
    }
}

extension IVKeychain {
    /// 创建查询条件
    /// - Parameter identifier: keychain server 即存款关键字
    private class func createKeychainQuery(_ identifier: String) -> NSMutableDictionary {
        let serverName = "com.Tencentcs.IVAccountMgr"
        let keychainQueryMutableDictionary = NSMutableDictionary(capacity: 4)
        //设置条件存储的类型
        keychainQueryMutableDictionary.setValue(kSecClassGenericPassword, forKey: kSecClass as String)
        //设置存储数据的标记
        keychainQueryMutableDictionary.setValue(serverName, forKey: kSecAttrServer as String)
        keychainQueryMutableDictionary.setValue(identifier, forKey: kSecAttrAccount as String)
        //设置数据访问属性
        keychainQueryMutableDictionary.setValue(kSecAttrAccessibleAfterFirstUnlock, forKey: kSecAttrAccessible as String)
        return keychainQueryMutableDictionary
    }
}
