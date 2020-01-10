//
//  IVLogger.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/8/27.
//  Copyright © 2019 Gwell. All rights reserved.
//

import Foundation
import JZLogger

//@objc class IVLog: NSObject {
//    @objc static func error(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
//        JZLogger.log(.error, path: path, function: function, line: line, message: message(items))
//    }
//
//    @objc static func warning(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
//        JZLogger.log(.warning, path: path, function: function, line: line, message: message(items))
//    }
//
//    @objc static func info(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
//        JZLogger.log(.info, path: path, function: function, line: line, message: message(items))
//    }
//
//    @objc static func debug(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
//        JZLogger.log(.debug, path: path, function: function, line: line, message: message(items))
//    }
//
//    @objc static func verbose(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
//        JZLogger.log(.verbose, path: path, function: function, line: line, message: message(items))
//    }
//}

func logError(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
    JZLogger.log(.error, path: path, function: function, line: line, message: message(items))
}

func logWarning(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
    JZLogger.log(.warning, path: path, function: function, line: line, message: message(items))
}

func logInfo(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
    JZLogger.log(.info, path: path, function: function, line: line, message: message(items))
}

func logDebug(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
    JZLogger.log(.debug, path: path, function: function, line: line, message: message(items))
}

func logVerbose(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
    JZLogger.log(.verbose, path: path, function: function, line: line, message: message(items))
}

func logMessage(level: Int32, path: String, function: String, line: Int32, message: String) {
    JZLogger.log(Level(rawValue: Int(level))!, path: path, function: function, line: Int(line), message: message)
}

var logAssistant: IVLogAssistant {
    return IVLogAssistant.shared
}

fileprivate func unwrap<T: Any>(_ any: T) -> T {
    let mi = Mirror(reflecting: any)
    if mi.displayStyle != .optional {
        return any
    }

    if mi.children.count == 0 { return NSNull() as! T }
    let (_, some) = mi.children.first!
    return some as! T
}

fileprivate func message<T: Collection>(_ items: T) -> String {
    return items.map { (item) -> String in
        let any = unwrap(item)
        return any as? String ?? "\(any)"
    }.joined(separator: " ")
}

