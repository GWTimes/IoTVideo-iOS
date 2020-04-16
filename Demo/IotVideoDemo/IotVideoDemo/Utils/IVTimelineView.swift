//
//  IVTimelineView.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/1/8.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit

protocol IVTiming: Equatable {
    var start: TimeInterval { get }
    var end: TimeInterval { get }
    var duration: TimeInterval { get }
}

extension IVTiming {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return abs(lhs.start - rhs.start) < 0.0001 && abs(lhs.end - rhs.end) < 0.0001
    }
}

struct IVTimelineGroup {
    let time: IVTime
    let items: [IVTimelineItem] // 一定会有至少一个元素
    
    init(_ time: IVTime, _ items: [IVTimelineItem]) {
        self.time  = time
        self.items = items.isEmpty ? [.placeholder] : items
    }
    
    var isPlaceholder: Bool { return items[0].isPlaceholder }
    
    static func placeholder(_ time: IVTime) -> IVTimelineGroup  {
        return IVTimelineGroup(time, [.placeholder])
    }
    
    var validFilesCnt: UInt { items.reduce(0, { $0 + ($1.isValid ? 1 : 0) }) }

    var summaryString: String {
        return String(format: "%@ ▽     文件数:%d", time.dateString, validFilesCnt)
    }
}

/// 时间片最大10分钟 (太大影响放大性能，太小影响缩小性能)
let maxDuration: TimeInterval  = 10*60
/// 时间片最小0.001秒
let miniDuration: TimeInterval = 0.001

struct IVTimelineItem: IVTiming {
    
    let start: TimeInterval
    let end: TimeInterval
    let duration: TimeInterval
    
    let type: String
    let color: UIColor
    let rawValue: Any?
    
    private(set)
    lazy var fragments: [IVTimelineFragment] = splitIntoFragments()

    init?(start: TimeInterval, end: TimeInterval, type: String, color: UIColor, rawValue: Any?) {
        self.start = start
        self.end = end
        self.duration = end - start
        
        if self.duration < miniDuration {
            return nil
        }
        
        self.type = type
        self.color = color
        self.rawValue = rawValue
    }
    
    var isPadding: Bool { type == "padding" }
    var isPlaceholder: Bool { type == "placeholder" }
    var isValid: Bool { !isPadding && !isPlaceholder }

    static func padding(start: TimeInterval, end: TimeInterval) -> IVTimelineItem? {
        return IVTimelineItem(start: start, end: end, type: "padding", color: .white, rawValue: nil)
    }
    
    static var placeholder: IVTimelineItem {
        return IVTimelineItem(start: 0, end: miniDuration*2, type: "placeholder", color: .white, rawValue: nil)!
    }
    
    /// 切割大块时间段
    func splitIntoFragments() -> [IVTimelineFragment] {
        var fragments: [IVTimelineFragment] = []
        
        var duration = self.duration
        var t0  = self.start
        
        // 切割大块间隙
        while duration > maxDuration {
            let t1 = t0 + maxDuration
            let fg = IVTimelineFragment(start: t0, end: t1, item: self)
            fragments.append(fg)
            t0 = t1
            duration -= maxDuration
        }
        
        // 剩余小块
        if duration > miniDuration {
            let fg = IVTimelineFragment(start: t0, end: t0 + duration, item: self)
            fragments.append(fg)
        }
        
        return fragments
    }
}

struct IVTimelineFragment: IVTiming {
    let start: TimeInterval
    let end: TimeInterval
    let duration: TimeInterval
    let item: IVTimelineItem
    
    init(start: TimeInterval, end: TimeInterval, item: IVTimelineItem) {
        self.start = start
        self.end = end
        self.duration = end - start
        self.item = item
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
        let calendar = Calendar.current
        let ymd = calendar.dateComponents([.year, .month, .day], from: date)
        let date = calendar.date(from: ymd)!
        let t0 = date.timeIntervalSince1970
        let t1 = t0 + (86400 - 1)
        self.init(start: t0, end: t1)
    }
        
    static let today = IVTime(date: Date())
    
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
}

protocol IVTimelineViewDelegate: class {
    /// 滚动或者点击时间轴片段
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - item: 时间片段
    ///   - time: 时间值（标准时间，不是偏移量）
    func timelineView(_ timelineView: IVTimelineView, didSelect item: IVTimelineItem, at time: TimeInterval)
    
    /// 数据源
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - time: 时间片段
    ///   - completionHandler: 数据获取完成回调
    func timelineView(_ timelineView: IVTimelineView, itemsForTimelineAt time: IVTime, completionHandler: @escaping ([IVTimelineItem]?) -> Void)
}

class IVTimelineView: UIView {
    
    // MARK: - Property

    /// 时间轴事件代理
    weak var delegate: IVTimelineViewDelegate?
    
    /// 时间轴最大缩放比例（最大每秒占多少像素点(pix/sec)）
    let maximumScale = 5.0
    
    /// 时间轴最小缩放比例（最小每秒占多少像素点(pix/sec)）
    let minimumScale = 0.005
    
    /// 时间轴缩放比例（每秒占多少像素点(pix/sec)）
    private(set)
    var scale = 1.0 {
        didSet {
            scale = max(minimumScale, min(maximumScale, scale))
                        
            if oldValue == scale {
                return
            }
            
            let offsetX = collectionView.contentOffset.x
            collectionView.reloadData()
            let pinchScale = scale / oldValue
            collectionView.contentOffset.x = offsetX * CGFloat(pinchScale)
        }
    }
                    
    /// 所有文件数据源
    private(set)
    var dataSource: [IVTimelineGroup] = []

    /// 当前文件组
    private(set)
    var currentGroup: IVTimelineGroup = .placeholder(.today) {
        willSet {
            DispatchQueue.main.async {[weak self] in
                self?.dateBtn.setTitle(newValue.summaryString , for: .normal)
                self?.currentItem = self?.nextItem ?? .placeholder
            }
        }
    }
    
    /// 当前文件
    private(set)
    var currentItem: IVTimelineItem = .placeholder
            
    /// 当前播放时间（UTC标准时间）
    var currentPTS: TimeInterval = 0 {
        didSet {
            logVerbose("currentPTS new:\(currentPTS) old:\(oldValue) diff:\(currentPTS - oldValue)")
            
            if currentPTS < currentGroup.time.start {
                loadAndDisplayItems(at: currentGroup.time.before(days: 1))
            } else if currentPTS > currentGroup.time.end {
                loadAndDisplayItems(at: currentGroup.time.after(days: 1))
            } else {
                tryScrollToTime(currentPTS)
            }
        }
    }

    /// 下一个文件
    var nextItem: IVTimelineItem? {
        if !currentItem.isValid {
            return currentGroup.items.first(where: { $0.isValid })
        } else if let currIdx = currentGroup.items.firstIndex(of: currentItem) {
            for nextIdx in currIdx+1..<currentGroup.items.endIndex {
                let nextItem = currentGroup.items[nextIdx]
                if nextItem.isValid {
                    return nextItem
                }
            }
        }
        return nil
    }

    private var autoScrollEnable = true
    
    private var loadingTimes: [IVTime] = []
    
    // MARK: - UI

    lazy var indicatorLine: UIView = {
        let ind = UIView(frame: CGRect(x: (collectionView.bounds.width-2)/2, y: 0, width: 2, height: collectionView.bounds.height))
        ind.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        ind.backgroundColor  = UIColor.red
        return ind
    }()

    lazy var scaleLabel: UILabel = {
        let lb = UILabel(frame: CGRect(x: (collectionView.bounds.width-40)/2, y: (collectionView.bounds.height-40)/2, width: 40, height: 40))
        lb.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        lb.backgroundColor = UIColor(white: 0.8, alpha: 0.8)
        lb.textColor = .black
        lb.textAlignment = .center
        lb.font = .systemFont(ofSize: 12)
        lb.layer.cornerRadius = 20
        lb.layer.masksToBounds = true
        lb.isHidden = true
        self.addSubview(lb)
        return lb
    }()
    
    lazy var playBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: (collectionView.bounds.width-40)/2, y: (collectionView.bounds.height-40)/2, width: 40, height: 40))
        btn.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        btn.backgroundColor = UIColor(white: 0.8, alpha: 0.8)
        btn.layer.cornerRadius = 20
        btn.layer.masksToBounds = true
        btn.setImage(UIImage(named: "FullPlay_Play"), for: .normal)
        btn.addEvent { [weak self]_ in
            self?.playBtnClicked()
        }
        btn.isHidden = true
        self.addSubview(btn)
        return btn
    }()

    
    lazy var headerBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: bounds.height-20, width: 40, height: 20))
        btn.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin]
        btn.backgroundColor = UIColor(white: 0.9, alpha: 1)
        btn.layer.cornerRadius = 5
        btn.layer.masksToBounds = true
        btn.titleLabel?.font = .systemFont(ofSize: 10)
        btn.setTitle("<<", for: .normal)
        btn.setTitleColor(.blue, for: .normal)
        btn.addEvent { [unowned self]_ in
            self.collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
        btn.isHidden = true
        self.addSubview(btn)
        return btn
    }()

    lazy var footerBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: bounds.width-40, y: bounds.height-20, width: 40, height: 20))
        btn.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin]
        btn.backgroundColor = UIColor(white: 0.9, alpha: 1)
        btn.layer.cornerRadius = 5
        btn.layer.masksToBounds = true
        btn.titleLabel?.font = .systemFont(ofSize: 10)
        btn.setTitle(">>", for: .normal)
        btn.setTitleColor(.blue, for: .normal)
        btn.addEvent { [unowned self]_ in
            self.collectionView.setContentOffset(CGPoint(x: self.collectionView.contentSize.width-self.collectionView.frame.width, y: 0), animated: true)
        }
        btn.isHidden = true
        self.addSubview(btn)
        return btn
    }()

    lazy var dateBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: collectionView.bounds.maxY, width: bounds.width, height: 20))
        btn.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        btn.setTitle(currentGroup.summaryString, for: .normal)
        btn.setTitleColor(.blue, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.addEvent { (_) in
            self.calendarView.isHidden = false
            self.calendarView.currentDate = self.currentGroup.time.date
        }
        return btn
    }()

    /// 时间轴布局
    lazy var timelineLayout = IVTimelineLayout()
    
    /// 时间轴容器视图
    lazy var collectionView: UICollectionView = {
        let rect = CGRect(x: 0, y: 0, width: self.bounds.width, height: 64)
        let col = UICollectionView(frame: rect, collectionViewLayout: timelineLayout)
        col.autoresizingMask = [.flexibleBottomMargin, .flexibleWidth]
        col.register(IVTimelineCell.self, forCellWithReuseIdentifier: "IVTimelineCell")
        col.register(IVTimelineHeaderFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: UICollectionView.elementKindSectionHeader)
        col.register(IVTimelineHeaderFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: UICollectionView.elementKindSectionFooter)
        col.showsHorizontalScrollIndicator = false
        col.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 100, bottom: 0, right: 100)
        col.backgroundColor = UIColor(white: 0.98, alpha: 1)
        col.dataSource = self
        col.delegate   = self
        col.addGestureRecognizer(pinchGesture)
        return col
    }()
    
    /// 缩放手势
    private lazy var pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureHandler(_:)))
    
    lazy var calendarView: IVCalendar = {
        let vcView = nextViewController?.view
        let cal = IVCalendar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300))
        cal.center = vcView!.center
        cal.backgroundColor = .white
//        cal.markDates = [Date(timeIntervalSince1970: 1584240204),
//                         Date(timeIntervalSince1970: 1586919204)]
//        cal.lowerValidDate = Date(timeIntervalSince1970: 1584240204)
        cal.currentDate = currentGroup.time.date
        cal.delegate = self
        vcView?.addSubview(cal)
        return cal
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if currentGroup.isPlaceholder {
            preloadItemsIfNeed(at: currentGroup.time)
        }
    }
}

private extension IVTimelineView {
    
    func setupUI() {
        backgroundColor = .white
        addSubview(collectionView)
        addSubview(indicatorLine)
        addSubview(dateBtn)
    }
    
    /// 预加载数据
    func preloadItemsIfNeed(at time: IVTime) {
        DispatchQueue.main.async {[weak self] in
            guard let `self` = self else { return }
                        
            if !self.dataSource.contains(where: { time == $0.time }),
                !self.loadingTimes.contains(time) {
                self.loadingTimes.append(time)
                
                self.delegate?.timelineView(self, itemsForTimelineAt: time) {(items) in
                    DispatchQueue.main.async {[weak self] in
                        guard let `self` = self else { return }
                        self.loadingTimes.removeAll(where: { $0 == time})
                        if let items = items {
                            logInfo("下载成功 \(time.dateString)")
                            self.insertDataSource(items, at: time)
                        } else {
                            logError("下载失败 \(time.dateString)")
                        }
                    }
                }
            }
        }
    }
    
    /// 加载并刷新UI
    func loadAndDisplayItems(at time: IVTime) {
        DispatchQueue.main.async {[weak self] in
            guard let `self` = self else { return }
            if self.currentGroup.time != time {
                let isPrev = time.start < self.currentGroup.time.start
                
                self.currentGroup = self.dataSource.first(where: { time == $0.time }) ?? .placeholder(time)

                if self.currentGroup.isPlaceholder {
                    self.preloadItemsIfNeed(at: time)
                }
                
                self.collectionView.reloadData()
                self.collectionView.contentOffset.x = isPrev ? self.collectionView.contentSize.width-self.collectionView.frame.width : 0
                self.collectionView.transform = CGAffineTransform(translationX: isPrev ? -1000 : 1000, y: 0)
                UIView.animate(withDuration: 0.3) {
                    self.collectionView.transform = .identity
                }
            }
        }
    }
    
    /// 插入数据源
    func insertDataSource(_ items: [IVTimelineItem], at time: IVTime) {
        var newItems = items.sorted { $0.start < $1.start }
        
        // 填充中间空隙
        let maxIdx = max(items.count-1, 0)
        for i in 0 ..< maxIdx {
            if let padding = IVTimelineItem.padding(start: newItems[maxIdx-i-1].end, end: newItems[maxIdx-i].start) {
                newItems.insert(padding, at: maxIdx-i)
            }
        }
        // 填充尾部空隙
        if items.count > 0 {
            if let padding = IVTimelineItem.padding(start: newItems.last!.end, end: time.end) {
                newItems.insert(padding, at: newItems.endIndex)
            }
        }
        // 填充头部空隙
        if let padding = IVTimelineItem.padding(start: time.start, end: newItems.first?.start ?? time.end) {
            newItems.insert(padding, at: newItems.startIndex)
        }
        
        let newGroup = IVTimelineGroup(time, newItems)
          
        let idx = dataSource.firstIndex(where: { $0.time.start >= time.end })
        dataSource.insert(newGroup, at: idx ?? 0)
        
        if currentGroup.time == time && currentGroup.isPlaceholder {
            currentGroup = newGroup
            collectionView.reloadData()
        }
    }
    
    func selectedTimelineItem() -> (item: IVTimelineItem, time: TimeInterval)? {
        for cell in collectionView.visibleCells {
            guard let cell = cell as? IVTimelineCell else {
                continue
            }
            let newRect = collectionView.convert(cell.frame, to: self)
            let indRect = indicatorLine.frame
            
            guard newRect.contains(CGPoint(x: indRect.maxX, y: indRect.midY)) else {
                continue
            }
            
            guard let fragment = cell.fragment, fragment.item.isValid else {
                break
            }
                                    
            let width0 = (fragment.start - fragment.item.start) * scale
            let width1 = Double(indRect.maxX - newRect.origin.x)
            let offset = width0 + width1
            let time = round(fragment.item.start + offset/scale)

            return (fragment.item, time)
        }
        
        return nil
    }
    
    func enableAutoScroll(after delay: TimeInterval) {
        autoScrollEnable = false
        IVDelayWork.asyncAfter(delay, key: "autoScrollEnable") {[weak self] in
            self?.autoScrollEnable = true
        }
    }
    
    var isInteracting: Bool {
        return collectionView.isDragging ||
            collectionView.isTracking ||
            collectionView.isDecelerating ||
            !playBtn.isHidden ||
            !scaleLabel.isHidden
    }
    
    func forceScrollToTime(_ time: TimeInterval) {
        DispatchQueue.main.async {
            guard let first = self.currentGroup.items.first else { return }
            let offset = CGFloat(time - first.start) * CGFloat(self.scale)

            let point = CGPoint(x: offset, y: self.collectionView.contentOffset.y)
            self.collectionView.setContentOffset(point, animated: true)
        }
    }

    func tryScrollToTime(_ time: TimeInterval) {
        if self.isInteracting {
            self.enableAutoScroll(after: 2)
            return
        }
        
        if !self.autoScrollEnable {
            return
        }
        
        forceScrollToTime(time)
    }
    
    @objc func pinchGestureHandler(_ pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .began:
            scaleLabel.isHidden = false
            playBtn.isHidden = true
        case .changed:
            self.scale *= Double(pinch.scale)
            scaleLabel.text = self.scale > 0.1 ? "\(Int(self.scale * 100))%" : String(format: "%.1f%%", self.scale * 100)
        default:
            IVDelayWork.asyncAfter(1, key: "scaleLabel.isHidden") {[weak self] in
                self?.scaleLabel.isHidden = true
            }
        }
        pinch.scale = 1
    }
    
    private func didScrollHandler() {
        if let _ = selectedTimelineItem() {
            playBtn.isHidden = false
            IVDelayWork.asyncAfter(2, key: "playBtn.isHidden") {[weak self] in
                self?.playBtn.isHidden = true
            }
        }
    }
    
    func playBtnClicked() {
        playBtn.isHidden = true
        autoScrollEnable = true
        if let (item, time) = selectedTimelineItem() {
            currentItem = item
            delegate?.timelineView(self, didSelect: item, at: time)
        }
    }
}

extension IVTimelineView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return currentGroup.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var item = currentGroup.items[section]
        return item.fragments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IVTimelineCell", for: indexPath) as! IVTimelineCell
        var item = currentGroup.items[indexPath.section]
        let fragment = item.fragments[indexPath.row]
        cell.setTimelineFragment(fragment, scale: scale)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerfooter = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath) as! IVTimelineHeaderFooter
        if kind == UICollectionView.elementKindSectionHeader {
            let prevDay = self.currentGroup.time.before(days: 1)
            headerfooter.dateLabel.text = prevDay.dateString
            headerfooter.btn.setTitle("<<<前一天<<<", for: .normal)
            headerfooter.btn.addEvent { (_) in
                self.loadAndDisplayItems(at: prevDay)
            }
        } else {
            if currentGroup.time == .today {
                headerfooter.dateLabel.text = ""
                headerfooter.btn.setTitle("没有更多了", for: .normal)
                headerfooter.btn.addEvent { _ in }
            } else {
                let nextDay = self.currentGroup.time.after(days: 1)
                headerfooter.dateLabel.text = nextDay.dateString
                headerfooter.btn.setTitle(">>>后一天>>>", for: .normal)
                headerfooter.btn.addEvent { (_) in
                    self.loadAndDisplayItems(at: nextDay)
                }
            }
        }
        return headerfooter
    }
}


extension IVTimelineView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionHeader {
            headerBtn.isHidden = true
            let prevDay = currentGroup.time.before(days: 1)
            preloadItemsIfNeed(at: prevDay)
        } else {
            footerBtn.isHidden = true
            let nextDay = currentGroup.time.after(days: 1)
            preloadItemsIfNeed(at: nextDay)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionHeader {
            headerBtn.isHidden = false
        } else {
            footerBtn.isHidden = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = currentGroup.items[indexPath.section]
        
        // 间隙不处理
        if !item.isValid { return }
                
        forceScrollToTime(item.start)
        
        playBtn.isHidden = false
        IVDelayWork.asyncAfter(2, key: "playBtn.isHidden") {[weak self] in
            self?.playBtn.isHidden = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var item = currentGroup.items[indexPath.section]
        let fragment = item.fragments[indexPath.row]

        let itemW = CGFloat(fragment.duration * scale)
        return CGSize(width: itemW, height: collectionView.bounds.height)
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
        if section == currentGroup.items.startIndex {
            return CGSize(width: collectionView.bounds.width/2, height: collectionView.bounds.height)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if section == currentGroup.items.endIndex-1 {
            return CGSize(width: collectionView.bounds.width/2, height: collectionView.bounds.height)
        }
        return .zero
    }
}

extension IVTimelineView: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        playBtn.isHidden = true
        scaleLabel.isHidden = true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.isDecelerating { return }
        
        if scrollView.contentOffset.x < -60 {
            let prevDay = self.currentGroup.time.before(days: 1)
            self.loadAndDisplayItems(at: prevDay)
        } else if currentGroup.time != .today,
            scrollView.contentOffset.x - scrollView.contentSize.width > -(scrollView.frame.width-60) {
            let nextDay = self.currentGroup.time.after(days: 1)
            self.loadAndDisplayItems(at: nextDay)
        }

        if decelerate { return }

        didScrollHandler()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didScrollHandler()
    }
}

extension IVTimelineView: IVCalendarDelegate {
    
    func calendar(_ calendar: IVCalendar, didSelect date: Date) {
        calendar.isHidden = true
        loadAndDisplayItems(at: IVTime(date: date))
    }
}

class IVTimelineCell: UICollectionViewCell {
    
    func setTimelineFragment(_ fragment: IVTimelineFragment, scale: Double) {
        self.fragment = fragment
        self.scale = scale
        colorView.backgroundColor = fragment.item.color
        removeAllTextLayer()
        timeMarks = IVTimeMark.all.filter { scale * Double($0.rawValue) >= 4.8 } // 距离大于 4.8 pt
        setNeedsDisplay()
    }

    /// === 数据模型 ===
    private(set) var fragment: IVTimelineFragment!
    
    /// === 缩放比例 ===
    private(set) var scale = 1.0

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
        let remain: TimeInterval = fragment.start - floor(fragment.start) // 小数点后的余数
        let mod: TimeInterval = TimeInterval(Int(fragment.start) % mark.rawValue) + remain // 小数点后的余数
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
        case .hour4, .hour2, .hour: return 20
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
        
        while offset <= fragment.duration {
            if mark.upperMark == nil || Int(fragment.start + offset) % mark.upperMark!.rawValue != 0 {
                ctx?.move(to: CGPoint(x: scale * offset, y: 0))
                ctx?.addLine(to: CGPoint(x: scale * offset, y: markHeight))
                
                if showText, mark >= .sec10 {
                    for divisor in IVTimeMark.divisors {
                        if Int(fragment.start + offset) % divisor == 0 {
                            addTextLayer(frame: CGRect(x: CGFloat(scale * offset)-labelWidth/2, y: bounds.height-20, width: labelWidth, height: 20),
                                         text: fmt.string(from: Date(timeIntervalSince1970: fragment.start + offset)),
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

        timeMarks.forEach { (mark) in
            drawTimelineMark(ctx, mark: mark)
        }
    }
}

class IVTimelineHeaderFooter: UICollectionReusableView {
    lazy var dateLabel: UILabel = {
        let lb = UILabel(frame: CGRect(x: 0, y: bounds.height-20, width: bounds.width, height: 20))
        lb.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        lb.textColor = .gray
        lb.textAlignment = .center
        lb.font = .systemFont(ofSize: 10)
        lb.numberOfLines = 1
        return lb
    }()
    
    lazy var btn: UIButton = {
        let btn = UIButton(frame: bounds)
        btn.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        btn.setTitleColor(.blue, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15)
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(btn)
        addSubview(dateLabel)
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

    static let all: [IVTimeMark] = [.hour4, .hour2, .hour, .min30, .min10, .min5, .min1, .sec30, .sec10, .sec5, .sec1]

    static func < (lhs: IVTimeMark, rhs: IVTimeMark) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    static func > (lhs: IVTimeMark, rhs: IVTimeMark) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }
}
