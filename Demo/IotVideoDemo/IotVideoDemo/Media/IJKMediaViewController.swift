//
//  IJKMoviePlayer.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/1/12.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IJKMediaFramework
import IoTVideo
import IVVAS

class IJKMediaViewController: UIViewController, IVDeviceAccessable {
    var device: IVDevice!
    
    @IBOutlet weak var timelineView: IVTimelineView?
    @IBOutlet weak var seekTimeLabel: UILabel!
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var alarmList: UITableView!
    var mediaPlayer: IJKMediaPlayback?
    
    var csItem: IVCSPlaybackItem? = nil
    
    var seekTime: TimeInterval = 0
    
    var eventsInfo: IVCSEventsInfo? {
        didSet {
            if let newEvents = eventsInfo?.list {
                events = newEvents
            }
        }
    }
    var events: [IVCSEvent] = []
    var autoPlayNextMedia = true
    
    lazy var timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(refreshProgressSlider), userInfo: nil, repeats: true)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "云回放"
                
        addMediaObservers()
        timelineView?.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mediaPlayer?.shutdown()
        NotificationCenter.default.removeObserver(self)
        timer.invalidate()
    }

    func getMarkList(time: IVTime, completionHandler: @escaping ([IVCSMarkItem]?) -> Void) {
        let hud = ivLoadingHud()
        let timezone = TimeZone.current.secondsFromGMT()
        
        IVVAS.shared.getVideoDateList(withDeviceId: device.deviceID, timezone: timezone) { (json, error) in
            hud.hide()
            guard let json = json else {
                logError("\(String(describing: error))")
                completionHandler(nil)
                return
            }
            logDebug(json)

            let jsonModel = json.decode(IVModel<IVCSMarkItems>.self)
            guard jsonModel?.code == 0 else {
                logError("\(String(describing: error))")
                completionHandler([])
                return
            }
            
            let list = jsonModel?.data?.list ?? []
            return completionHandler(list)
        }
    }

    func getPlaybackList(time: IVTime, completionHandler: @escaping ([IVCSPlaybackItem]?) -> Void) {
        let hud = ivLoadingHud()
        
        IVVAS.shared.getVideoPlayList(withDeviceId: device.deviceID, startTime: time.start, endTime: time.end) { (json, error) in
            hud.hide()
            guard let json = json, error == nil else {
                logError("\(String(describing: error))")
                completionHandler([])
                return
            }
            
            let jsonModel = json.decode(IVModel<IVCSPlayListInfo>.self)
            
            guard jsonModel?.code == 0 else {
                logError("\(String(describing: jsonModel?.msg))")
                completionHandler([])
                return
            }
            let list = jsonModel?.data?.list ?? []
            return completionHandler(list)
        }
    }

    func getEventList(at time: IVTime) {
        IVVAS.shared.getEventList(withDeviceId: device.deviceID, startTime: time.start, endTime: time.end, pageSize: 50, filterTypeMask: nil, validCloudStorage: false) { (json, error) in
            logInfo("event list: \(json ?? "") , error: \(String(describing: error))")
            guard let json = json, error == nil else {
                logError("\(String(describing: error))")
                return
            }
            
            let jsonModel = json.decode(IVModel<IVCSEventsInfo>.self)
            
            guard jsonModel?.code == 0 else {
                self.alarmList.isHidden = true
                if jsonModel?.code == 10010 {
                    logInfo(jsonModel?.msg ?? "无记录")
                } else {
                    logError("\(String(describing: jsonModel?.msg))")
                }
                return
            }
            
            self.eventsInfo = jsonModel?.data
            if self.events.count == 0 {
                self.alarmList.isHidden = true
            } else {
                self.alarmList.isHidden = false
                self.alarmList.reloadData()
            }
        }
    }

    func getPlayUrl(_ item: IVCSPlaybackItem, responseHandler: ((_ url: URL?) -> Void)? = nil) {
        if let url = item.url {
            responseHandler?(url)
        } else {
            IVVAS.shared.getVideoPlayAddress(withDeviceId: device.deviceID, startTime: TimeInterval(item.start), endTiem: TimeInterval(item.end)) { (json, error) in
                guard let json = json else {
                    responseHandler?(nil)
                    if (error! as NSError).code != 21000 {
                        logError("getPlayUrl error \(item.start) \(String(describing: error))")
                    }
                    return
                }
                
                if let playInfo = json.decode(IVModel<IVCSPlayInfo>.self)?.data,
                    let urlstr = playInfo.url, let url = URL(string: urlstr) {
                    item.url = url
                    logDebug("getPlayUrl", item.start, item.end, item.url)
                    responseHandler?(url)
                } else {
                    logError("getPlayUrl empty \(item.start) \(String(describing: error))")
                    responseHandler?(nil)
                }
            }
        }
    }
    
    private func prepareToPlay(_ item: IVCSPlaybackItem) {
        logDebug("prepareToPlay", item.start)
        self.timer.fireDate = .distantFuture

        getPlayUrl(item) { (url) in
            guard let url = url else { return }
            logDebug("readyToPlay", item.start, url)
              
            let oldMediaPlayer = self.mediaPlayer
            DispatchQueue.main.async {
                oldMediaPlayer?.shutdown()
            }
            self.csItem = item

            if let newMediaPlayer = IJKFFMoviePlayerController(contentURL: url, with: IJKFFOptions.byDefault()) {
                IJKFFMoviePlayerController.setLogLevel(k_IJK_LOG_WARN)
                newMediaPlayer.scalingMode = .aspectFit
                newMediaPlayer.shouldAutoplay = true
                newMediaPlayer.playbackVolume = 1.0
                newMediaPlayer.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                newMediaPlayer.view.frame = self.videoView.bounds
                self.videoView.autoresizesSubviews = true
                self.videoView.addSubview(newMediaPlayer.view)
                newMediaPlayer.prepareToPlay()
                
                self.timer.fireDate = .distantPast
                self.activityIndicatorView.startAnimating()
                
                let oldview = oldMediaPlayer?.view
                DispatchQueue.main.asyncAfter(deadline: .now()+5) {
                    oldview?.removeFromSuperview()
                }
                
                self.mediaPlayer = newMediaPlayer
            }
        }
        
        if let nextCSItem = self.timelineView?.viewModel.nextRawItem?.rawValue as? IVCSPlaybackItem {
            getPlayUrl(nextCSItem)
        }
    }
        
    @objc func refreshProgressSlider() {
        guard let mediaPlayer = mediaPlayer, mediaPlayer.playbackState == .playing, seekTime == 0 else { return }
        if mediaPlayer.duration > 0, let csItem = csItem {
            let newPTS = Int64(mediaPlayer.currentPlaybackTime + Double(csItem.start) + 0.5)
            print("refreshProgressSlider csItemStart:\(csItem.start) currentPlaybackTime:\(mediaPlayer.currentPlaybackTime) duration:\(mediaPlayer.duration) playableDuration:\(mediaPlayer.playableDuration)")
            timelineView?.viewModel.update(pts: TimeInterval(newPTS))
        }
    }
    
    func seek(toTime time: TimeInterval, playbackItem item: IVCSPlaybackItem) {
        logDebug("seekToTime", time, item)
        
        if item.start != csItem?.start {
            seekTime = time
            prepareToPlay(item)
        } else {
            mediaPlayer?.currentPlaybackTime = time - TimeInterval(item.start)
        }
    }

    // MARK: - 点击事件
    
    @IBAction func playClicked(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            if csItem == nil {
                if let item = timelineView?.viewModel.nextRawItem?.rawValue as? IVCSPlaybackItem {
                    prepareToPlay(item)
                } else {
                    sender.isSelected = !sender.isSelected
                    IVPopupView.showAlert(title: "当前日期无可播放文件", in: self.videoView)
                    return
                }
            }
            mediaPlayer?.play()
        } else {
            mediaPlayer?.pause()
        }
        refreshProgressSlider()
    }
        
    // MARK: - 播放器代理
    
    func addMediaObservers() {
        NotificationCenter.default.addObserver(forName: .IJKMPMoviePlayerLoadStateDidChange, object: nil, queue: nil) { (noti) in
//            logDebug(noti)
        }

        NotificationCenter.default.addObserver(forName: .IJKMPMoviePlayerPlaybackDidFinish, object: nil, queue: nil) { [weak self] (noti) in
            guard let `self` = self else { return }
            logDebug("IJKMPMoviePlayerPlaybackDidFinish:", self.mediaPlayer?.playbackState.rawValue, noti.userInfo)
            if self.autoPlayNextMedia, let nextCSItem = self.timelineView?.viewModel.nextRawItem?.rawValue as? IVCSPlaybackItem {
                self.prepareToPlay(nextCSItem)
                self.mediaPlayer?.play()
            }
        }

        NotificationCenter.default.addObserver(forName: .IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: nil, queue: nil) {[weak self] (noti) in
            guard let `self` = self else { return }
            logDebug("IJKMPMediaPlaybackIsPreparedToPlayDidChange:", self.mediaPlayer?.playbackState.rawValue)
            if self.seekTime != 0, let csItem = self.csItem {
                logDebug("seekToTime:", self.seekTime - TimeInterval(csItem.start))
                self.mediaPlayer?.currentPlaybackTime = self.seekTime - TimeInterval(csItem.start)
                self.seekTime = 0
            }
            self.refreshProgressSlider()
        }

        NotificationCenter.default.addObserver(forName: .IJKMPMoviePlayerPlaybackStateDidChange, object: nil, queue: nil) { [weak self](noti) in
            guard let `self` = self else { return }
            logDebug("IJKMPMoviePlayerPlaybackStateDidChange:", self.mediaPlayer?.playbackState.rawValue)
            guard let mediaPlayer = self.mediaPlayer else { return }
            mediaPlayer.isPreparedToPlay ? self.activityIndicatorView.stopAnimating() : self.activityIndicatorView.startAnimating()
            self.playBtn.isSelected = mediaPlayer.isPlaying()
        }
    }

}

extension IJKMediaViewController: IVTimelineViewDelegate {
    
    func timelineView(_ timelineView: IVTimelineView, markListForCalendarAt time: IVTime, completionHandler: @escaping ([IVCSMarkItem]?) -> Void) {
        getMarkList(time: time, completionHandler: completionHandler)
    }
    
    func timelineView(_ timelineView: IVTimelineView, itemsForTimelineAt time: IVTime, completionHandler: @escaping ([IVTimelineItem]?) -> Void) {
        getPlaybackList(time: time) { (playbackList) in
            let timelineItems = playbackList?.compactMap({ IVTimelineItem(start: TimeInterval($0.start),
                                                                          end: TimeInterval($0.end),
                                                                          type: "",
                                                                          rawValue: $0) })
            completionHandler(timelineItems)
        }
    }
    
    func timelineView(_ timelineView: IVTimelineView, didSelectItem item: IVTimelineItem?, at time: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {[weak self] in
            self?.seekTimeLabel.isHidden = true
        }
        if let playbackItem = item?.rawValue as? IVCSPlaybackItem {
            seek(toTime: time, playbackItem: playbackItem)
            activityIndicatorView.startAnimating()
        }
        refreshProgressSlider()
    }
    
    func timelineView(_ timelineView: IVTimelineView, didSelectDateAt time: IVTime) {
        getEventList(at: time)
    }

    func timelineView(_ timelineView: IVTimelineView, didSelectRangeAt time: IVTime) {
        
    }

    func timelineView(_ timelineView: IVTimelineView, didScrollTo time: TimeInterval) {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        let date = Date(timeIntervalSince1970: round(time))
        seekTimeLabel.text = fmt.string(from: date)
        seekTimeLabel.isHidden = false
    }
}

//MARK: 事件列表
extension IJKMediaViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        cell = tableView.dequeueReusableCell(withIdentifier: "alarmListCell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "alarmListCell")
        }
        let event = events[indexPath.row]
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        let date = Date(timeIntervalSince1970: TimeInterval(event.startTime))
        cell?.textLabel?.text = "\(fmt.string(from: date))"
        cell?.detailTextLabel?.text = "type: \(event.firstAlarmType)"
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let event = self.events[indexPath.row]
        if let item = timelineView?.viewModel.current.rawItems.first(where: {$0.start <= TimeInterval(event.startTime) && TimeInterval(event.endTime) <= $0.end}) {
            seek(toTime: TimeInterval(event.startTime), playbackItem: IVCSPlaybackItem(start: Int(item.start), end: Int(item.end)))
        } else {
            seek(toTime: TimeInterval(event.startTime), playbackItem: IVCSPlaybackItem(start: event.startTime, end: event.endTime))
        }
        refreshProgressSlider()
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "删除") { (action, view, completion) in
            let event = self.events[indexPath.row]
            IVVAS.shared.deleteEvents(withDeviceId: self.device.deviceID, eventIds: [event.alarmId]) { (json, error) in
                logInfo("devent delete \(String(describing: json))")
                guard error == nil else {
                    logDebug("event delete error  \(String(describing: error))")
                    completion(false)
                    return
                }
                self.events.remove(at: indexPath.row)
                completion(true)
                self.alarmList.reloadData()
            }
        }
        let config = UISwipeActionsConfiguration(actions: [delete])
        return config
    }
}
