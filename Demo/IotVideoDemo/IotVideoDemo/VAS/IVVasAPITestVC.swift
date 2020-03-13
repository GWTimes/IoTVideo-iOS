//
//  IVVasAPITestVC.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/3.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IVVAS

class IVVasAPITestVC: UITableViewController {
    fileprivate var dataArray = [IVVASApi]()
    let IVRequest = IVVAS.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        getDataArray()
        //        let _ = IVVAS.shareInstance.copy()
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return dataArray.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IVVasAPITestVC", for: indexPath)
        cell.textLabel?.text = dataArray[indexPath.row].rawValue
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch dataArray[indexPath.row] {
        case .packageHotList:
            IVRequest.queryPackageHotList(countryCode: "CN", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .packageList:
            IVRequest.queryPackageList(countryCode: "CN", serviceType: .evs, responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .serviceOutLine:
            IVRequest.queryServiceOutline(deviceId: "", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .serviceList:
            IVRequest.queryServiceList(deviceId: "", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .createOrder:
            IVRequest.createOrder(deviceId: "", packageNo: "", couponCode: "", timezone: NSTimeZone.system.secondsFromGMT(), responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .orderInfo:
            IVRequest.queryOrderInfo(orderId: "", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .orderList:
            IVRequest.queryOrderList(deviceId: "", orderStatus: .paid, responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .orderOverview:
            IVRequest.queryOrderOverview(deviceId: "0000", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .createPayment:
            IVRequest.createPayment(orderId: "", payType: .wxpay, responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .paymentResult:
            IVRequest.queryPaymentResult(orderId: "", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .cloudList:
            IVRequest.getVideoList(deviceId: "", timezone: NSTimeZone.system.secondsFromGMT(), responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .cloudPlayback:
            let dateTime = "\(getZeroTimeInterval(Date()))"
            print(dateTime)
//            IVRequest.getVideoPlaybackList(deviceId: "", timezone: NSTimeZone.system.secondsFromGMT(), dateTime: dateTime, responseHandler: { (json, error) in
//                handleWebCallback(json: json, error: error)
//            })
        case .cloudSpeedPlay:
            IVRequest.videoSpeedPlay(deviceId: "", startTime: "\(Date().timeIntervalSince1970 - 300)", speed: 2, responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .cloudDownload:
            IVRequest.downloadVideo(deviceId: "", timezone: NSTimeZone.system.secondsFromGMT(), dateTime: "\(getZeroTimeInterval(Date()))", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .eventList:
            
            IVRequest.getEventList(deviceId: "", startTime: "\(getZeroTimeInterval(Date()))", endTime: "\(Date().timeIntervalSince1970)", lastId: 1, pageSize: 20, responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
            
        case .eventDelete:
            IVRequest.deleteEvents(eventIds: [1001,1002,1003], responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .couponOwner:
            IVRequest.queryOwnedCouponList(responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .couponPromotion:
            IVRequest.queryPromotionList(responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .couponReceive:
            IVRequest.receiveCoupons(couponIds: ["1001","1002"], responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .couponAvailable:
            IVRequest.queryAvailableCouponList(packageNo: "", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .voucherInfo:
            IVRequest.queryVoucher(voucherCode: "", responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
        case .voucherExchange:
            IVRequest.useVoucher(deviceId: "000", voucherCode: "", timezone: NSTimeZone.system.secondsFromGMT(), responseHandler: { (json, error) in
                handleWebCallback(json: json, error: error)
            })
            //        default:
            //            print("暂未实现")
        }
    }
}

extension IVVasAPITestVC {
    private func getDataArray() {
        dataArray = [.packageHotList,
                     .packageList,
                     .serviceOutLine,
                     .serviceList,
                     .createOrder,
                     .orderInfo,
                     .orderList,
                     .orderOverview,
                     .createPayment,
                     .paymentResult,
                     .cloudList,
                     .cloudPlayback,
                     .cloudSpeedPlay,
                     .cloudDownload,
                     .eventList,
                     .eventDelete,
                     .couponOwner,
                     .couponPromotion,
                     .couponReceive,
                     .couponAvailable,
                     .voucherInfo,
                     .voucherExchange]
    }
    
    /// 获取某一日的零时零分时间戳
    /// - Parameter date: 时间
    private func getZeroTimeInterval(_ date: Date) -> TimeInterval {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year,.month,.day], from: date)
        let zeroDate = calendar.date(from: components)
        return zeroDate?.timeIntervalSince1970 ?? 0
    }
    
}


/// 增值服务相关API  22
fileprivate enum IVVASApi: String {
    //MARK:- 套餐/订单
    /// 热度值套餐列表查询
    case packageHotList = "热度值套餐列表查询"
    /// 查询套餐列表
    case packageList    = "查询套餐列表"
    /// 查询设备已购买服务的概要
    case serviceOutLine = "查询设备已购买服务的概要"
    /// 查询设备所有支持的服务详情列表
    case serviceList    = "查询设备所有支持的服务详情列表"
    /// 生成订单
    case createOrder    = "生成订单"
    /// 查询订单详情
    case orderInfo      = "查询订单详情"
    /// 查询订单列表
    case orderList      = "查询订单列表"
    /// 订单信息总览
    case orderOverview  = "订单信息总览"
    /// 生成支付签名信息
    case createPayment  = "生成支付签名信息"
    /// 获取支付结果
    case paymentResult  = "获取支付结果"
    
    //MARK:- 云回放
    /// 获取云存视频列表
    case cloudList      = "获取云存视频列表"
    /// 获取云存回放m3u8列表
    case cloudPlayback  = "获取云存回放m3u8列表"
    /// 倍速回放
    case cloudSpeedPlay = "cloudSpeedPlay"
    /// 下载视频m3u8列表
    case cloudDownload  = "下载视频m3u8列表"
    
    //MARK:- 事件
    /// 事件列表查询
    case eventList      = "事件列表查询"
    /// 事件删除
    case eventDelete    = "事件删除"
    
    //MARK:- 优惠券
    /// 查看用户已经领取的优惠券列表
    case couponOwner     = "查看用户已经领取的优惠券列表"
    /// 推送促销活动的信息列表
    case couponPromotion = "推送促销活动的信息列表"
    /// 领取优惠券，支持一键领取多张
    case couponReceive   = "领取优惠券，支持一键领取多张"
    /// 获取可用的优惠券列表
    case couponAvailable = "获取可用的优惠券列表"
    
    //MARK:- 兑换码
    /// 查询兑换码对应的商品（优惠活动的套餐信息）信息
    case voucherInfo     = "查询兑换码对应的商品信息"
    /// 兑换码兑换对应的商品（优惠活动的套餐信息）
    case voucherExchange = "兑换码兑换对应的商品"
}

