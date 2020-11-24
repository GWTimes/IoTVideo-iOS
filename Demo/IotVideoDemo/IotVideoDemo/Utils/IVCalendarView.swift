//
//  IVCalendarView.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/4/14.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit


private let margin: CGFloat = 10.0
private let paddingLeft: CGFloat = 20.0

class IVCalendarView: UIView {
    // MARK: - Property
    
    // 需要标记的日期数组
    public var markableDates: [TimeInterval] = [] {
        didSet {
            DispatchQueue.main.async {[weak self] in
                CATransaction.setDisableActions(true)
                self?.collectionView.reloadData()
                CATransaction.commit()
            }
        }
    }
    
    // 当前选中日期
    public var currentDate = Date() {
        didSet { referenceDate = currentDate }
    }

    /// 点击选择日期回调
    public var selectedDateCallback: ((_ date: Date) -> Void)?

    // 参考日期
    private var referenceDate = Date() {
        didSet {
            DispatchQueue.main.async {[weak self] in
                CATransaction.setDisableActions(true)
                self?.collectionView.reloadData()
                CATransaction.commit()
            }
        }
    }
    private var isCurrentMonth: Bool = false //是否当月
    private var currentMonthTotalDays: Int = 0
    private var firstDayIsWeekInMonth: Int = 0 //每月的一号对于的周几
//    private let today: String = String(day(Date()))  //当天几号

    // MARK: - UI
    
    private lazy var headerBar: UIView = {
        let headV = UIView()
        headV.backgroundColor = UIColor(rgb: 0x0075fe)
        return headV
    }()
    
    private lazy var dateLabel: UILabel = {
        let dateLb = UILabel()
        dateLb.textAlignment = .center
        dateLb.textColor = .white
        dateLb.font = .systemFont(ofSize: 17)
        return dateLb
    }()

    private lazy var lastMonthButton: UIButton = {
        let btn = UIButton()
        if let img = UIImage(named: "iot_arrow_left") {
            btn.setImage(img, for: .normal)
        } else {
            btn.setTitle("<", for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 17)
        }
        btn.addEvent { [unowned self](_) in
            self.referenceDate = self.lastMonth(self.referenceDate)
            self._initCalendarInfo()
            CATransaction.setDisableActions(true)
            self.collectionView.reloadData()
            CATransaction.commit()
        }
        return btn
    }()

    private lazy var nextMonthButton: UIButton = {
        let btn = UIButton()
        if let img = UIImage(named: "iot_arrow_right") {
            btn.setImage(img, for: .normal)
        } else {
            btn.setTitle(">", for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 17)
        }
        btn.addEvent { [unowned self](_) in
            self.referenceDate = self.nextMonth(self.referenceDate)
            self._initCalendarInfo()
            CATransaction.setDisableActions(true)
            self.collectionView.reloadData()
            CATransaction.commit()
        }
        return btn
    }()

    private lazy var todyButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("今天", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15)
        btn.addEvent { [unowned self](_) in
            self.currentDate = Date()
            self._initCalendarInfo()
            CATransaction.setDisableActions(true)
            self.collectionView.reloadData()
            CATransaction.commit()
        }
        return btn
    }()

    private lazy var weekView: UIStackView = {
        let weekView = UIStackView()
        weekView.axis = .horizontal
        weekView.alignment = .center
        weekView.distribution = .fillEqually
        var weekArray = ["日", "一", "二", "三", "四", "五", "六"]
        for weekStr in weekArray {
            let week = UILabel()
            week.text = weekStr
            week.textColor = UIColor.white
            week.font = UIFont.boldSystemFont(ofSize: 15)
            week.textAlignment = .center
            weekView.addArrangedSubview(week)
        }
        return weekView
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = margin
        layout.minimumInteritemSpacing = margin
        
        let tempRect = CGRect(x: paddingLeft, y: self.headerBar.frame.maxY, width: kScreenWidth - paddingLeft * 2, height: 244)
        let colV = UICollectionView(frame: tempRect, collectionViewLayout: layout)
        colV.backgroundColor = UIColor.white
        colV.dataSource = self
        colV.delegate = self
        colV.register(IVCalendarCell.self, forCellWithReuseIdentifier: NSStringFromClass(IVCalendarCell.self))
        return colV
    }()
    
    private lazy var footerBar: UIView = {
        let headV = UIView()
//        headV.backgroundColor = UIColor(rgb: 0x0075fe)
        return headV
    }()

    private lazy var cancelButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("取消", for: .normal)
        btn.setTitleColor(UIColor.gray, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17)
        btn.addEvent { [unowned self](_) in
            self.alpha = 0
        }
        return btn
    }()

    private lazy var confirmButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("确定", for: .normal)
        btn.setTitleColor(UIColor(rgb: 0x0075fe), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17)
        btn.addEvent { [unowned self](_) in
            self.alpha = 0
            self.selectedDateCallback?(self.currentDate)
        }
        return btn
    }()

    
    // MARK: - init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        //init
        _initCalendarInfo()
     
        prepareView()
        prepareLayout()
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
    }
    
    private func prepareView() {
        addSubview(headerBar)
        headerBar.addSubview(dateLabel)
        headerBar.addSubview(lastMonthButton)
        headerBar.addSubview(nextMonthButton)
        headerBar.addSubview(todyButton)
        headerBar.addSubview(weekView)
        
        addSubview(collectionView)

        addSubview(footerBar)
        footerBar.addSubview(cancelButton)
        footerBar.addSubview(confirmButton)
    }
    
    private func prepareLayout() {
        headerBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(40 + 40)
        }
        
        dateLabel.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.width.equalTo(140)
            make.height.equalTo(40)
        }
        
        lastMonthButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(dateLabel)
            make.height.width.equalTo(40)
            make.right.equalTo(dateLabel.snp.left)
        }
        
        nextMonthButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(dateLabel)
            make.height.width.equalTo(40)
            make.left.equalTo(dateLabel.snp.right)
        }

        todyButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(dateLabel)
            make.height.width.equalTo(40)
            make.right.equalToSuperview().offset(-8)
        }

        weekView.snp.makeConstraints { (make) in
            make.top.equalTo(dateLabel.snp.bottom)
            make.left.equalTo(headerBar.snp.leftMargin)
            make.right.equalTo(headerBar.snp.rightMargin)
            make.bottom.equalToSuperview()
        }

        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(headerBar.snp.bottom)
            make.left.equalTo(headerBar.snp.leftMargin)
            make.right.equalTo(headerBar.snp.rightMargin)
            make.bottom.equalTo(footerBar.snp.top)
        }
        
        footerBar.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(44)
        }

        cancelButton.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
            make.right.equalTo(confirmButton.snp.left)
            make.width.equalTo(confirmButton)
        }
        
        confirmButton.snp.makeConstraints { (make) in
            make.top.right.bottom.equalToSuperview()
        }
    }    
}

private extension IVCalendarView {

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

extension IVCalendarView: UICollectionViewDataSource {
    
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
            let mark = markableDates.contains(where: { Calendar.current.isDate(Date(timeIntervalSince1970: Double($0)), inSameDayAs: date) })
            cell.markLayer.isHidden = !mark
            
            if /*date.timeIntervalSince1970 < (markableDates.first ?? 0) ||*/ date > Date() {
                cell.dayLabel.textColor = .lightGray
//                if Int(date.timeIntervalSince1970) < (markableDates.first ?? 0) {
//                    cell.subLabel.text = "过期"
//                }
            }

            if Calendar.current.isDate(date, inSameDayAs: currentDate) {
                cell.dayLabel.backgroundColor = .blue
                cell.dayLabel.textColor = .white
            }
        }
        
        return cell
    }
}

extension IVCalendarView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let days = self.currentMonthTotalDays + self.firstDayIsWeekInMonth
        let rowCount: Int = (days / 7) + 1
        let W = (collectionView.bounds.width - paddingLeft * 2 - margin * 6) / 7.0
        let H = (collectionView.bounds.height - margin * 6) / CGFloat(rowCount)
        return CGSize(width: W, height: H)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! IVCalendarCell
        if cell.dayLabel.textColor == .lightGray { return }
        
        let day = indexPath.row - firstWeekInMonth(date: referenceDate) + 1
        currentDate = dateOfDay(day, from: referenceDate)
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
        let lb = UILabel(frame: CGRect(x: 0, y: 0, width: W, height: W))
        lb.layer.cornerRadius = W / 2
        lb.layer.masksToBounds = true
        lb.textAlignment = .center
        lb.textColor = .black
        lb.font = .systemFont(ofSize: 17)
        addSubview(lb)
        return lb
    }()
    
    lazy var subLabel: UILabel = {
        let lb = UILabel(frame: CGRect(x: 0, y: bounds.height-15, width: bounds.width, height: 15))
        lb.textAlignment = .center
        lb.textColor = .lightGray
        lb.font = .systemFont(ofSize: 9)
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
