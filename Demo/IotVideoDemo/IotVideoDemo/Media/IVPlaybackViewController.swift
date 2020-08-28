//
//  IVPlaybackViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/12/11.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo
import MBProgressHUD

class IVPlaybackViewController: IVDevicePlayerViewController {
    
    @IBOutlet weak var timelineView: IVTimelineView?
    @IBOutlet weak var seekTimeLabel: UILabel!
    @IBOutlet weak var deviceRecordBtn: UIButton!

    var playbackPlayer: IVPlaybackPlayer? {
        get { return player as? IVPlaybackPlayer }
        set { player = newValue }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playbackPlayer = IVPlaybackPlayer(deviceId: device.deviceID)
        timelineView?.delegate = self
        deviceRecordBtn.isSelected = UserDefaults.standard.bool(forKey: "\(device.deviceID).isSelected")
    }
        
    /// 获取回放列表
    func loadPlaybackItems(timeRange: IVTime, completionHandler: @escaping ([IVPlaybackItem]?) -> Void) {
        seekTimeLabel.isHidden = true
        // ⚠️如果时间跨度太大请合理使用分页功能，否则可能影响查询速度
        IVPlaybackPlayer.getPlaybackList(ofDevice: device.deviceID, pageIndex: 0, countPerPage: 900, startTime: timeRange.start, endTime: timeRange.end) { (page, err) in
            guard let items = page?.items else {
                completionHandler(nil)
                logError(err as Any)
                return
            }
            
            completionHandler(items)
        }
    }
    
    @IBAction func deviceRecordClicked(_ sender: UIButton) {
        let data: Data
        if !sender.isSelected {
            data = "record_start".data(using: .utf8)!
        } else {
            data = "record_stop".data(using: .utf8)!
        }
        
        sender.isEnabled = false
        let hud = ivLoadingHud()
        IVMessageMgr.sharedInstance.sendData(toDevice: device.deviceID, data: data, withoutResponse: { [weak self]_, err in
            hud.hide()
            guard let `self` = self else { return }
            if let err = err {
                IVPopupView.showAlert(message: err.localizedDescription, in: self.mediaView)
            } else {
                IVPopupView.showAlert(message: "发送成功", in: self.mediaView)
                sender.isSelected = !sender.isSelected
                UserDefaults.standard.set(sender.isSelected, forKey: "\(self.device.deviceID).isSelected")
            }
            
            sender.isEnabled = true
        })
    }
    
    override func playClicked(_ sender: UIButton) {
        guard let playbackPlayer = playbackPlayer else { return }
        if playbackPlayer.playbackItem == nil {
            //加载数据后自动预选择一段视频
            if let item = timelineView?.viewModel.anyRawItem?.rawValue as? IVPlaybackItem {
                playbackPlayer.setPlaybackItem(item, seekToTime: item.startTime)
                super.playClicked(sender)
            } else {
                IVPopupView.showAlert(title: "当前日期无可播放文件", in: self.mediaView)                
            }
        } else {
            super.playClicked(sender)
        }
    }
}

extension IVPlaybackViewController: IVTimelineViewDelegate {
    func timelineView(_ timelineView: IVTimelineView, markListForCalendarAt time: IVTime, completionHandler: @escaping ([IVCSMarkItem]?) -> Void) {
        completionHandler([])
    }
    
    func timelineView(_ timelineView: IVTimelineView, itemsForTimelineAt timeRange: IVTime, completionHandler: @escaping ([IVTimelineItem]?) -> Void) {
        loadPlaybackItems(timeRange: timeRange) { (playbackItems) in
            let timelineItems = playbackItems?.compactMap({ IVTimelineItem(start: $0.startTime,
                                                                          end: $0.endTime,
                                                                          type: $0.type,
                                                                          rawValue: $0) })
            completionHandler(timelineItems)
        }
    }
    
    func timelineView(_ timelineView: IVTimelineView, didSelect item: IVTimelineItem?, at time: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {[weak self] in
            self?.seekTimeLabel.isHidden = true
        }
        guard let playbackPlayer = playbackPlayer else { return }
        if let playbackItem = item?.rawValue as? IVPlaybackItem {
            if playbackPlayer.status == .stopped {
                playbackPlayer.setPlaybackItem(playbackItem, seekToTime: time)
                playbackPlayer.play()
            } else {
                playbackPlayer.seek(toTime: time, playbackItem: playbackItem)
            }
        }

        activityIndicatorView.startAnimating()
    }
    
    func timelineView(_ timelineView: IVTimelineView, didScrollTo time: TimeInterval) {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        let date = Date(timeIntervalSince1970: time)
        seekTimeLabel.text = fmt.string(from: date)
        seekTimeLabel.isHidden = false
    }
    
    override func player(_ player: IVPlayer, didUpdatePTS PTS: TimeInterval) {
        super.player(player, didUpdatePTS: PTS)
        timelineView?.viewModel.update(pts: PTS)
    }
}
