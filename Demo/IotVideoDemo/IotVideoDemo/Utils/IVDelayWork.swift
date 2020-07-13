//
//  IVDelayWork.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/4/8.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation

class IVDelayWork: Any {
    
    private class WorkItem {
        var deadline: TimeInterval = 0
        var work: (() -> Void)? = nil
        
        init(deadline: TimeInterval, work: @escaping @convention(block) () -> Void) {
            self.deadline = deadline
            self.work = work
        }
    }
    
    private static let timer: Timer = {
        let tr = Timer.scheduledTimer(timeInterval: 0.1, target: IVDelayWork.self, selector: #selector(tickClockHandler(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(tr, forMode: .common)
        return tr
    }()
    
    @objc private static func tickClockHandler(_ timer: Timer) {
        DispatchQueue.main.async {
            workItems.forEach {
                $0.value.deadline -= timer.timeInterval
                if $0.value.deadline <= 0 {
                    $0.value.work?()
                }
            }
            workItems = workItems.filter { $0.value.deadline > 0 }
            if workItems.isEmpty {
                timer.fireDate = .distantFuture
            }
        }
    }
    
    private static var workItems: [String : WorkItem] = [:]
    
    public static func asyncAfter(_ deadline: TimeInterval, key: String, execute work: @escaping @convention(block) () -> Void) {
        DispatchQueue.main.async {
            if let item = workItems[key] {
                item.deadline = deadline
                item.work = work
            } else {
                workItems[key] = WorkItem(deadline: deadline, work: work)
                timer.fireDate = .distantPast
            }
        }
    }
    
    // 等待（不超过deadline）条件（condition）成立之后执行任务（work）
    public static func async(wait condition: @escaping (_ canceled: inout Bool) -> Bool,
                             execute work: @escaping (_ success: Bool) -> Void,
                             deadline: DispatchTime = DispatchTime.distantFuture,
                             interval: TimeInterval = 0.5) {
        DispatchQueue.global().async {
            var canceled = false
            var succ = condition(&canceled)
            while !succ, .now() < deadline {
                succ = condition(&canceled)
                if canceled { break }
                usleep(useconds_t(interval * 1000000)) // 100ms
            }
            DispatchQueue.main.async { work(succ) }
        }
    }
}

