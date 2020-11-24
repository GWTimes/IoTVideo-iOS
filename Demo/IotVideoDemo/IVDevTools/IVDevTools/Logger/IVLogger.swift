//
//  IVLogger.swift
//  Yoosee
//
//  Created by JonorZhang on 2019/4/10.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import Foundation

// 日志级别
@objc public enum Level: Int, CustomStringConvertible {
    case off     = 0
    case fatal   = 1
    case error   = 2
    case warning = 3
    case info    = 4
    case debug   = 5
    case verbose = 6
    
    public var description: String {
        switch self {
        case .off:      return ""
        case .fatal:    return "[F]📵"
        case .error:    return "[E]💔"
        case .warning:  return "[W]⚠️"
        case .info:     return "[I]💙"
        case .debug:    return "[D]"
        case .verbose:  return "[V]"
        }
    }
}

fileprivate class Log: NSObject {
    var level: Level
    var tag: String
    var message: String
    var file: String
    var function: String
    var line: Int
    var dateDesc: String
    
    convenience override init() {
        self.init(date: Date(), tag: "APP", level: .verbose, message: "", file: "", function: "", line: 0)
    }
    
    init(date: Date, tag: String, level: Level, message: String, file: String, function: String, line: Int) {
        self.dateDesc   = Log.dateFormatter.string(from: date)
        self.tag        = tag
        self.level      = level
        self.message    = message
        self.file       = file
        self.function   = function
        self.line       = line
        super.init()
    }
    
    // 08:30:53.004 控制器销毁 MineController <BaseViewController.m:22> -[BaseViewController dealloc]
    override var description: String {
        let linestr = (line > 0 ? "L\(line)" : "")

        switch (level) {
        case .fatal, .error, .warning:
            let location = (line > 0 ? "[\(file):\(line) \(function)]" : "")
            return String(format: "%@ [%@] %@ %@ %@", dateDesc, tag, level.description, message, location)
        case .info:
            return String(format: "%@ [%@] %@ %@ %@", dateDesc, tag, level.description, message, linestr)
        case .debug, .verbose:
            return String(format: "%@ [%@] %@ %@",    dateDesc, tag, message, linestr)
        default:
            return ""
        }
    }

    static func == (lhs: Log, rhs: Log) -> Bool {
        return lhs.dateDesc == rhs.dateDesc
    }
    
    static func < (lhs: Log, rhs: Log) -> Bool {
        return lhs.dateDesc < rhs.dateDesc
    }
    
    static func > (lhs: Log, rhs: Log) -> Bool {
        return lhs.dateDesc > rhs.dateDesc
    }
    
    private static let dateFormatter: DateFormatter = {
        let defaultDateFormatter = DateFormatter()
        defaultDateFormatter.locale = NSLocale.current
        defaultDateFormatter.dateFormat = "HH:mm:ss.SSS" //"yyyy-MM-dd HH:mm:ss.SSS"
        return defaultDateFormatter
    }()
}

@objc public class IVLogger: NSObject {
    
    private static let serialQueue = DispatchQueue(label: "iv.logger.serialQueue")
    
    /// 日志的最高级别, 默认Debug:.debug / Release:.info。 log.level > maxLevel 的将会忽略
    public static var logLevel: Level = IVLogSettingViewController.logLevel {
        didSet {
            if logLevel != IVLogSettingViewController.logLevel {
                IVLogSettingViewController.logLevel = logLevel
            }
            eventObserver?(self)
        }
    }

    private static var eventObserver: ((IVLogger.Type) -> Void)? = nil
    
    @objc public static func register(_ eventObserver: ((IVLogger.Type) -> Void)? = nil) {
        IVFileLogger.shared.autoLoggingStandardOutput()
        self.eventObserver = eventObserver
        registerCrashHandler { (crashLog) in
            log(level: .fatal, message: crashLog)
        }
    }

    @objc public static func log(_ tag: String = "APP", level: Level = .debug, path: String = #file, function: String = #function, line: Int = #line, message: String = "") {
        // 级别限制
        if level.rawValue > logLevel.rawValue { return }
        
        // 模型转换
        let fileName = (path as NSString).lastPathComponent
        let log = Log(date: Date(), tag: tag, level: level, message: message, file: fileName, function: function, line: line)
        let logDesc = log.description
        
        if level == .fatal {
            IVFileLogger.shared.insertFatal(logDesc)
        }
        logMessage(logDesc)
    }

    @objc public static func logMessage(_ message: String?) {
        guard let message = message else { return }
//#if DEBUG
//        if IVLogger.isXcodeRunning {
            print(message)
//        } else {
//            serialQueue.async {
//                IVFileLogger.shared.insertText(message)
//            }
//        }
//#else
//        serialQueue.async {
//            IVFileLogger.shared.insertText(message)
//        }
//#endif
    }
    
    @objc public static var isXcodeRunning: Bool = {
        var info = kinfo_proc()
        info.kp_proc.p_flag = 0
        var mib = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        
        var size = MemoryLayout.size(ofValue: info)
        let _ = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        
        let isxcode = ( (info.kp_proc.p_flag & P_TRACED) != 0 )

        return isxcode
    }()
}


