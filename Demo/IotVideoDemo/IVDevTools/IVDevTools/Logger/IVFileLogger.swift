//
//  IVFileLogger.swift
//  IVLogger
//
//  Created by JonorZhang on 2019/8/20.
//  Copyright © 2019 JonorZhang. All rights reserved.
//

import UIKit

enum LogContent {
    case text(String) // 搜索跳转用text
    case url(URL)     // 列表点击进来用url
}

protocol IVFileLoggerDelegate: class {
    func fileLogger(_ logger: IVFileLogger, didInsert text: String)
}

class IVFileLogger: NSObject {
    
    static let shared = IVFileLogger()
    
    private override init() {
        super.init()
    }
    
    weak var delegate: IVFileLoggerDelegate?
    
    static let resourceBundle: Bundle? = {
        let fwBundle = Bundle(for: IVFileLogger.self)
        if let srcPath = fwBundle.path(forResource: "Resource", ofType: "bundle") {
            return Bundle(path: srcPath)
        }
        return nil
    }()
    
    let fileManager = FileManager.default
    
    lazy var fileHandle: FileHandle = {
        do {
            let handle = try FileHandle(forWritingTo: currLogFileURL as URL)
            return handle
        } catch {
            fatalError("IVFileLogger couldn't get fileWritingHandle: \(currLogFileURL)")
        }
    }()
    
    /// log文件目录
    lazy var logDir: URL = {
        guard let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("IVFileLogger couldn't find cachesDirectory")
        }

        // 创建日志目录
        let directoryURL = cachesDir.appendingPathComponent("com.jz.log")
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory( at: directoryURL, withIntermediateDirectories: true)
            } catch {
                fatalError("IVFileLogger couldn't create logDirectory: \(directoryURL)")
            }
        }
        return directoryURL
    }()

    var maxFileCount = IVLogSettingViewController.maxLogFiles

    /// 设备型号
    private var modelIdentifier: String {
        var systemInfo = utsname()
        
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    func getDeviceInfo() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let datetime = fmt.string(from: Date())
        let dev = UIDevice.current
        
        let appVersion = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?").\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")"
        
        return """
                > date:     \(datetime)
                > name:     \(dev.name)
                > model:    \(modelIdentifier)
                > OS:       \(dev.systemName) \(dev.systemVersion)
                > pakege:   \(appVersion)(\(Bundle.main.bundleIdentifier ?? "?"))
                > lang:     \(Locale.preferredLanguages.first ?? "?")
                > IDFV:     \(dev.identifierForVendor?.uuidString ?? "?")
                ----------------------------------------------------------------------------------------
                \(IVLogger.isXcodeRunning ? "正在使用Xcode Debug，日志输出到控制台！" : "")
                \n\n
                """
    }
    
    func createFile(pathExtension: String) -> URL {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let filename = fmt.string(from: Date()) + "." + pathExtension
        let fileurl = logDir.appendingPathComponent(filename, isDirectory: false)
        
        do {
            try getDeviceInfo().write(to: fileurl, atomically: true, encoding: .utf8)
            print("日志路径：", fileurl.path)
        } catch {
            fatalError("IVFileLogger couldn't create logFile: \(fileurl)")
        }
        
        return fileurl
    }
    
    /// 当前log文件URL
    lazy var currLogFileURL: URL = {
        return createFile(pathExtension: "log")
    }()
    
    /// 当前crash文件URL
    lazy var currCrashFileURL: URL = {
        return createFile(pathExtension: "crash")
    }()
    
    /// 所有历史log文件URL
    func getAllFileURLs(pathExtension: String) -> [URL] {
        let subpaths = fileManager.subpaths(atPath: logDir.path)?.filter({ (subpath) -> Bool in
            subpath.hasSuffix(pathExtension)
        })
        let fullpaths = subpaths?.map{ logDir.appendingPathComponent($0) }
        let sortedFullpaths = fullpaths?.sorted { $0.absoluteString > $1.absoluteString } ?? []
        if sortedFullpaths.count > maxFileCount {
            let suffixPaths = sortedFullpaths.suffix(from: maxFileCount)
            suffixPaths.forEach { (url) in
                deleteLogFile(url)
            }
        }
        return Array(sortedFullpaths.prefix(maxFileCount))
    }
    
    /// 读取一个log文件内容
    func readLogFile(_ url: URL) -> Data? {
        let data = fileManager.contents(atPath: url.path)
        return data
    }
    
    
    /// 读取文件末尾的count个字节
    func readLastData(from url: URL, bytes: inout UnsafeMutableRawPointer, count: inout Int) {
        let filename = url.path.cString(using: .ascii)
        let mode = "rb".cString(using: .ascii)
        guard let fp = fopen(filename, mode) else {
            count = 0
            return
        }
        // 成功，返回0，失败返回非0值
        let seekret = fseek(fp, -count, SEEK_END)
        if seekret != 0 {
            fseek(fp, 0, SEEK_SET)
        }
        count = fread(bytes, 1, count, fp);
        fclose(fp)
    }
    
    /// 追加一条普通记录到当前log文件
    func insertText(_ message: String) {
        do {
            if !fileManager.fileExists(atPath: currLogFileURL.path) {
                // 创建日志文件
                let line = message + "\n"
                try line.write(to: currLogFileURL, atomically: true, encoding: .utf8)
                
            } else {
                // 追加日志记录
                _ = fileHandle.seekToEndOfFile()
                let line = message + "\n"
                if let data = line.data(using: String.Encoding.utf8) {
                    fileHandle.write(data)
                }
                delegate?.fileLogger(self, didInsert: line)
            }
        } catch {
            print("IVFileLogger couldn't  write to file \(currLogFileURL).")
        }
    }

    /// 追加一条崩溃记录到当前log文件
    func insertFatal(_ message: String) {
        let crashURL = currCrashFileURL
        do {
            if !fileManager.fileExists(atPath: crashURL.path) {
                // 创建日志文件
                let line = message + "\n"
                try line.write(to: crashURL, atomically: true, encoding: .utf8)
                
            } else {
                do {
                    let fd = try FileHandle(forWritingTo: crashURL as URL)
                    _ = fd.seekToEndOfFile()
                    let line = message + "\n"
                    if let data = line.data(using: String.Encoding.utf8) {
                        fd.write(data)
                    }
                    fd.closeFile()
                    delegate?.fileLogger(self, didInsert: line)
                } catch {
                    fatalError("IVFileLogger couldn't get fileWritingHandle: \(crashURL)")
                }
            }
        } catch {
            print("IVFileLogger couldn't  write to file \(crashURL).")
        }
    }

    /// 删除一个log文件
    func deleteLogFile(_ url: URL) {
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            print("IVFileLogger couldn't remove file \(url).")
        }
    }    
    
    func autoLoggingStandardOutput() {
        if !IVLogger.isXcodeRunning {
            let filepath = currLogFileURL.path.cString(using: .ascii)
            let mode = ("a+").cString(using: .ascii)
            freopen(filepath, mode, stdout);
            freopen(filepath, mode, stderr);
        }
    }
    
}
