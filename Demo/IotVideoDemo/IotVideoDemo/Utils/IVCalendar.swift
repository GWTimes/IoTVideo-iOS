//
//  IVCalendar.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/4/14.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit

let kScreenWidth:  CGFloat = UIScreen.main.bounds.width
let kScreenHeight: CGFloat = UIScreen.main.bounds.height

let margin: CGFloat = 10.0
let paddingLeft: CGFloat = 20.0
let itemWidth: CGFloat = (kScreenWidth - paddingLeft * 2 - margin * 6) / 7.0

protocol IVCalendarDelegate: class {
    func calendar(_ calendar: IVCalendar, didSelect date: Date)
}

class IVCalendar: UIView {
    // MARK: - Property
    
    weak var delegate: IVCalendarDelegate?
    
    // 需要标记的日期数组
    var markDates: [Date] = []

    // 有效日期下限
    var lowerValidDate: Date?
    
    // 当前选中日期
    var currentDate = Date() {
        didSet { referenceDate = currentDate }
    }

    // 参考日期
    private var referenceDate = Date() {
        didSet {
            DispatchQueue.main.async {[weak self] in
                self?.collectionView.reloadData()
            }
        }
    }
    private var isCurrentMonth: Bool = false //是否当月
    private var currentMonthTotalDays: Int = 0
    private var firstDayIsWeekInMonth: Int = 0 //每月的一号对于的周几
//    private let today: String = String(day(Date()))  //当天几号

    // MARK: - UI
    
    private lazy var headerView: UIView = {
        let headV = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: 74))
        headV.backgroundColor = UIColor(rgb: 0x0075fe)
        return headV
    }()
    
    private lazy var dateLabel: UILabel = {
        let dateLb = UILabel(frame: CGRect(x: (self.bounds.width-100)/2, y: 5, width: 100, height: 30))
        dateLb.textAlignment = .center
        dateLb.textColor = .white
        dateLb.font = .systemFont(ofSize: 17)
        return dateLb
    }()

    private lazy var lastMonthButton: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 5, width: 44, height: 30))
        btn.frame.origin.x = dateLabel.frame.minX - 44 - 8
        btn.setTitle("<", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17)
        btn.addEvent { (_) in
            self.referenceDate = self.lastMonth(self.referenceDate)
            self._initCalendarInfo()
            self.collectionView.reloadData()
        }
        return btn
    }()

    private lazy var nextMonthButton: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 5, width: 44, height: 30))
        btn.frame.origin.x = dateLabel.frame.maxX + 8
        btn.setTitle(">", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17)
        btn.addEvent { (_) in
            self.referenceDate = self.nextMonth(self.referenceDate)
            self._initCalendarInfo()
            self.collectionView.reloadData()
        }
        return btn
    }()
    
    private lazy var cancelButton: UIButton = {
        let btn = UIButton(frame: CGRect(x: self.bounds.width-44-8, y: 5, width: 44, height: 30))
        btn.setTitle("取消", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17)
        btn.addEvent { (_) in
            self.isHidden = true
        }
        return btn
    }()
    
    private lazy var weekView: UIView = {
        let originY: CGFloat = self.headerView.bounds.height - 13.0 - 15.0
        let weekView = UIView(frame: CGRect(x: paddingLeft, y: originY, width: kScreenWidth - paddingLeft * 2, height: 15))
        weekView.backgroundColor = UIColor.clear
        
        //week
        var weekArray = ["日", "一", "二", "三", "四", "五", "六"]
        var originX: CGFloat = 0.0
        for weekStr in weekArray {
            let week = UILabel()
            week.frame = CGRect(x: originX, y: 0, width: itemWidth, height: 15)
            week.text = weekStr
            week.textColor = UIColor.white
            week.font = UIFont.boldSystemFont(ofSize: 15)
            week.textAlignment = .center
            weekView.addSubview(week)
            originX = week.frame.maxX + margin
        }
        return weekView
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumLineSpacing = margin
        layout.minimumInteritemSpacing = margin
        
        let tempRect = CGRect(x: paddingLeft, y: self.headerView.frame.maxY, width: kScreenWidth - paddingLeft * 2, height: 244)
        let colV = UICollectionView(frame: tempRect, collectionViewLayout: layout)
        colV.backgroundColor = UIColor.white
        colV.dataSource = self
        colV.delegate = self
        colV.register(IVCalendarCell.self, forCellWithReuseIdentifier: NSStringFromClass(IVCalendarCell.self))
        return colV
    }()
    
    
    // MARK: - init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        //init
        _initCalendarInfo()
        
        self.addSubview(headerView)
        headerView.addSubview(dateLabel)
        headerView.addSubview(lastMonthButton)
        headerView.addSubview(nextMonthButton)
        headerView.addSubview(cancelButton)
        headerView.addSubview(weekView)
        
        self.addSubview(collectionView)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //初始化日历信息
    func _initCalendarInfo() {
        //当前月份的总天数
        self.currentMonthTotalDays = daysInMonth(date: referenceDate)
        
        //当前月份第一天是周几
        self.firstDayIsWeekInMonth = firstWeekInMonth(date: referenceDate)
        
        self.dateLabel.text = stringFromDate(date: referenceDate, format: "yyyy-MM")
        
        //是否当月
        self.isCurrentMonth = Calendar.current.isDate(referenceDate, equalTo: Date(), toGranularity: .month)
        
        //重置日历高度
        let days = self.currentMonthTotalDays + self.firstDayIsWeekInMonth
        let rowCount: Int = (days / 7) + 1
        let kitHeight: CGFloat = itemWidth * CGFloat(rowCount) + CGFloat(rowCount) * margin
        collectionView.frame.size.height = kitHeight
    }
}

private extension IVCalendar {

    func stringFromDate(date: Date, format: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = format
        let dateStr = fmt.string(from: date)
        return dateStr
    }
    
    func lastMonth(_ date: Date) -> Date {
        let month = Calendar.current.date(byAdding: .month, value: -1, to: date)!
        return month
    }
    
    func nextMonth(_ date: Date) -> Date {
        let month = Calendar.current.date(byAdding: .month, value: 1, to: date)!
        return month
    }
    
    func daysInMonth(date: Date) -> Int {
        let days = Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 0
        return days
    }
    
    func firstWeekInMonth(date: Date) -> Int {
        let date1 = dateOfDay(1, from: date)
        let week = Calendar.current.component(.weekday, from: date1) - 1
        return week
    }
    
    func dayOfDate(_ date: Date) -> Int {
        let day = Calendar.current.component(.day, from: date)
        return day
    }
    
    func dateOfDay(_ day: Int, from date: Date) -> Date {
        var components = Calendar.current.dateComponents(in: .current, from: date)
        components.day = day
        return components.date!
    }
    
    func inFuture(_ day: Int, for date: Date) -> Bool {
        let dateN = dateOfDay(day, from: date)
        return Calendar.current.compare(Date(), to: dateN, toGranularity: .day) == .orderedAscending
    }
}

extension IVCalendar: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return firstWeekInMonth(date: referenceDate) + daysInMonth(date: referenceDate)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(IVCalendarCell.self), for: indexPath) as! IVCalendarCell

        cell.clear()

        if indexPath.row >= firstWeekInMonth(date: referenceDate) {
            let day = indexPath.row - firstWeekInMonth(date: referenceDate) + 1
            let date = dateOfDay(day, from: referenceDate)
            
            cell.dayLabel.text = "\(day)"
            cell.markLayer.isHidden = !markDates.contains(date)
            
            if date < (lowerValidDate ?? Date.distantPast) || date > Date() {
                cell.dayLabel.textColor = .gray
            }

            if Calendar.current.isDate(date, inSameDayAs: currentDate) {
                cell.dayLabel.backgroundColor = .blue
                cell.dayLabel.textColor = .white
            }
        }
        
        return cell
    }
}

extension IVCalendar: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let day = indexPath.row - firstWeekInMonth(date: referenceDate) + 1
        if indexPath.row < firstWeekInMonth(date: referenceDate) || inFuture(day, for: referenceDate) { return }
        let selectDate = dateOfDay(day, from: referenceDate)
        delegate?.calendar(self, didSelect: selectDate)
    }
}


class IVCalendarCell: UICollectionViewCell {
    
    func clear() {
        dayLabel.text = nil
        dayLabel.backgroundColor = .white
        dayLabel.textColor = .black
        subLabel.text = nil
        markLayer.isHidden = true
    }
    
    lazy var dayLabel: UILabel = {
        let W: CGFloat = 32.0
        let padding = (itemWidth - W) / 2.0
        let lb = UILabel(frame: CGRect(x: padding, y: padding, width: W, height: W))
        lb.layer.cornerRadius = W / 2
        lb.layer.masksToBounds = true
        lb.textAlignment = .center
        lb.textColor = .black
        lb.font = .systemFont(ofSize: 14)
        addSubview(lb)
        return lb
    }()
    
    lazy var subLabel: UILabel = {
        let lb = UILabel(frame: CGRect(x: 0, y: bounds.height-15, width: bounds.width, height: 15))
        lb.textAlignment = .center
        lb.textColor = .gray
        lb.font = .systemFont(ofSize: 10)
        addSubview(lb)
        return lb
    }()
        
    lazy var markLayer: CALayer = {
        let W: CGFloat = 6
        let mark = CALayer()
        mark.backgroundColor = UIColor.red.cgColor
        mark.frame = CGRect(x: (self.frame.width - W)/2, y: self.frame.height - W, width: W, height: W)
        mark.cornerRadius = W / 2
        mark.masksToBounds = true
        layer.addSublayer(mark)
        return mark
    }()
}
