//
//  IVTimelineView.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/1/8.
//  Copyright © 2020 Tencentcs. All rights reserved.
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
            print("dTime \(currentTime) \(oldValue) \(currentTime - oldValue)")
            refreshRefreshTimeline(currentTime)
        }
    }
    
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
        col.backgroundColor = UIColor.clear
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
        addSubview(collectionView)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(collectionView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.reloadData()
    }
}

private extension IVTimelineView {
    
    func refreshRefreshTimeline(_ time: TimeInterval) {
        DispatchQueue.main.async {
            if self.collectionView.isDragging {
                print("isDragging")
                return
            }
            if self.collectionView.isTracking {
                print("isTracking")
                return
            }
            if self.collectionView.isDecelerating {
                print("isDecelerating")
                return
            }

            guard let first = self.dataSource.first else { return }
            let offset = CGFloat(time - first.startTime) * CGFloat(self.scale)

            let point = CGPoint(x: offset, y: self.collectionView.contentOffset.y)
            self.collectionView.setContentOffset(point, animated: true)
        }
    }
    
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
    }
    
    private func didScrollHandler() {
        for cell in collectionView.visibleCells {
            let newRect = collectionView.convert(cell.frame, to: self)
            let newCenter = collectionView.center
            
            guard newRect.contains(newCenter),
                let indexPath = collectionView.indexPath(for: cell) else {
                    continue
            }
            
            let slice = timeSlices[indexPath.row]
            
            // 间隙不处理
            if slice.type == "gap" { return }
            
            guard let item = dataSource.first(where: { $0.startTime <= slice.startTime && $0.endTime >= slice.endTime }) else {
                print("没找到对应数据")
                return
            }
            
            let width0 = (slice.startTime - item.startTime) * scale
            let width1 = Double(newCenter.x - newRect.origin.x)
            let offset = width0 + width1
            let time = round(item.startTime + offset/scale)
            
            delegate?.timelineView(self, didSelect: item, at: time)
            return
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
        return CGSize(width: bounds.width/2, height: bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: bounds.width/2, height: bounds.height)
    }
}

extension IVTimelineView: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.isDecelerating || decelerate { return }
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
        removeAllTextLayer()
        showTimeMarks = IVTimeMark.all.filter { scale * Double($0.rawValue) >= 4.8 } // 距离大于 4.8 pt
        setNeedsDisplay()
    }

    /// === 数据模型 ===
    private var item: IVTimelineItem!
    
    /// === 缩放比例 ===
    private var scale = 1.0

    /// === 时间刻度 ===
    private var showTimeMarks: [IVTimeMark] = [.hour]
    
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
   
    private func FontSize(of mark: IVTimeMark) -> CGFloat {
        var fontSize: CGFloat
        if mark.rawValue >= IVTimeMark.hour.rawValue {
            fontSize = CGFloat(CGFloat(mark.rawValue) * CGFloat(scale) / 800) * 20
            fontSize = fontSize < 14 ? 14 : (fontSize > 20 ? 20 : fontSize)
        } else if mark.rawValue >= IVTimeMark.min1.rawValue  {
            fontSize = CGFloat(CGFloat(mark.rawValue) * CGFloat(scale) / 800) * 17
            fontSize = fontSize < 12 ? 12 : (fontSize > 17 ? 17 : fontSize)
        } else {
            fontSize = CGFloat(CGFloat(mark.rawValue) * CGFloat(scale) / 800) * 15
            fontSize = fontSize < 8 ? 8 : (fontSize > 15 ? 15 : fontSize)
        }
        return fontSize
    }
    
    private func TimeOffset(of mark: IVTimeMark) -> TimeInterval {
        let remain: TimeInterval = item.startTime - floor(item.startTime) // 小数点后的余数
        let mod: TimeInterval = TimeInterval(Int(item.startTime) % mark.rawValue) + remain // 小数点后的余数
        let offset: TimeInterval = mod > 0.001 ? TimeInterval(mark.rawValue) - mod : 0
        return offset
    }
    
    private func DateFormat(of mark: IVTimeMark) -> String {
        return mark < .min1 ? "ss" : "HH:mm"
    }
    
    private func LabelWidth(of mark: IVTimeMark) -> CGFloat {
        let text = DateFormat(of: mark) as NSString
        let width = text.boundingRect(with: CGSize(width: 100, height: 20),
                                      options: .usesFontLeading,
                                      attributes: [.font : UIFont.systemFont(ofSize: FontSize(of: mark))],
                                      context: nil).width
        return max(width, 30)
        //        return FontSize(of: mark) * CGFloat(DateFormat(of: mark).count)
    }

    private func MarkHeight(of mark: IVTimeMark) -> Double {
        switch mark {
        case .hour8, .hour4, .hour2, .hour: return 20
        case .min30: return 18
        case .min10: return 16
        case .min5, .min1: return 14
        case .sec30: return 12
        case .sec10: return 10
        case .sec5, .sec1: return 8
        }
    }
    
    private func StrokeColor(of mark: IVTimeMark) -> UIColor {
        let alpha = ((CGFloat(mark.rawValue) * CGFloat(scale) - 2) / 200) + 0.2
        let color = UIColor(white: 0, alpha: alpha)
        return color
    }
    
    private func removeAllTextLayer() {
        layer.sublayers?.forEach({
            if $0.name == "textLayer" { $0.removeFromSuperlayer() }
        })
    }
    
    private func addTextLayer(frame: CGRect, text: String, color: UIColor, fontSize: CGFloat) {
        let timeLayer = CATextLayer()
        timeLayer.frame = frame
        timeLayer.string = text
        timeLayer.alignmentMode = .center
        timeLayer.foregroundColor = color.cgColor
        timeLayer.fontSize = fontSize
        timeLayer.contentsScale = UIScreen.main.scale
        timeLayer.name = "textLayer"
        layer.addSublayer(timeLayer)
    }
    
    // === 刻度\文字 ===
    private func drawTimelineMark(_ ctx: CGContext?, mark: IVTimeMark) {
        let markHeight = MarkHeight(of: mark)
        var offset = TimeOffset(of: mark)
        
        let color = StrokeColor(of: mark)
        let fontSize = FontSize(of: mark)
        
        let fmt = DateFormatter()
        fmt.dateFormat = DateFormat(of: mark)

        let labelWidth = LabelWidth(of: mark)
        let showText = CGFloat(mark.rawValue) * CGFloat(scale) > labelWidth
        
        ctx?.setLineWidth(1)
        ctx?.setStrokeColor(color.cgColor)
        
        while offset <= item.duration {
            if mark.upperMark == nil || Int(item.startTime + offset) % mark.upperMark!.rawValue != 0 {
                ctx?.move(to: CGPoint(x: scale * offset, y: 0))
                ctx?.addLine(to: CGPoint(x: scale * offset, y: markHeight))
                
                if showText, mark >= .sec10 {
                    for divisor in IVTimeMark.divisors {
                        if Int(item.startTime + offset) % divisor == 0 {
                            addTextLayer(frame: CGRect(x: CGFloat(scale * offset)-labelWidth/2, y: bounds.height-20, width: labelWidth, height: 20),
                                         text: fmt.string(from: Date(timeIntervalSince1970: item.startTime + offset)),
                                         color: color,
                                         fontSize: fontSize)
                            break
                        }
                    }
                }
            }
            
            offset += Double(mark.rawValue)
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

        showTimeMarks.forEach { (mark) in
            drawTimelineMark(ctx, mark: mark)
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

enum IVTimeMark: Int, Comparable {
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
    
    var upperMark: IVTimeMark? { return IVTimeMark.all.reversed().first(where: { $0 > self }) }
    
    static let divisors = [1, 2, 3, 5]

    static let all: [IVTimeMark] = [.hour8, .hour4, .hour2, .hour, .min30, .min10, .min5, .min1, .sec30, .sec10, .sec5, .sec1]

    static func < (lhs: IVTimeMark, rhs: IVTimeMark) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    static func > (lhs: IVTimeMark, rhs: IVTimeMark) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }
}
