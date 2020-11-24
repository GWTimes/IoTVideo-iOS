//
//  IVTimelineViewModel.swift
//  IotVideoDemoYS
//
//  Created by JonorZhang on 2020/8/20.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo.IVPlaybackPlayer

/// 时间刻度
enum IVTimeMark: Int, Comparable {
    case hour4    = 14400 // 60*60*4
    case hour2    = 7200  // 60*60*2
    case hour     = 3600  // 60*60
    case min30    = 1800  // 30*60
    case min10    = 600   // 10*60
    case min5     = 300   // 5*60
    case min1     = 60    // 60
    case sec30    = 30    // 30
    case sec10    = 10    // 10
    case sec5     = 5     // 5
    case sec1     = 1     // 1
    
    /// 当前刻度的上一级刻度
    var upperMark: IVTimeMark? { return IVTimeMark.all.reversed().first(where: { $0 > self }) }
    
    /// 除数
    static let divisors = [1, 2, 3, 5]

    /// 所有刻度
    static let all: [IVTimeMark] = [.hour4, .hour2, .hour, .min30, .min10, .min5, .min1, .sec30, .sec10, .sec5, .sec1]

    static func < (lhs: IVTimeMark, rhs: IVTimeMark) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    static func > (lhs: IVTimeMark, rhs: IVTimeMark) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }
}

protocol IVTiming: Comparable, CustomStringConvertible {
    var start: TimeInterval { get }
    var end: TimeInterval { get }
    var duration: TimeInterval { get }
}

extension IVTiming {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return abs(lhs.start - rhs.start) < 0.0001 && abs(lhs.end - rhs.end) < 0.0001
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.end - 0.0001 < rhs.start
    }

    static func > (lhs: Self, rhs: Self) -> Bool {
        return lhs.start > rhs.end - 0.0001
    }
    
    func contains(_ ti: TimeInterval) -> Bool {
        return ti > start - 0.0001 && ti < end + 0.0001
    }
    
    func after(days: UInt) -> IVTime {
        return offset(days: Int(days))
    }

    func before(days: UInt) -> IVTime {
        return offset(days: -1 * Int(days))
    }

    func offset(days: Int) -> IVTime {
        return IVTime(start: start + Double(86400*days), end: end + Double(86400*days))
    }
    
    func string(dateFormat: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = dateFormat
        return fmt.string(from: date)
    }
    
    var date: Date {
        return Date(timeIntervalSince1970: start)
    }
    
    var dateString: String {
        return string(dateFormat: "yyyy-MM-dd")
    }
    
    var description: String {
        return String(format: "%.3lf-%.3lf=%.3f", start, end, duration)
    }
}

struct IVTime: IVTiming, Hashable {
    let start: TimeInterval
    let end: TimeInterval
    let duration: TimeInterval
    
    init(start: TimeInterval, end: TimeInterval) {
        self.start = start
        self.end = end
        self.duration = end - start
    }
    
    init(date: Date) {
        let ymd = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let date = Calendar.current.date(from: ymd)!
        let t0 = date.timeIntervalSince1970
        let t1 = t0 + 86400
        self.init(start: t0, end: t1)
    }

    static let today = IVTime(date: Date())
}

struct IVTimelineItem: IVTiming {
    var start: TimeInterval
    var end: TimeInterval
    var duration: TimeInterval
    var type: String
    
    var color: UIColor {
        switch type {
        case "padding", "placeholder":
            return UIColor(white: 0.98, alpha: 1)
        case "manual":
            return .orange
        case "alarm":
            return .red
        case "allday":
            return UIColor(rgb: 0x91B1EF)
        default:
            return .green
        }
    }
    
    var rawValue: Any?
    
    var isPadding: Bool { type == "padding" }
    var isPlaceholder: Bool { type == "placeholder" }
    var isValid: Bool { !isPadding && !isPlaceholder }

    init(start: TimeInterval, end: TimeInterval, type: String, rawValue: Any?) {
        self.start = start
        self.end = end
        self.duration = end - start
        self.type = type
        self.rawValue = rawValue
    }
    
    static func padding(start: TimeInterval, end: TimeInterval) -> IVTimelineItem {
        return IVTimelineItem(start: start, end: end, type: "padding", rawValue: nil)
    }

    static func placeholder(start: TimeInterval, end: TimeInterval) -> IVTimelineItem {
        return IVTimelineItem(start: start, end: end, type: "placeholder", rawValue: nil)
    }
}

struct IVTimelineSection: IVTiming {
    let time: IVTime
    
    var start: TimeInterval { time.start }
    var end: TimeInterval { time.end }
    var duration: TimeInterval { time.duration }

    // 原始回放文件（用于定位某时刻对应的文件）
    private(set) var rawItems: [IVTimelineItem]
        
    // 合成的回放文件（用于时间轴渲染）
    private(set) var items: [IVTimelineItem] = []

    // 时间轴缩放比例（每秒占多少像素点(pix/sec)）
    private(set) var scale: Double = 1
    
    init(_ time: IVTime, rawItems: [IVTimelineItem], scale: Double) {
        self.time = time
        // 过滤小于1秒的文件
        self.rawItems = rawItems.filter({ $0.duration >= 1.0 })
        self.redraw(toFit: scale)
    }
            
    var isPlaceholder: Bool { rawItems.first?.isPlaceholder ?? true }
    var isValid: Bool { !isPlaceholder }

    // 插入原始回放文件（用于插入头部跨界文件）
    mutating func insertItemAtStartIndex(_ item: IVTimelineItem) {
        guard item.isValid, item.start <= start else {
            return
        }
        if isPlaceholder {
            rawItems.removeAll()
        }
        rawItems.insert(item, at: rawItems.startIndex)
    }

    /// 更新块大小
    /// - Parameter scale: 时间轴缩放比例（每秒占多少像素点(pix/sec)）
    fileprivate
    mutating func redraw(toFit scale: Double) {
        // minimum: 1pix or 1sec
        let minDuration = max(1/scale, 1.0)
        // maximum: 200pix or 4hour
        let maxDuration = min(200/scale, 4*60*60)
  
        // 0. 临时缓存
        var items = rawItems
        
        if items.count > 1 {
            // 1. 合并相邻的 同类型&&(小间距||重叠) 的块
            for i in (1..<items.count).reversed() {
                let isSameType = items[i-1].type == items[i].type
                let isOverlap  = items[i].start <= items[i-1].end
                let isClosely  = items[i].start - items[i-1].end <= minDuration
                if isSameType && (isOverlap || isClosely) {
                    items[i-1].end  = items[i].end
                    items[i-1].duration = items[i-1].end - items[i-1].start
                    items.remove(at: i)
                }
            }
            
            for i in (1..<items.count).reversed() {
                let diff = items[i].start - items[i-1].end
                if diff > minDuration {
                    // 2.1 填充大缝隙
                    let padding = IVTimelineItem.padding(start: items[i-1].end, end: items[i].start)
                    items.insert(padding, at: i)
                } else if diff > 0 {
                    // 2.2 小间隙合到items[i-1]末尾
                    items[i-1].end = items[i].start
                    items[i-1].duration = items[i-1].end - items[i-1].start
                } else {
                    // 2.3 修正重叠的不同类型的块
                    if items[i-1].isValid {
                        items[i].start = items[i-1].end
                        items[i].duration = items[i].end - items[i].start
                    } else {
                        items[i-1].end = items[i].start
                        items[i-1].duration = items[i-1].end - items[i-1].start
                    }
                }
            }
        }
        
        // 有文件才填充尾部
        if items.count > 0 {
            if items.last!.end < time.end {
                // 3.1 填充尾部缝隙
                let padding = IVTimelineItem.padding(start: items.last!.end, end: time.end)
                items.insert(padding, at: items.endIndex)
            } else {
                // 3.2 修剪尾部跨日期的文件
                items[items.count-1].end = time.end
                items[items.count-1].duration = items[items.count-1].end - items[items.count-1].start
            }
        }
    
        let t1 = (items.first?.start ?? time.end)
        if time.start < t1 {
            // 4.1 填充头部缝隙(无文件||有间隔)
            let padding = IVTimelineItem.padding(start: time.start, end: t1)
            items.insert(padding, at: items.startIndex)
        } else {
            // 4.2 修剪头部跨日期的文件
            items[0].start = time.start
            items[0].duration = items[0].end - items[0].start
        }

        for i in (0..<items.count).reversed() {
            if items[i].duration < minDuration {
                if items[i].isValid {
                    // 5.1.1 有效文件太小，向相临块借一点
                    let diff = minDuration - items[i].duration
                    let dstIdx = i>0 ? i-1 : i+1
                    if i > 0 {
                        items[dstIdx].end -= diff
                        items[i].start -= diff
                    } else {
                        items[dstIdx].start += diff
                        items[i].end += diff
                    }
                    items[dstIdx].duration = items[dstIdx].end - items[dstIdx].start
                    items[i].duration = items[i].end - items[i].start
                } else {
                    // 5.1.1 填充块太小，合并到相临块
                    let dstIdx = i>0 ? i-1 : i+1
                    if i > 0 {
                        items[dstIdx].end   = items[i].end
                    } else {
                        items[dstIdx].start = items[i].start
                    }
                    items[dstIdx].duration  = items[dstIdx].end - items[dstIdx].start
                    items.remove(at: i)
                }
            } else if items[i].duration > maxDuration {
                // 5.2 等分切割成不超过`maxDuration`的块
                let splitCount = ceil(items[i].duration / maxDuration)
                let splitDuration = items[i].duration / splitCount
                while items[i].duration > maxDuration {
                    let subitem = IVTimelineItem(start: items[i].end - splitDuration, end: items[i].end, type: items[i].type, rawValue: nil)
                    items.insert(subitem, at: i+1)
                    items[i].end  -= splitDuration
                    items[i].duration -= splitDuration
                }
            }
        }
        
        self.scale = scale
        self.items = items
    }

    static func placeholder(_ time: IVTime, scale: Double) -> IVTimelineSection  {
        return IVTimelineSection(time, rawItems: [.placeholder(start: time.start, end: time.end)], scale: scale)
    }
}

/// 时间轴状态
enum IVTimelineState {
    /// 自动跟踪
    case tracking
    /// 手动拖动
    case dragging
    /// 手动缩放
    case zooming
    /// 选择时段
    case selecting
}

class IVTimelineViewModel {
    /// 所有数据源
    private(set) var sections: [IVTimelineSection] = []
    
    /// 当前数据源
    private(set) var current: IVTimelineSection
     
    /// 时间戳
    private(set) var pts: TimeInterval
    
    /// 当前文件
    var currentRawItem: IVTimelineItem? {
        if !current.isValid { return nil }
        return current.rawItems.first(where: { $0.contains(pts) })
    }
    
    /// 下一个文件
    var nextRawItem: IVTimelineItem? {
        if let nextIdx = current.rawItems.firstIndex(where: { $0.start >= pts }) {
            return current.rawItems[nextIdx]
        } else {
            if let nextSection = sections.first(where: { $0.time == current.after(days: 1) }), nextSection.isValid {
                return nextSection.rawItems.first
            }
        }
        return nil
    }
    
    /// 给定时间范围的第一个文件
    func nextRawItem(greaterThan gt: TimeInterval, lessThan lt: TimeInterval) -> IVTimelineItem? {
        if let nextIdx = current.rawItems.firstIndex(where: { $0.start > gt && $0.start < lt}) {
            return current.rawItems[nextIdx]
        } else {
            if let nextSection = sections.first(where: { $0.time == current.after(days: 1) }),
               let nextItem = nextSection.rawItems.first, nextItem.start > gt && nextItem.start < lt {
                return nextItem
            }
        }
        return nil
    }

    /// 当前/下一个文件
    var anyRawItem: IVTimelineItem? {
        return currentRawItem ?? nextRawItem
    }
    
    /// (放大)时间轴最大比例（最大每秒占多少像素点(pix/sec)）
    let maximumScale = 5.0
    
    /// (缩小)时间轴最小比例（最小每秒占多少像素点(pix/sec)）
    let minimumScale = 0.01
    
    /// 时间轴缩放比例（每秒占多少像素点(pix/sec)）
    private(set)
    var scale: Double = 0.034

    /// 时间轴渲染状态
    public var state: IVObservable<IVTimelineState> = .init(.tracking)

    /// 构造方法
    init(time: IVTime) {
        pts = time.start
        current = .placeholder(time, scale: scale)
    }

    func update(scale: Double) -> Bool {
        if (scale <= minimumScale && self.scale <= minimumScale) {
            return false
        }

        if (scale >= maximumScale && self.scale >= maximumScale) {
            return false
        }
        
        self.scale = min(max(scale, minimumScale), maximumScale)
//        logVerbose("update(scale:\(self.scale))")
        let scalerate = self.scale / current.scale
        if scalerate >= 2.0 || scalerate <= 0.5 {
            logDebug(String(format: "scale: %f %f", self.scale, current.scale))
            current.redraw(toFit: self.scale)
        }
        return true
    }

    func update(pts: TimeInterval, needsScroll: Bool = true) {
//        logVerbose("update(pts:\(pts), needsScroll:\(needsScroll))")
        self.pts = pts
        if needsScroll, state.value != .selecting {
            scrollToTimeIfNeed?(pts, current.time)
        }
    }

    var scrollToTimeIfNeed: ((_ pts: TimeInterval, _ sectionTime: IVTime) -> Void)?
    
    /// 插入数据源
    func insertSection(items: [IVTimelineItem], for time: IVTime) {
        // 按时间升序
        let sortedItems = items.sorted { $0.start < $1.start }

        // 插入数据
        let section = IVTimelineSection(time, rawItems: sortedItems, scale: scale)
        let newIdx = sections.firstIndex(where: { $0.time.start >= time.end }) ?? 0
        sections.insert(section, at: newIdx)
        
        // 更新当前数据源
        if current.time == time && current.isPlaceholder {
            loadSection(for: time)
        }
    }
    
    /// 加载数据源
    func loadSection(for time: IVTime) {
        let newSec = sections.first(where: { $0.time == time })
        if (current.time != time) || (current.isPlaceholder && newSec != nil) {
            current = newSec ?? .placeholder(time, scale: scale)
            
            if !current.isPlaceholder {
                // 前一个section末尾文件跨越section
                let lastday = current.before(days: 1)
                if let lastItem = sections.first(where: { $0.time == lastday })?.rawItems.last,
                    lastItem.isValid, lastItem.end > current.start {
                    current.insertItemAtStartIndex(lastItem)
                }
            }
            
            current.redraw(toFit: self.scale)
        }
    }
}



