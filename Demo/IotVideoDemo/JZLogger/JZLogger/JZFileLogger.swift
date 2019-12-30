//
//  JZFileLogger.swift
//  JZLogger
//
//  Created by JonorZhang on 2019/8/20.
//  Copyright © 2019 JonorZhang. All rights reserved.
//

import UIKit

enum LogContent {
    case text(String) // 搜索跳转用text
    case url(URL)     // 列表点击进来用url
}

protocol JZFileLoggerDelegate: class {
    func fileLogger(_ logger: JZFileLogger, didInsert text: String)
}

class JZFileLogger: NSObject {
    
    static let shared = JZFileLogger()
    
    private override init() {
        super.init()
        autoLoggingStandardOutput()
    }
    
    weak var delegate: JZFileLoggerDelegate?
    
    static let resourceBundle: Bundle? = {
        let fwBundle = Bundle(for: JZFileLogger.self)
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
            fatalError("JZFileLogger couldn't get fileWritingHandle: \(currLogFileURL)")
        }
    }()
    
    /// log文件目录
    lazy var logDir: URL = {
        guard let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("JZFileLogger couldn't find cachesDirectory")
        }

        // 创建日志目录
        let directoryURL = cachesDir.appendingPathComponent("com.jz.log")
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory( at: directoryURL, withIntermediateDirectories: true)
            } catch {
                fatalError("JZFileLogger couldn't create logDirectory: \(directoryURL)")
            }
        }
        return directoryURL
    }()

    var maxFileCount = JZLogSettingViewController.maxLogFiles

    func getDeviceInfo() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let datetime = fmt.string(from: Date())
        let dev = UIDevice.current
        
        let appVersion = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?").\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")"
        
        return """
                > date:     \(datetime)
                > device:   \(dev.name)(\(dev.systemName) \(dev.systemVersion))
                > pakege:   \(appVersion)(\(Bundle.main.bundleIdentifier ?? "?"))
                > lang:     \(Locale.preferredLanguages.first ?? "?")
                > IDFV:     \(dev.identifierForVendor?.uuidString ?? "?")
                ----------------------------------------------------------------------------------------
                \n\n
                """
    }
    
    /// 当前log文件URL
    lazy var currLogFileURL: URL = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let filename = fmt.string(from: Date()) + ".log"
        let fileurl = logDir.appendingPathComponent(filename, isDirectory: false)
        
        do {
            try getDeviceInfo().write(to: fileurl, atomically: true, encoding: .utf8)
            print("日志路径：", fileurl.path)
        } catch {
            fatalError("JZFileLogger couldn't create logFile: \(fileurl)")
        }
        
        return fileurl
    }()
    
    /// 所有历史log文件URL
    func getAllFileURLs() -> [URL] {
        let subpaths = fileManager.subpaths(atPath: logDir.path)
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
    
    /// 追加一条记录到当前log文件
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
            print("JZFileLogger couldn't  write to file \(currLogFileURL).")
        }
    }
    
    /// 删除一个log文件
    func deleteLogFile(_ url: URL) {
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            print("JZFileLogger couldn't remove file \(url).")
        }
    }    
    
    func autoLoggingStandardOutput() {
        if !JZLogger.isXcodeRunning {
            let filepath = currLogFileURL.path.cString(using: .ascii)
            let mode = ("a+").cString(using: .ascii)
            freopen(filepath, mode, stdout);
            freopen(filepath, mode, stderr);
        }
    }
    
}
