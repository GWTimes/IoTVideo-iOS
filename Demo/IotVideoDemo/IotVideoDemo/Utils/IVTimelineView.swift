//
//  IVTimelineView.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/1/8.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import SnapKit

protocol IVTimelineViewDelegate: class {
    /// （滚动中）到达某时刻
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - time: 时间值（UTC时间，不是偏移量）
    func timelineView(_ timelineView: IVTimelineView, didScrollTo time: TimeInterval)

    /// （滚动停止）选中某时刻
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - item: 时间片段
    ///   - time: 时间值（UTC时间，不是偏移量）
    func timelineView(_ timelineView: IVTimelineView, didSelectItem item: IVTimelineItem?, at time: TimeInterval)
    
    /// 点击选中某日期
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - time: 日期所在的时间片段
    func timelineView(_ timelineView: IVTimelineView, didSelectDateAt time: IVTime)

    /// 选择模式下选中某时间范围
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - time: 选择的时间范围
    func timelineView(_ timelineView: IVTimelineView, didSelectRangeAt time: IVTime)

    /// 数据源
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - time: 时间片段
    ///   - completionHandler: 数据获取完成回调
    func timelineView(_ timelineView: IVTimelineView, itemsForTimelineAt time: IVTime, completionHandler: @escaping ([IVTimelineItem]?) -> Void)
    
    /// 获取打点日期
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - time: 时间片段
    ///   - completionHandler: 数据获取完成回调
    func timelineView(_ timelineView: IVTimelineView, markListForCalendarAt time: IVTime, completionHandler: @escaping ([IVCSMarkItem]?) -> Void)
}

class IVTimelineView: UIControl {
    
    // MARK: Property

    /// 时间轴事件代理
    weak var delegate: IVTimelineViewDelegate?
       
    /// 视图模型
    var viewModel: IVTimelineViewModel = IVTimelineViewModel(time: .today)
       
    private var autoScrollEnable = true
    
    private var loadingTimes: [IVTime] = []
    
    // MARK: UI

    private let indicatorLine: UIView = {
        let ind = UIView()
        ind.backgroundColor = UIColor.red
        return ind
    }()
        
    private var selectView = IVTimelineSelectView().then {
        $0.isHidden = true
    }
    
    private let calendarBtn: UIButton = {
        let btn = UIButton()
        if let img = UIImage(named: "calender_icon") {
            btn.setImage(img, for: .normal)
        } else {
            btn.setTitle("📅", for: .normal)
        }
        btn.backgroundColor = UIColor(white: 0.98, alpha: 1)
        return btn
    }()
    
    /// 日期容器视图
    private let datelineView = IVDatelineView()
    
    /// 时间轴容器视图
    lazy var timeCollView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        let col = UICollectionView(frame: .zero, collectionViewLayout: layout)
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

    let loadingAnim = UIActivityIndicatorView(style: .gray)

    private var headerBtn: UIButton?
    private var footerBtn: UIButton?
    
    private var isManuallyOperation = false

    /// 缩放手势
    private lazy var pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureHandler(_:)))
    
    lazy var calendarView: IVCalendarView = {
        let cal = IVCalendarView()
        cal.backgroundColor = .white
        cal.alpha = 0
        cal.currentDate = viewModel.current.date
        return cal
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareView()
        prepareEvent()
        prepareLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        prepareView()
        prepareEvent()
        prepareLayout()
    }
    
    deinit {
        logDebug("timeline view deinit")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
        layoutIfNeeded()
        
        calendarBtn.isHidden = gIsLandscape
        datelineView.isHidden = gIsLandscape
        if gIsLandscape { calendarView.alpha = 0 }
            
        self.timeCollView.reloadData()
        if viewModel.current.isPlaceholder {
            loadAndDisplaySection(at: viewModel.current.time)
        } else {
            scrollToTime(viewModel.pts, force: true, animated: false)
        }        
    }
    
    override var isTracking: Bool {
        return !autoScrollEnable ||
            isInteracting ||
            datelineView.isTracking ||
            timeCollView.isTracking
    }
    
}

private extension IVTimelineView {
        
    private func prepareView() {
        backgroundColor = .white
        addSubview(datelineView)
        addSubview(calendarBtn)
        addSubview(timeCollView)
        addSubview(indicatorLine)
        addSubview(loadingAnim)
        addSubview(selectView)
    }
    
    private func prepareEvent() {
        
        calendarBtn.addEvent { [unowned self](_) in
            let superview = self.nextViewController?.view
            superview?.addSubview(self.calendarView)
            self.calendarView.snp.remakeConstraints { (make) in
                make.height.equalTo(400)
                make.width.equalTo(375)
                make.centerX.equalToSuperview()
                make.bottom.equalTo(superview!.snp.bottomMargin)
            }
            
            if self.calendarView.alpha < 0.01 {
                self.calendarView.alpha = 0
                self.calendarView.transform = CGAffineTransform(translationX: 0, y: 400)
                UIView.animate(withDuration: 0.3, animations: {
                    self.calendarView.alpha = 1
                    self.calendarView.transform = .identity
                })
                self.calendarView.currentDate = self.viewModel.current.date
                if self.calendarView.markableDates.isEmpty {
                    self.loadMarkList(at: self.viewModel.current.time)
                }
            }
        }

        selectView.didChangeValue = { [unowned self] (leftView, rightView)in

            let leftDiff  = indicatorLine.frame.midX - leftView.frame.maxX
            let rightDiff = indicatorLine.frame.midX - rightView.frame.minX

            var leftTime  = Double(timeCollView.contentOffset.x - leftDiff)  / self.viewModel.scale + viewModel.current.start
            var rightTime = Double(timeCollView.contentOffset.x + rightDiff) / self.viewModel.scale + viewModel.current.start

            leftTime = min(max(leftTime, viewModel.current.start), viewModel.current.end)
            rightTime = min(max(rightTime, viewModel.current.start), viewModel.current.end)

            delegate?.timelineView(self, didSelectRangeAt: IVTime(start: leftTime, end: rightTime))
        }
        
        viewModel.scrollToTimeIfNeed = { [weak self] pts, sectionTime in
            guard let `self` = self else { return }
            if self.isManuallyOperation { return }
            if pts < sectionTime.start {
                self.loadAndDisplaySection(at: sectionTime.before(days: UInt(sectionTime.start - pts) / 86400 + 1))
            } else if pts > sectionTime.end {
                self.loadAndDisplaySection(at: sectionTime.after(days: UInt(pts - sectionTime.end) / 86400 + 1))
            } else {
                DispatchQueue.main.async {
                    self.scrollToTime(pts, force: false, animated: true)
                }
            }
        }
        
        viewModel.state.observe { [weak self](state, _) in
            guard let `self` = self else { return }
            self.selectView.isHidden = (state == .selecting)
            if state == .selecting {
                self.delegate?.timelineView(self, didSelectRangeAt: IVTime(start: self.viewModel.current.start,
                                                                           end: self.viewModel.current.end))
            }
        }
        
        datelineView.selectedDateCallback = { [weak self] date in
            self?.loadAndDisplaySection(at: IVTime(date: date))
        }
        
        calendarView.selectedDateCallback = { [weak self] date in
            self?.calendarView.alpha = 0
            self?.loadAndDisplaySection(at: IVTime(date: date))
        }
    }
    
    private func prepareLayout() {
        calendarBtn.snp.makeConstraints { (make) in
            make.top.right.equalToSuperview()
            make.width.height.equalTo(35)
        }

        datelineView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.height.equalTo(35)
            make.right.equalToSuperview()
        }

        timeCollView.snp.makeConstraints { (make) in
            make.top.equalTo(datelineView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        indicatorLine.snp.makeConstraints { (make) in
            make.center.equalTo(timeCollView)
            make.width.equalTo(1)
            make.height.equalTo(timeCollView).offset(6)
        }
        
        loadingAnim.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        selectView.snp.makeConstraints { (make) in
            make.edges.equalTo(timeCollView)
        }
    }
    
    
    private func updateLayout() {
        timeCollView.snp.remakeConstraints { (make) in
            if gIsLandscape {
                make.top.equalToSuperview()
            } else {
                // FIXME: 加这句导致timelineview释放不了？
                make.top.equalTo(datelineView.snp.bottom)
            }
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    /// 预加载数据
    func preloadSectionIfNeed(at time: IVTime, isBackward: Bool) {
        DispatchQueue.main.async {[weak self] in
            guard let `self` = self else { return }
                        
            if !self.viewModel.sections.contains(where: { time == $0.time }),
                !self.loadingTimes.contains(time) {
                self.loadingTimes.append(time)
                self.loadingAnim.startAnimating()

                self.delegate?.timelineView(self, itemsForTimelineAt: time) {(items) in
                    DispatchQueue.main.async {[weak self] in
                        guard let `self` = self else { return }
                        self.loadingTimes.removeAll(where: { $0 == time})
                        self.loadingAnim.stopAnimating()
                        if let items = items {
//                            logInfo("下载成功 \(time.dateString) \(items)")
                            
                            self.viewModel.insertSection(items: items, for: time)
                            
                            if self.viewModel.current.time == time {
                                self.timeCollView.reloadData()
                                if let destItem = isBackward ? self.viewModel.current.items.last(where: { $0.isValid }) : self.viewModel.current.items.first(where: { $0.isValid }) {
                                    self.scrollToTime(destItem.start, force: true, animated: true)
                                } else {
                                    self.timeCollView.contentOffset.x = isBackward ? self.timeCollView.contentSize.width-self.timeCollView.frame.width : 0
                                }
                            }
                        } else {
                            logError("下载失败 \(time.dateString)")
                        }
                    }
                }
            }
        }
    }
    
    /// 加载并刷新UI
    func loadAndDisplaySection(at time: IVTime) {
        DispatchQueue.main.async {[weak self] in
            guard let `self` = self else { return }
            let isSameTime = (self.viewModel.current.time == time)
            let isBackward = time.start < self.viewModel.current.start
            
            // 通知外部点击的日期
            self.delegate?.timelineView(self, didSelectDateAt: time)

            if !isSameTime || self.viewModel.current.isPlaceholder {
                self.viewModel.loadSection(for: time)
                
                if self.viewModel.current.isPlaceholder {
                    // 是placeholder就下载
                    self.preloadSectionIfNeed(at: time, isBackward: isBackward)
                    if isSameTime { return } // 相同日期
                }
                                
                self.datelineView.selectedDate = time.date
                
                self.timeCollView.reloadData()
                self.timeCollView.contentOffset.x = isBackward ? self.timeCollView.contentSize.width-self.timeCollView.frame.width : 0
                
                if !self.viewModel.current.isPlaceholder,
                    let destItem = isBackward ? self.viewModel.current.items.last(where: { $0.isValid }) : self.viewModel.current.items.first(where: { $0.isValid }) {
                    self.scrollToTime(destItem.start, force: true, animated: true)
                }
                
                self.timeCollView.transform = CGAffineTransform(translationX: isBackward ? -100 : 100, y: 0)
                UIView.animate(withDuration: 0.3) {
                    self.timeCollView.transform = .identity
                }
            }
        }
    } 
        
    func loadMarkList(at time: IVTime) {
        self.delegate?.timelineView(self, markListForCalendarAt: time, completionHandler: { [weak self](markList) in
            guard let markList = markList else { return }
            self?.calendarView.markableDates = markList.map { TimeInterval($0) }
        })
    }
 
    func enableAutoScroll(after delay: TimeInterval) {
        autoScrollEnable = false
        IVDelayWork.asyncAfter(delay, key: "autoScrollEnable") {[weak self] in
            self?.autoScrollEnable = true
        }
    }
    
    var isInteracting: Bool {
        return timeCollView.isDragging ||
            timeCollView.isTracking ||
            timeCollView.isDecelerating
    }
        
    func scrollToTime(_ time: TimeInterval, force: Bool, animated: Bool) {
        if !force {
            if self.isInteracting {
                self.enableAutoScroll(after: 2)
                return
            }
            
            if !self.autoScrollEnable {
                return
            }
        }
        let time = min(max(time, viewModel.current.start), viewModel.current.end)
        viewModel.update(pts: time, needsScroll: false)
        let offsetX = CGFloat(time - viewModel.current.start) * CGFloat(viewModel.scale)
        let point = CGPoint(x: offsetX, y: timeCollView.contentOffset.y)
        self.timeCollView.setContentOffset(point, animated: animated)
    }
    
    @objc func pinchGestureHandler(_ pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .changed:
            isManuallyOperation = true
            let oldScale = viewModel.scale
            if viewModel.update(scale: oldScale * Double(pinch.scale)) {
//                CATransaction.setDisableActions(true)
                timeCollView.reloadData()
                scrollToTime(viewModel.pts, force: true, animated: false)
//                CATransaction.commit()
            }
        default:
            IVDelayWork.asyncAfter(1, key: "isManuallyScroll-did-end") {[weak self] in
                self?.isManuallyOperation = false
            }
        }
        pinch.scale = 1
    }
    
}

extension IVTimelineView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.current.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IVTimelineCell", for: indexPath) as! IVTimelineCell
        let item = viewModel.current.items[indexPath.item]
        let time = IVTime(start: item.start, end: item.end)
        cell.update(time: time, color: item.color, isValid: item.isValid, scale: viewModel.scale)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerfooter = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath) as! IVTimelineHeaderFooter
        let fmt = DateFormatter()
        fmt.dateFormat = "MM/dd"
        
        if kind == UICollectionView.elementKindSectionHeader {
            headerBtn = headerfooter.btn
            let prevDay = self.viewModel.current.before(days: 1)
            headerBtn?.setTitle("\(fmt.string(from: prevDay.date))   ☜=((・∀・*)☜=", for: .normal)
            headerBtn?.setTitle("╰(￣▽￣)╭", for: .selected)
            headerBtn?.addEvent { (_) in
                self.loadAndDisplaySection(at: prevDay)
            }
        } else {
            footerBtn = headerfooter.btn
            if viewModel.current.time == .today {
                footerBtn?.setTitle("(＞﹏＜)||", for: .normal)
                footerBtn?.addEvent { _ in }
            } else {
                let nextDay = self.viewModel.current.after(days: 1)
                footerBtn?.setTitle("=☞(*・∀・))=☞   \(fmt.string(from: nextDay.date))", for: .normal)
                footerBtn?.setTitle("╰(￣▽￣)╭", for: .selected)
                footerBtn?.addEvent { (_) in
                    self.loadAndDisplaySection(at: nextDay)
                }
            }
        }
        headerfooter.setNeedsDisplay()
        return headerfooter
    }
}


extension IVTimelineView: UICollectionViewDelegateFlowLayout {
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = viewModel.current.items[indexPath.item]
        if !item.isValid { return }
        scrollToTime(item.start, force: true, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = viewModel.current.items[indexPath.item]
        let fscale = Double(UIScreen.main.scale) * viewModel.scale
        let floorStart = floor(fscale * item.start) / Double(UIScreen.main.scale)
        let floorEnd = floor(fscale * item.end) / Double(UIScreen.main.scale)
        let newItemW = CGFloat(floorEnd - floorStart)
        return CGSize(width: newItemW, height: collectionView.bounds.height)
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
        return CGSize(width: collectionView.bounds.width/2, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width/2, height: collectionView.bounds.height)
    }
    
    // MARK: UIScrollViewDelegate
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isManuallyOperation = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.isDecelerating { return }
        
        if scrollView.contentOffset.x < -60 {
            let prevDay = viewModel.current.before(days: 1)
            loadAndDisplaySection(at: prevDay)
        } else if viewModel.current.time != .today,
            scrollView.contentOffset.x - scrollView.contentSize.width > -(scrollView.frame.width-60) {
            let nextDay = viewModel.current.after(days: 1)
            loadAndDisplaySection(at: nextDay)
        }
        
        if decelerate { return }
        scrollhandler(didEnd: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollhandler(didEnd: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        headerBtn?.isSelected = (scrollView.isDragging && scrollView.contentOffset.x < -60)
        footerBtn?.isSelected = (scrollView.isDragging && viewModel.current.time < .today && scrollView.contentOffset.x - scrollView.contentSize.width > -(scrollView.frame.width-60))
        
        scrollhandler(didEnd: false)
    }
    
    private func scrollhandler(didEnd: Bool) {
        guard isManuallyOperation, !viewModel.current.items.isEmpty else {
            return
        }
        
        for cell in timeCollView.visibleCells {
            guard let cell = cell as? IVTimelineCell else {
                continue
            }
            let newRect = timeCollView.convert(cell.frame, to: self)
            let indRect = indicatorLine.frame
            
            guard newRect.contains(CGPoint(x: indRect.midX, y: indRect.midY)) else {
                continue
            }
            
            var seekTime = Double(timeCollView.contentOffset.x) / self.viewModel.scale + viewModel.current.start
            seekTime = min(max(seekTime, viewModel.current.start), viewModel.current.end)
            
            viewModel.update(pts: seekTime, needsScroll: false)
            delegate?.timelineView(self, didScrollTo: seekTime)

            if didEnd {
                IVDelayWork.asyncAfter(1, key: "isManuallyScroll-did-end") {[weak self] in
                    self?.isManuallyOperation = false
                }

                if let item = viewModel.currentRawItem {
                    logDebug("selected curr-item \(String(describing: item)) at \(seekTime)")
                    delegate?.timelineView(self, didSelectItem: item, at: seekTime)
                } else if let item = viewModel.nextRawItem, item.start < viewModel.current.end {
                    IVDelayWork.asyncAfter(1, key: "selected next-item") {[weak self] in
                        guard let `self` = self else { return }
                        logDebug("selected next-item \(String(describing: item)) at \(seekTime)")
                        self.scrollToTime(item.start, force: true, animated: true)
                        self.delegate?.timelineView(self, didSelectItem: item, at: item.start)
                    }
                }
            } else {
                IVDelayWork.cancelTask(withKey: "selected next-item")
            }
            return
        }
        
        IVDelayWork.asyncAfter(1, key: "isManuallyScroll-did-end") {[weak self] in
            self?.isManuallyOperation = false
        }
    }
}


// MARK: -

class IVTimelineCell: UICollectionViewCell {
    
    private(set) var time: IVTime = .today
    private(set) var color: UIColor = .white
    private(set) var isValid: Bool = false
    private(set) var scale = 1.0
        
    func update(time: IVTime, color: UIColor, isValid: Bool, scale: Double) {
        self.time = time
        self.color = color
        self.isValid = isValid
        self.scale  = scale
        timeMarks = IVTimeMark.all.filter { scale * Double($0.rawValue) >= 4.8 } // 距离大于 4.8 pt
        setNeedsDisplay()
    }
            
    /// === 时间刻度 ===
    private var timeMarks: [IVTimeMark] = [.hour]
           
    private func TimeOffset(of mark: IVTimeMark) -> TimeInterval {
        let remain: TimeInterval = time.start - floor(time.start) // 小数点后的余数
        let mod: TimeInterval = TimeInterval(Int(time.start) % mark.rawValue) + remain // 小数点前整数
        let offset: TimeInterval = mod > 0.001 ? TimeInterval(mark.rawValue) - mod : 0
        return offset
    }
    
    private lazy var dateFormater = IVTimeMark.all.reduce(into: [IVTimeMark : DateFormatter]()) { (dict, mark) in
        let fmt = DateFormatter()
        fmt.dateFormat = DateFormat(of: mark)
        dict[mark] = fmt
    }
    
    private func DateFormat(of mark: IVTimeMark) -> String {
        return mark < .min1 ? "ss" : "HH:mm"
    }
        
    private func StrokeColor(of mark: IVTimeMark) -> UIColor {
        let alpha = ((CGFloat(mark.rawValue) * CGFloat(scale) - 2) / 200) + 0.2
        let color = UIColor(white: 0, alpha: alpha)
        return color
    }
        
    // === 刻度\文字 ===
    private func drawTimelineMark(_ ctx: CGContext?) {
        let miniMark = timeMarks.last!
        let miniStep = CGFloat(miniMark.rawValue) * CGFloat(scale)
        var offset   = TimeOffset(of: miniMark)
        let offsetW  = CGFloat(offset * scale)
        let halfLabelW = LabelWidth(of: timeMarks.first!) / 2
        let halfLabelT = Double(halfLabelW) / scale
        let multiple = ceil((offsetW + halfLabelW) / miniStep)
        offset  = offset - Double(multiple * miniStep) / scale
             
        let style = NSMutableParagraphStyle()
        style.alignment = .center
           
        while offset <= time.duration + halfLabelT {
            let offX = CGFloat(scale * offset) // min(max(CGFloat(scale * offset), self.bounds.minX - miniStep), self.bounds.maxX + miniStep)

            for mark in timeMarks {
//                print("markline \(time) \(miniMark.rawValue)    \(mark.rawValue)    \(offset)   \(time.start + offset)")
                if (Int(time.start + offset) % mark.rawValue == 0) {
//                    print("markline -")

                    // 刻度/文字颜色
                    let color = StrokeColor(of: mark)
                    
                    // === 1.画刻度 ===
                    let markHeight = MarkHeight(of: mark)
                    ctx?.setLineWidth(mark >= .hour ? 2 : 1)
                    ctx?.setStrokeColor(color.cgColor)
                    ctx?.move(to:    CGPoint(x: offX, y: verticalInset))
                    ctx?.addLine(to: CGPoint(x: offX, y: verticalInset + CGFloat(markHeight)))
                    ctx?.strokePath()

                    // === 2.画文字 ===
                    let fontSize = FontSize(of: mark)

                    let fmt = dateFormater[mark]!

                    let labelWidth = LabelWidth(of: mark)
                    let showText = CGFloat(mark.rawValue) * CGFloat(scale) > labelWidth

                    if showText, mark >= .sec10 {
                        for divisor in IVTimeMark.divisors {
                            if Int(round(time.start + Double(offX))) % divisor == 0 {
                                let font = UIFont.systemFont(ofSize: fontSize)
                                let string = NSAttributedString(string: fmt.string(from: Date(timeIntervalSince1970: time.start + offset)),
                                                                attributes: [.font : font,
                                                                             .foregroundColor : color,
                                                                             .paragraphStyle : style])
                                string.draw(in: CGRect(x: offX-labelWidth/2,
                                                       y: bounds.height-20-verticalInset,
                                                       width: labelWidth,
                                                       height: 20))
                                break
                            }
                        }
                    }
                
                    // === 3.该时间点绘制完毕 ===
                    break
                }
            }
            offset += Double(miniMark.rawValue)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
//        print(self.classForCoder, "alloc")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        // 颜色块
        ctx?.setFillColor(color.cgColor)
        ctx?.fill(rect.insetBy(dx: 0, dy: verticalInset))
        // 刻度
        drawTimelineMark(ctx)
    }
}

class IVTimelineHeaderFooter: UICollectionReusableView {
    
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        // 背景色
        ctx?.setFillColor(UIColor(white: 0.98, alpha: 1).cgColor)
        ctx?.fill(rect)
        // 绘制00:00
        let mark = IVTimeMark.hour4
        let font = UIFont.systemFont(ofSize: FontSize(of: mark))
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let string = NSAttributedString(string: "00:00",
                                        attributes: [.font : font,
                                                     .foregroundColor : UIColor.black,
                                                     .paragraphStyle : style])
        let isHeader = (reuseIdentifier == UICollectionView.elementKindSectionHeader)
        let labelWidth = LabelWidth(of: mark)
        let offX = isHeader ? bounds.width : 0
        string.draw(in: CGRect(x: offX-labelWidth/2,
                               y: bounds.height-20-verticalInset,
                               width: labelWidth,
                               height: 20))
        // 绘制｜
        let markHeight = MarkHeight(of: mark)
        ctx?.setLineWidth(2)
        ctx?.setStrokeColor(UIColor.black.cgColor)
        ctx?.move(to: CGPoint(x: offX, y: verticalInset))
        ctx?.addLine(to: CGPoint(x: offX, y: verticalInset + CGFloat(markHeight)))
        ctx?.strokePath()
    }
}

private let verticalInset: CGFloat = 10.0

private func FontSize(of mark: IVTimeMark) -> CGFloat {
    if mark.rawValue >= IVTimeMark.min1.rawValue  {
        return 17
    }
    return 12
}

private func DateFormat(of mark: IVTimeMark) -> String {
    return mark < .min1 ? "ss" : "HH:mm"
}

private var _widthCaches: [IVTimeMark : CGFloat] = [:]
private func LabelWidth(of mark: IVTimeMark) -> CGFloat {
    if let width = _widthCaches[mark] {
        return width
    }
    let text = DateFormat(of: mark) as NSString
    let width = max(30, text.boundingRect(with: CGSize(width: 100, height: 20),
                                  options: .usesFontLeading,
                                  attributes: [.font : UIFont.systemFont(ofSize: FontSize(of: mark))],
                                  context: nil).width)
    _widthCaches[mark] = width
    return width
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

fileprivate class IVTimelineSelectView: UIView {
    let selectIndLeft = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.image = UIImage(named: "iot_select_indicator")
    }

    let selectIndRight = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.image = UIImage(named: "iot_select_indicator")
    }
    
    var didChangeValue: ((_ leftView: UIView, _ rightView: UIView) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        addSubview(selectIndLeft)
        addSubview(selectIndRight)
        
        selectIndLeft.addPanGesture { [unowned self](pan) in
            if let pan = pan as? UIPanGestureRecognizer, let panView = pan.view {
                panView.frame.origin.x += pan.translation(in: self).x
                if panView.frame.origin.x < 0 {
                    panView.frame.origin.x = 0
                } else if panView.frame.maxX > self.selectIndRight.frame.minX {
                    panView.frame.origin.x = self.selectIndRight.frame.minX - 35
                }
                self.setNeedsDisplay()
                pan.setTranslation(.zero, in: self)
                self.didChangeValue?(self.selectIndLeft, self.selectIndRight)
            }
        }

        selectIndRight.addPanGesture { [unowned self](pan) in
            if let pan = pan as? UIPanGestureRecognizer, let panView = pan.view {
                panView.frame.origin.x += pan.translation(in: self).x
                if panView.frame.origin.x < self.selectIndLeft.frame.maxX {
                    panView.frame.origin.x = self.selectIndLeft.frame.maxX
                } else if panView.frame.origin.x > self.bounds.width - 35 {
                    panView.frame.origin.x = self.bounds.width - 35
                }
                self.setNeedsDisplay()
                pan.setTranslation(.zero, in: self)
                self.didChangeValue?(self.selectIndLeft, self.selectIndRight)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
            
    override func layoutSubviews() {
        super.layoutSubviews()
        selectIndLeft.frame  = CGRect(x: 0, y: verticalInset, width: 35, height: bounds.height - 2 * verticalInset)
        selectIndRight.frame = CGRect(x: bounds.width - 35, y: verticalInset, width: 35, height: bounds.height - 2 * verticalInset)
    }
        
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.clear(bounds)
        
        ctx?.setLineJoin(.round)
        ctx?.setLineWidth(2)
        ctx?.setStrokeColor(UIColor(rgb: 0x4A90E2).cgColor)
        ctx?.stroke(CGRect(x: selectIndLeft.frame.midX,
                           y: verticalInset + 1,
                           width: selectIndRight.frame.midX - selectIndLeft.frame.midX,
                           height: bounds.height - 2 * (verticalInset + 1)))
    }
}
