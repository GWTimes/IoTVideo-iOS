//
//  IVDatelineView.swift
//  IotVideoDemoYS
//
//  Created by JonorZhang on 2020/8/13.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit

class IVDatelineView: UIControl {
    /// 当前选择日期
    public var selectedDate: Date = Date() {
        didSet {
            didSelectDate(selectedDate)
        }
    }
    
    /// 点击选择日期回调
    public var selectedDateCallback: ((_ date: Date) -> Void)?

    /// 日期个数（天数）
    private let dateCount = (Int(Date().timeIntervalSince1970) + NSTimeZone.system.secondsFromGMT()) / (24*60*60) + 1
    
    /// 时间轴布局
    private let layout = UICollectionViewFlowLayout().then {
        $0.itemSize = CGSize(width: 60, height: 35)
        $0.minimumLineSpacing = 0
        $0.minimumInteritemSpacing = 0
        $0.scrollDirection = .horizontal
    }
    
    /// 日期容器视图
    private lazy var dateCollView = UICollectionView(frame: .zero, collectionViewLayout: layout).then {
        $0.register(IVDatelineCell.self, forCellWithReuseIdentifier: "IVDatelineCell")
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = UIColor(white: 0.98, alpha: 1)
        $0.dataSource = self
        $0.delegate   = self
        $0.allowsMultipleSelection = false
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(dateCollView)
        dateCollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logDebug("IVDatelineView deinit")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dateCollView.reloadData()
        didSelectDate(selectedDate)
    }
        
    override var isTracking: Bool {
        return dateCollView.isTracking
    }

    private func didSelectDate(_ date: Date) {
        dateCollView.indexPathsForSelectedItems?.forEach({ (item) in
            dateCollView.deselectItem(at: item, animated: false)
        })
        dateCollView.selectItem(at: indexPathOfDate(date), animated: true, scrollPosition: .centeredHorizontally)
    }
    
    private func indexPathOfDate(_ date: Date) -> IndexPath {
        let days = (Int(date.timeIntervalSince1970) + NSTimeZone.system.secondsFromGMT()) / (24*60*60)
        return IndexPath(item: days, section: 0)
    }
    
    private func dateOfIndexPath(_ indexPath: IndexPath) -> Date {
        let timeInterval = TimeInterval(indexPath.item * (24*60*60))
        return Date(timeIntervalSince1970: timeInterval - Double(NSTimeZone.system.secondsFromGMT()))
    }
    
    private let dateFormat = DateFormatter().then {
        $0.dateFormat = "MM/dd"
    }
    
    private func stringOfDate(_ date: Date) -> String {
        return dateFormat.string(from: date)
    }
}

extension IVDatelineView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dateCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IVDatelineCell", for: indexPath) as! IVDatelineCell
        let date = dateOfIndexPath(indexPath)
        cell.textLabel.text = stringOfDate(date)
        cell.isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width/2-layout.itemSize.width/2, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width/2-layout.itemSize.width/2, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedDate = dateOfIndexPath(indexPath)
        selectedDateCallback?(selectedDate)
    }
}

fileprivate class IVDatelineCell: UICollectionViewCell {
    let textLabel = UILabel().then {
        $0.textColor = .lightGray
        $0.font = .systemFont(ofSize: 15)
        $0.textAlignment = .center
    }

    private let indicator = UIView().then {
        $0.backgroundColor = .blue
        $0.layer.cornerRadius = 2
        $0.layer.masksToBounds = true
        $0.isHidden = true
    }

    override var isSelected: Bool {
        didSet {
            indicator.isHidden = !isSelected
            textLabel.textColor = isSelected ? .black : .lightGray
            textLabel.font = .systemFont(ofSize: isSelected ? 16 : 15)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(textLabel)
        contentView.addSubview(indicator)
        
        textLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-4)
        }
        
        indicator.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-4)
            make.width.height.equalTo(4)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
