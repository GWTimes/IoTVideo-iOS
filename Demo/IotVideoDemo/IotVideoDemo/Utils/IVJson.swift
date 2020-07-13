//
//  IVJson.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/2.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import SwiftyJSON

/// 解析JSon
class IVJson: NSObject {
    /// 传入json进行解析
    /// - Parameter json: json字符串
    /// - Parameter type: 遵守 Codable 协议的Model.self
    /// - Returns: 解析完成的model
    class func decode<T: Codable>(json: String, type:T.Type) -> T? {
        return json.decode(type)
    }
}

extension String {
    /// json 解析
    /// - Parameter type: 遵守 Codable 协议的Model.self
    /// - Returns: 解析完成的model
    func decode<T: Codable>(_ type: T.Type) -> T? {
        let jsonData = data(using: .utf8)!
        let model: T? = try? JSONDecoder().decode(type, from: jsonData)
        return model
    }

    /// json 解析 字典 解出data对应model
    /// - Parameter type: 遵守 Codable 协议的Model.self
    func ivDecode<T: Codable>(_ type: T.Type) -> T? {
        return decode(IVModel<T>.self)?.data
    }
    
    /// json 解析 数组 解出data对应model
    /// - Parameter type: 遵守 Codable 协议的Model.self
    func ivArrayDecode<T: Codable>(_ type: T.Type) -> [T?] {
        return decode(IVArrayModel<T>.self)?.data ?? []
    }
}


struct IVModel<T>: Codable where T: Codable {
    var msg: String?
    var code: Int = 0
    var data: T?
}

struct IVArrayModel<T: Codable>: Codable {
    var data: [T?]?
    var code: Int = 0
    var msg: String?
}

extension JSON {
    func value(_ path: String) -> JSON? {
        let json = self
        let subpaths = path.split(separator: ".", maxSplits: 1)
        if subpaths.count == 1 {
            let leaf = String(subpaths[0])
            return json[leaf]
        } else if subpaths.count > 1 {
            let leaf = String(subpaths[0])
            let newpath = String(subpaths[1])
            if !json[leaf].exists() {
                return nil
            } else {
                let newjson = json[leaf]
                return newjson.value(newpath)
            }
        } else {
            return nil
        }
    }
    
    /// 读取服务器推送的状态更新
    /// - Parameters:
    ///   - value: 具体值的字段 例如 stVal 或 ctVal
    ///   - property: 是哪个属性的值 例如 _online
    ///   - path: 服务器返回 有时候完整的，有时候是部分的，直接传进来就好
    /// - Returns: 返回的 JSON
    func ivValue(_ value: String, property: String, path: String) -> JSON? {
        if path.contains(property) {
            return self[value].ivExists()
        } else {
            let paths = ["ProReadonly","Action","ProConst"]
            for path in paths {
                if self[path].exists() {
                    return self[path].value(property + "." + value)?.ivExists()
                }
            }
            return self.value(property + "." + value)?.ivExists()
        }
    }
    
    // 防止未解析到对应值，但是最终却使用了类似 0，“”，false这样的默认值
    private func ivExists() -> JSON? {
        return self.exists() ? self : nil
    }
}

