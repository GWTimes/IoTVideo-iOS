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
    func timelineView(_ timelineView: IVTimelineView, didSelect item: IVTimelineItem, at time: TimeInterval)
}

class IVTimelineView: UIView {
    
    weak var delegate: IVTimelineViewDelegate?

    var maximumScale = 5.0  // 最大每秒占多少像素点(pix/sec)
    var minimumScale = 0.05 // 最小每秒占多少像素点(pix/sec)
    var scale = 1.0 {       // 每秒占多少像素点(pix/sec)
        didSet {
            if scale > 5.0 { scale = 5.0 }
            else if scale < 0.05 { scale = 0.05 }
            let offsetX = collectionView.contentOffset.x
            collectionView.reloadData()
            let pinchScale = scale / oldValue
            collectionView.contentOffset.x = offsetX * CGFloat(pinchScale)
        }
    }
    var miniGap: TimeInterval = 0.1 // 小于0.1s的间隙不显示
    
    var currentTime: TimeInterval = 0 {
        didSet {
            DispatchQueue.main.async {
                if let first = self.dataSource.first {
                    let offset = CGFloat(self.currentTime - first.startTime)// * CGFloat(self.scale)
                    self.collectionView.contentOffset.x = offset
                }
            }
        }
    }
    
    lazy var pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureHandler(_:)))
    
    lazy var timelineLayout = IVTimelineLayout()
    lazy var collectionView: UICollectionView = {
        let col = UICollectionView(frame: self.bounds, collectionViewLayout: timelineLayout)
        col.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        col.register(IVTimelineCell.self, forCellWithReuseIdentifier: "IVTimelineCell")
        col.showsHorizontalScrollIndicator = false
        col.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 100, bottom: 0, right: 100)
        col.backgroundColor = UIColor(white: 0.95, alpha: 1)
        col.dataSource = self
        col.delegate   = self
        col.addGestureRecognizer(pinchGesture)
        return col
    }()
    
    private(set) var dataSource: [IVTimelineItem] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.reloadData()
            }
        }
    }
        
    func appendItems(_ items: [IVTimelineItem]) {
        if items.isEmpty { return }
        // 1.排序列表
        var items = items.sorted { $0.startTime < $1.startTime }
        // 2.插入空隙
        if items.count > 1 {
            let maxIdx = items.count-1
            for i in 0 ..< maxIdx {
                if let gapItem = makeGapItem(lhs: items[maxIdx-i-1], rhs: items[maxIdx-i]) {
                    items.insert(gapItem, at: maxIdx-i)
                }
            }
        }
        // 3.拼接列表
        if let last = dataSource.last, items.first!.startTime > last.startTime {
            // a.尾部插入
            if let gapItem = makeGapItem(lhs: last, rhs: items.first!) {
                items.insert(gapItem, at: dataSource.startIndex)
            }
            dataSource.insert(contentsOf: items, at: dataSource.endIndex)
        } else if let first = dataSource.first, items.last!.startTime > first.startTime {
            // b.头部插入
            if let gapItem = makeGapItem(lhs: items.last!, rhs: first) {
                items.insert(gapItem, at: dataSource.endIndex)
            }
            dataSource.insert(contentsOf: items, at: dataSource.startIndex)
        } else {
            if dataSource.isEmpty {
                dataSource.append(contentsOf: items)
            } else {
                logError("数据异常 datasource:\(dataSource), items:\(items)")
                return
            }
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
        scale *= Double(pinch.scale)
    }
}

private extension IVTimelineView {
    
    func makeGapItem(lhs:IVTimelineItem, rhs:IVTimelineItem) -> IVTimelineItem? {
        let gap = rhs.startTime - lhs.endTime
        if gap > miniGap {
            let gapItem = IVTimelineItem(startTime: lhs.endTime,
                                         endTime: rhs.startTime,
                                         duration: gap,
                                         type: "gap",
                                         color: .white)
            return gapItem
        }
        return nil
    }
    
    func didScrollHandler() {
        for cell in collectionView.visibleCells {
            let newRect = collectionView.convert(cell.frame, to: self)
            let newCenter = collectionView.center
            if newRect.contains(newCenter) {
                if let indexPath = collectionView.indexPath(for: cell) {
                    let item = dataSource[indexPath.row]
                    
                    // 间隙不处理
                    if item.type == "gap" { return }
                    
                    let offset = newCenter.x - newRect.origin.x
                    logInfo("seek:", item.startTime, offset, offset/CGFloat(scale))
                    delegate?.timelineView(self, didSelect: item, at: item.startTime + Double(offset)/scale)
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
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IVTimelineCell", for: indexPath)
        cell.backgroundColor = dataSource[indexPath.row].color
        return cell
    }
}


extension IVTimelineView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = dataSource[indexPath.row]
        delegate?.timelineView(self, didSelect: item, at: item.startTime)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemW = CGFloat(dataSource[indexPath.row].duration * scale)
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
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .random
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
