//
//  IVConfigMgr.swift
//  IVLogger
//
//  Created by Zhang on 2019/9/8.
//  Copyright © 2019 JonorZhang. All rights reserved.
//

import UIKit

public struct Config: Codable {
    public var name: String
    public var key: String
    public var value: String
    public var enable: Bool
}

public class IVConfigMgr: NSObject {
    
    static let kAllConfigKeys = "IVConfigKeys"
    
    public static var allConfigs: [Config] = {
        if let data = UserDefaults.standard.data(forKey: kAllConfigKeys),
            let cfgs = try? JSONDecoder().decode([Config].self, from: data), !cfgs.isEmpty {
            return cfgs
        }
//        直接修改默认值： PS 只给 IoTVideoDemo使用， 其他项目请还原
//        return []
        
//        1157493686468 腾讯测试
        
        return [
            Config(name: "TEST_ID_0", key: "IOT_TEST_SECRECT_ID", value: "AKIDwmOmvryLcolStUw2vc4JI1hHfpkShJOS", enable: false),
            Config(name: "TEST_KEY_0", key: "IOT_TEST_SECRECT_KEY", value: "zmJbfXBZlkkV1IMBk9OSGtIannUwCCwR", enable: false),
            
            Config(name: "TEST_ID_zc", key: "IOT_TEST_SECRECT_ID", value: "AKIDJI7i39Df3CG5qM9jY7SiksuocFeov3HF", enable: false),
            Config(name: "TEST_KEY_1", key: "IOT_TEST_SECRECT_KEY", value: "ylJbecMp2zh8PRO5VllVyA7TbUAdrqaC", enable: false),
        ]
    }() {
        didSet {
            let data = try? JSONEncoder().encode(allConfigs)
            UserDefaults.standard.set(data, forKey: kAllConfigKeys)
        }
    }

    static func addCfg(_ cfg: Config) {
        if let idx = allConfigs.firstIndex(where: { $0.name == cfg.name }) {
            allConfigs[idx] = cfg
        } else {
            allConfigs.append(cfg)
        }
    }

    static func deleteCfg(_ cfg: Config) {
        if let idx = allConfigs.firstIndex(where: { $0.name == cfg.name }) {
            allConfigs.remove(at: idx)
        }
    }

    static func updateCfg(_ name: String, _ newCfg: Config) {
        if let idx = allConfigs.firstIndex(where: { $0.name == name }) {
            allConfigs[idx] = newCfg
        }
    }

    static func enableCfg(_ name: String, _ enable: Bool) {
        if let idx = allConfigs.firstIndex(where: { $0.name == name }) {
            allConfigs[idx].enable = enable
        }
    }
    
    static func existsCfg(_ name: String) -> Bool {
        if let _ = allConfigs.firstIndex(where: { $0.name == name }) {
            return true
        }
        return false
    }
    


}
