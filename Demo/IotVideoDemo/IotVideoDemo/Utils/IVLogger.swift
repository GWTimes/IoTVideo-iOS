//
//  IVLogger.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/8/27.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import Foundation
import IVDevTools
import IoTVideo

//@objc class IVLog: NSObject {
//    @objc static func error(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
//        IVLogger.log(.error, path: path, function: function, line: line, message: message(items))
//    }
//
//    @objc static func warning(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
//        IVLogger.log(.warning, path: path, function: function, line: line, message: message(items))
//    }
//
//    @objc static func info(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
//        IVLogger.log(.info, path: path, function: function, line: line, message: message(items))
//    }
//
//    @objc static func debug(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
//        IVLogger.log(.debug, path: path, function: function, line: line, message: message(items))
//    }
//
//    @objc static func verbose(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
//        IVLogger.log(.verbose, path: path, function: function, line: line, message: message(items))
//    }
//}

func logFatal(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
    IVLogger.log("APP", level: .fatal, path: path, function: function, line: line, message: message(items))
}

func logError(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
    IVLogger.log("APP", level: .error, path: path, function: function, line: line, message: message(items))
}

func logWarning(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
    IVLogger.log("APP", level: .warning, path: path, function: function, line: line, message: message(items))
}

func logInfo(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
    IVLogger.log("APP", level: .info, path: path, function: function, line: line, message: message(items))
}

func logDebug(path: String = #file, function: String = #function, line: Int = #line, _ items: Any?...) {
    IVLogger.log("APP", level: .debug, path: path, function: function, line: line, message: message(items))
}

func logVerbose(path: String = #file, function: String = #function, line: Int = #line, _ items: Any...) {
    IVLogger.log("APP", level: .verbose, path: path, function: function, line: line, message: message(items))
}

func logMessage(_ message: String?) {
    IVLogger.logMessage(message)
}

var devToolsAssistant: IVDevToolsAssistant {
    return IVDevToolsAssistant.shared
}

var logLevel: UInt {
    return UInt(IVLogger.logLevel.rawValue)
}

func registerLogger() {
    IVLogger.register { (logger) in
        IoTVideo.sharedInstance.logLevel = IVLogLevel(rawValue: logLevel)!
    }
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

