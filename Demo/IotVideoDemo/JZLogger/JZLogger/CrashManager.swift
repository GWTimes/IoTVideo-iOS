//
//  CrashManager.swift
//  JZLogger
//
//  Created by JonorZhang on 2019/10/16.
//  Copyright © 2019 JonorZhang. All rights reserved.
//

import Foundation
import MachO

private var crashHandler: ((String) -> Void)? = nil

func registerCrashHandler(_ handler: ((String) -> Void)?) {
    crashHandler = handler
    registerExcptionHandler()
    registerSignalHandler()
}

private var ori_uncaughtExceptionHandler: ((NSException) -> Void)? = nil

private func registerExcptionHandler() {
    ori_uncaughtExceptionHandler = NSGetUncaughtExceptionHandler()
    NSSetUncaughtExceptionHandler(uncaughtExceptionHandler)
}

private func registerSignalHandler() {
    signal(SIGABRT, signalCrashHandler)
    signal(SIGSEGV, signalCrashHandler)
    signal(SIGBUS, signalCrashHandler)
    signal(SIGTRAP, signalCrashHandler)
    signal(SIGILL, signalCrashHandler)
    
//    signal(SIGHUP, signalCrashHandler)
//    signal(SIGINT, signalCrashHandler)
//    signal(SIGQUIT, signalCrashHandler)
//    signal(SIGFPE, signalCrashHandler)
//    signal(SIGPIPE, signalCrashHandler)
}

private func uncaughtExceptionHandler(exception: NSException) {
    let arr = exception.callStackSymbols
    let reason = exception.reason
    let name = exception.name.rawValue
    var crash = String()
    crash += "Stack:\r\n"
    crash = crash.appendingFormat("imageOffset:0x%0x\r\n", imageOffset())
    crash += "\r\n\r\n name:\(name) \r\n reason:\(String(describing: reason)) \r\n \(arr.joined(separator: "\r\n")) \r\n\r\n"
    
    crashHandler?(crash)
    ori_uncaughtExceptionHandler?(exception)
}

private func signalCrashHandler(signal:Int32) -> Void {
    var mstr = String()
    mstr += "Stack:\n"
    
    mstr = mstr.appendingFormat("imageOffset:0x%0x\r\n", imageOffset())
    mstr += Thread.callStackSymbols.joined(separator: "\r\n")
    
    crashHandler?(mstr)
    exit(signal)
}

private func imageOffset() -> Int {
    let imagesCnt = _dyld_image_count()
    for i in 0..<imagesCnt {
        if let imageHeader = _dyld_get_image_header(i),
            imageHeader.pointee.filetype == MH_EXECUTE {
            return _dyld_get_image_vmaddr_slide(i)
        }
    }
    return 0;
}
