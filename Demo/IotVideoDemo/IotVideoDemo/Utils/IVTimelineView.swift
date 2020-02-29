//
//  IVTimelineView.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/1/8.
//  Copyright © 2020 gwell. All rights reserved.
//

import UIKit

struct IVTimelineItem {
    let startTime: TimeInterval
    let endTime: TimeInterval
    let duration: TimeInterval
    let type: String
    let color: UIColor
}

protocol IVTimelineViewDelegate: class {
    /// 滚动或者点击时间轴片段
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - item: 时间片段
    ///   - time: 时间值（标准时间，不是偏移量）
    func timelineView(_ timelineView: IVTimelineView, didSelect item: IVTimelineItem, at time: TimeInterval)
}

class IVTimelineView: UIView {
    
    /// 时间轴事件代理
    weak var delegate: IVTimelineViewDelegate?
    
    /// 时间轴最大缩放比例（最大每秒占多少像素点(pix/sec)）
    let maximumScale = 5.0
    
    /// 时间轴最小缩放比例（最小每秒占多少像素点(pix/sec)）
    let minimumScale = 0.005
    
    /// 时间轴缩放比例（每秒占多少像素点(pix/sec)）
    var scale = 1.0 {
        didSet {
            if scale > maximumScale {
                scale = maximumScale
            } else if scale < minimumScale {
                scale = minimumScale
            }
            
            if oldValue == scale {
                return
            }

            let offsetX = collectionView.contentOffset.x
            collectionView.reloadData()
            let pinchScale = scale / oldValue
            collectionView.contentOffset.x = offsetX * CGFloat(pinchScale)
        }
    }
    
    /// 时间轴当前时间
    var currentTime: TimeInterval = 0 {
        didSet {
            DispatchQueue.main.async {
                if self.hoverTime > 0 { return }

                guard let first = self.dataSource.first else { return }
                let offset = CGFloat(self.currentTime - first.startTime) * CGFloat(self.scale)
                self.collectionView.contentOffset.x = offset
            }
        }
    }
    
    /// 滚动之后视图悬停时间
    var hoverTime: TimeInterval = 0
    
    /// 缩放手势
    lazy var pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureHandler(_:)))
    
    /// 时间轴布局
    lazy var timelineLayout = IVTimelineLayout()
    
    /// 时间轴容器视图
    lazy var collectionView: UICollectionView = {
        let col = UICollectionView(frame: self.bounds, collectionViewLayout: timelineLayout)
        col.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        col.register(IVTimelineCell.self, forCellWithReuseIdentifier: "IVTimelineCell")
        col.register(IVTimelineHeaderFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: UICollectionView.elementKindSectionHeader)
        col.register(IVTimelineHeaderFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: UICollectionView.elementKindSectionFooter)
        col.showsHorizontalScrollIndicator = false
        col.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 100, bottom: 0, right: 100)
        col.backgroundColor = UIColor(white: 0.95, alpha: 1)
        col.dataSource = self
        col.delegate   = self
        col.addGestureRecognizer(pinchGesture)
        return col
    }()
    
    /// 原始时间段（保存外面传入的原始时间段）
    private(set) var dataSource: [IVTimelineItem] = []
    
    /// 时间片段（用于优化显示性能）
    private var timeSlices: [IVTimelineItem] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.reloadData()
            }
        }
    }
    
    /// 时间片最大10分钟 (太大影响放大性能，太小影响缩小性能)
    let maxDuration: TimeInterval  = 10*60
    
    /// 时间片最小0.001秒
    let miniDuration: TimeInterval = 0.001

    /// 设置数据源
    func setDataSource(_ items: [IVTimelineItem]) {
        let sortedItems = items.sorted { $0.startTime < $1.startTime }
        dataSource = sortedItems
        timeSlices = makeTimelineSlices(sortedItems)
    }
    
    /// 插入数据源
    func insertDataSource(_ items: [IVTimelineItem]) {
        if items.isEmpty { return }
        
        let sortedItems = items.sorted { $0.startTime < $1.startTime }
        
        // 1. 时序化
        let slices = makeTimelineSlices(sortedItems)
        
        if dataSource.isEmpty {
            dataSource.append(contentsOf: sortedItems)
            timeSlices.append(contentsOf: slices)
            return
        }
        // 3.拼接列表
        if let last = timeSlices.last, sortedItems.first!.startTime >= last.startTime {
            // a.尾部插入
            if let gapSlices = makeGapSlices(lhs: last, rhs: sortedItems.first!) {
                timeSlices.insert(contentsOf: gapSlices, at: timeSlices.endIndex)
            }
            dataSource.insert(contentsOf: sortedItems, at: dataSource.endIndex)
            timeSlices.insert(contentsOf: slices, at: timeSlices.endIndex)
        } else if let first = timeSlices.first, sortedItems.last!.startTime <= first.startTime {
            // b.头部插入
            if let gapSlices = makeGapSlices(lhs: sortedItems.last!, rhs: first) {
                timeSlices.insert(contentsOf: gapSlices, at: timeSlices.startIndex)
            }
            dataSource.insert(contentsOf: sortedItems, at: dataSource.startIndex)
            timeSlices.insert(contentsOf: slices, at: timeSlices.startIndex)
        } else {
            logError("数据异常 datasource:\(dataSource), timeSlices:\(timeSlices) items:\(sortedItems)")
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0.95, alpha: 1)
        addSubview(collectionView)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(collectionView)
    }
    
    @objc func pinchGestureHandler(_ pinch: UIPinchGestureRecognizer) {
        //放大情况
        if pinch.scale > 1.0 {
            if self.scale >= maximumScale {
                ivHud("不能再放大啦")
                return
            }
        }
        
        //缩小情况
        if pinch.scale < 1.0 {
            if self.scale <= minimumScale {
                ivHud("不能再缩小啦")
                return
            }
        }
                
        if pinch.state == .began || pinch.state == .changed {
            self.scale *= Double(pinch.scale)
            pinch.scale = 1
        }
        
        print(self.scale)
    }
}

private extension IVTimelineView {
    
    /// 切割大块时间段
    func fragmentTimelineItem(_ item: IVTimelineItem) -> [IVTimelineItem]? {
        var items: [IVTimelineItem] = []
        
        var duration = item.duration
        var t0  = item.startTime
        
        // 切割大块间隙
        while duration > maxDuration {
            let t1 = t0 + maxDuration
            let subItem = IVTimelineItem(startTime: t0,
                                         endTime: t1,
                                         duration: maxDuration,
                                         type: item.type,
                                         color: item.color)
            items.append(subItem)
            t0 = t1
            duration -= maxDuration
        }
        
        if duration > miniDuration {
            let subItem = IVTimelineItem(startTime: t0,
                                         endTime: t0 + duration,
                                         duration: duration,
                                         type: item.type,
                                         color: item.color)
            items.append(subItem)
        }
        
        return items.isEmpty ? nil : items
    }
    
    /// 生成间隙
    func makeGapSlices(lhs:IVTimelineItem, rhs:IVTimelineItem) -> [IVTimelineItem]? {
        let gapItem = IVTimelineItem(startTime: lhs.endTime,
                                     endTime: rhs.startTime,
                                     duration: rhs.startTime - lhs.endTime,
                                     type: "gap",
                                     color: .white)
        return fragmentTimelineItem(gapItem)
    }
    
    /// 生成时间轴切片
    func makeTimelineSlices(_ items: [IVTimelineItem]) -> [IVTimelineItem] {
        var items = items
        if items.isEmpty { return [] }
        // 2.切割大块文件
        let fragments = items.map({ fragmentTimelineItem($0)})
        // 3.去除nil
        let compactRes = fragments.compactMap { $0 }
        // 4.还原成一维数组
        items = compactRes.flatMap { $0 }
        // 5.插入空隙
        if items.count > 1 {
            let maxIdx = items.count-1
            for i in 0 ..< maxIdx {
                if let gapItems = makeGapSlices(lhs: items[maxIdx-i-1], rhs: items[maxIdx-i]) {
                    items.insert(contentsOf: gapItems, at: maxIdx-i)
                }
            }
        }
        return items
    }
    
    func didScrollHandler() {
        DispatchQueue.main.async {
            self.hoverTime += 1
            DispatchQueue.main.asyncAfter(deadline: .now()+1) { [weak self] in
                guard let `self` = self else { return }
                self.hoverTime -= 1
                if self.hoverTime > 0 { return }

                for cell in self.collectionView.visibleCells {
                    let newRect = self.collectionView.convert(cell.frame, to: self)
                    let newCenter = self.collectionView.center
                    
                    guard newRect.contains(newCenter),
                        let indexPath = self.collectionView.indexPath(for: cell) else {
                            continue
                    }
                    
                    let slice = self.timeSlices[indexPath.row]
                    
                    // 间隙不处理
                    if slice.type == "gap" { return }
                    
                    guard let item = self.dataSource.first(where: { $0.startTime <= slice.startTime && $0.endTime >= slice.endTime }) else {
                        print("没找到对应数据")
                        return
                    }
                    
                    let width0 = (slice.startTime - item.startTime) * self.scale
                    let width1 = Double(newCenter.x - newRect.origin.x)
                    let offset = width0 + width1
                    let time = round(item.startTime + offset/self.scale)
                    
                    logInfo("seek: \(item.startTime) => \(time)")
                    self.delegate?.timelineView(self, didSelect: item, at: time)
                }
            }
        }
    }
}

extension IVTimelineView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return timeSlices.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IVTimelineCell", for: indexPath) as! IVTimelineCell
        cell.setTimelineItem(timeSlices[indexPath.row], scale: scale)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerfooter = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath) as! IVTimelineHeaderFooter
        if kind == UICollectionView.elementKindSectionHeader {
            headerfooter.tips.text = "到头啦👉"
        } else {
            headerfooter.tips.text = "👈到尾啦"
        }
        return headerfooter
    }
}


extension IVTimelineView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let slice = timeSlices[indexPath.row]
        
        // 间隙不处理
        if slice.type == "gap" { return }
        
        guard let item = dataSource.first(where: { $0.startTime <= slice.startTime && $0.endTime >= slice.endTime }) else {
            print("没找到对应数据")
            return
        }
        
        delegate?.timelineView(self, didSelect: item, at: item.startTime)
    }
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemW = CGFloat(timeSlices[indexPath.row].duration * scale)
        return CGSize(width: itemW, height: bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.bounds.width/2, height: self.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: self.bounds.width/2, height: self.bounds.height)
    }
}

extension IVTimelineView: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate { return }
        didScrollHandler()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didScrollHandler()
    }
    
}

class IVTimelineCell: UICollectionViewCell {
    
    func setTimelineItem(_ item: IVTimelineItem, scale: Double) {
        self.item = item
        self.scale = scale
        colorView.backgroundColor = item.color
        markView.subviews.forEach({
            $0.removeFromSuperview()
        })
        timeMarks = IVTimeMark.all.filter { scale * Double($0.rawValue) >= 4.8 } // 距离大于 4.8 pt
        setNeedsDisplay()
    }

    /// === 数据模型 ===
    private var item: IVTimelineItem!
    
    /// === 缩放比例 ===
    private var scale = 1.0

    /// === 时间刻度 ===
    private var timeMarks: [IVTimeMark] = [.hour]
    
    // === 颜色 ===
    private lazy var colorView: UIView = {
        let v = UIView()
        // pix1是为了防止出现缝隙
        let pix1 = 1 / UIScreen.main.scale
        v.frame = CGRect(x: 0, y: bounds.height / 3, width: bounds.width + pix1, height: bounds.height / 3)
        v.autoresizingMask = .flexibleWidth
        addSubview(v)
        return v
    }()
    
    // === 刻度\文字 ===
    private lazy var markView: UIView = {
        let v = UIView(frame: bounds)
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        v.backgroundColor = .clear
        addSubview(v)
        return v
    }()
    
    private func drawTimelineMark(_ ctx: CGContext?, step: Int, superStep: Int, color: UIColor, fontSize: CGFloat, markHeight: Double) {
        let remain: TimeInterval = item.startTime - floor(item.startTime) // 小数点后的余数
        let mod: TimeInterval = TimeInterval(Int(item.startTime) % step) + remain // 小数点后的余数
        var offset: TimeInterval = mod > 0.001 ? TimeInterval(step) - mod : 0
        
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
                     
        let labelWidth = Double(fontSize) * Double(fmt.dateFormat.count)
        
        ctx?.setLineWidth(1)
        ctx?.setStrokeColor(color.cgColor)
        
        while offset <= item.duration {
            if superStep == 0 || Int(item.startTime + offset) % superStep != 0 {
                ctx?.move(to: CGPoint(x: scale * offset, y: 0))
                ctx?.addLine(to: CGPoint(x: scale * offset, y: markHeight))
                
                if step >= IVTimeMark.min1.rawValue {
                    for divisor in IVTimeMark.divisors {
                        if Double(step) * scale > labelWidth, Int(item.startTime + offset) % divisor == 0 {
                            let label = UILabel()
                            label.frame = CGRect(x: (scale * offset)-labelWidth/2, y: Double(bounds.height-20), width: labelWidth, height: 20)
                            label.text = fmt.string(from: Date(timeIntervalSince1970: item.startTime + offset))
                            label.textColor = color
                            label.textAlignment = .center
                            label.font = .systemFont(ofSize: fontSize)
                            label.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
                            markView.addSubview(label)
                            break
                        }
                    }
                }
            }
            
            offset += Double(step)
        }
        
        ctx?.strokePath()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.clear(rect)

        for mark in timeMarks {
            let step = mark.rawValue
                        
            switch mark {
            case .hour8:
                drawTimelineMark(ctx, step: step, superStep: 0, color: .black, fontSize: 14, markHeight: 20)
            case .hour4:
                drawTimelineMark(ctx, step: step, superStep: step*2, color: .black, fontSize: 14, markHeight: 20)
            case .hour2:
                drawTimelineMark(ctx, step: step, superStep: step*2, color: .black, fontSize: 14, markHeight: 20)
            case .hour:
                drawTimelineMark(ctx, step: step, superStep: step*2, color: .black, fontSize: 14, markHeight: 20)
            case .min30:
                drawTimelineMark(ctx, step: step, superStep: step*2, color: .darkGray, fontSize: 12, markHeight: 17)
            case .min10:
                drawTimelineMark(ctx, step: step, superStep: step*3, color: .darkGray, fontSize: 12, markHeight: 14)
            case .min5:
                drawTimelineMark(ctx, step: step, superStep: step*2, color: .darkGray, fontSize: 12, markHeight: 12)
            case .min1:
                drawTimelineMark(ctx, step: step, superStep: step*5, color: .darkGray, fontSize: 12, markHeight: 12)
            case .sec30:
                drawTimelineMark(ctx, step: step, superStep: step*2, color: .gray, fontSize: 0, markHeight: 10)
            case .sec10:
                drawTimelineMark(ctx, step: step, superStep: step*3, color: .gray, fontSize: 0, markHeight: 8)
            case .sec5:
                drawTimelineMark(ctx, step: step, superStep: step*2, color: .lightGray, fontSize: 0, markHeight: 5)
            case .sec1:
                drawTimelineMark(ctx, step: step, superStep: step*5, color: .lightGray, fontSize: 0, markHeight: 5)
            }
        }
        
    }
}

class IVTimelineHeaderFooter: UICollectionReusableView {
    lazy var tips: UILabel = {
        let lb = UILabel(frame: bounds)
        lb.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        lb.text = "没有更多了"
        lb.textColor = .red
        lb.textAlignment = .center
        lb.font = .systemFont(ofSize: 14)
        return lb
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tips)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class IVTimelineLayout: UICollectionViewFlowLayout {
    
    var layoutAttributes: [UICollectionViewLayoutAttributes] = []
    
    override init() {
        super.init()
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        scrollDirection = .horizontal
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum IVTimeMark: Int {
    case hour8    = 28800 // 60*60*8
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
    
    static let divisors = [1, 2, 3, 5]

    static let all: [IVTimeMark] = [.hour8, .hour4, .hour2, .hour, .min30, .min10, .min5, .min1, .sec30, .sec10, .sec5, .sec1]
}
