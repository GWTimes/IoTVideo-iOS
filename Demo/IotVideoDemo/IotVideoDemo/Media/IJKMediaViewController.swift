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
    
    var mediaPlayer: IJKMediaPlayback?
       
    var csItem: IVCSPlaybackItem? = nil
    
    var seekTime: TimeInterval = 0
    
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
        
        IVVAS.shared.getVideoList(withDeviceId: device.deviceID, timezone: timezone) { (json, error) in
            hud.hide()
            guard let json = json else {
                showAlert(msg: "\(String(describing: error))")
                completionHandler(nil)
                return
            }
            logDebug(json)
            
            var list = json.decode(IVModel<[IVCSMarkItem]>.self)?.data ?? []
            list.sort(by: { $0.dateTime < $1.dateTime })
            
            return completionHandler(list)
        }
    }

    func getPlaybackList(time: IVTime, completionHandler: @escaping ([IVCSPlaybackItem]?) -> Void) {
        let hud = ivLoadingHud()
        let timezone = TimeZone.current.secondsFromGMT()

        IVVAS.shared.getVideoPlaybackList(withDeviceId: device.deviceID,
                                          timezone: timezone,
                                          startTime: time.start,
                                          endTime: time.end)
        { (json, error) in
            hud.hide()
            guard let json = json else {
                showAlert(msg: "\(String(describing: error))")
                completionHandler(nil)
                return
            }
            logDebug(json)
            
            var list = json.ivDecode(PlayListData.self)?.palyList ?? []
            list.sort(by: { $0.starttime < $1.starttime })
            
            return completionHandler(list)
        }
    }

    private func prepareToPlay(_ item: IVCSPlaybackItem) {
        csItem = item
        guard let urlstr = item.m3u8Url, let url = URL(string: urlstr) else { return }
        
        mediaPlayer?.shutdown()
        
        if let newMediaPlayer = IJKFFMoviePlayerController(contentURL: url, with: IJKFFOptions.byDefault()) {
            IJKFFMoviePlayerController.setLogLevel(k_IJK_LOG_WARN)
            newMediaPlayer.scalingMode = .aspectFit
            newMediaPlayer.shouldAutoplay = true
            newMediaPlayer.playbackVolume = 1.0
            newMediaPlayer.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            newMediaPlayer.view.frame = videoView.bounds
            videoView.autoresizesSubviews = true
            videoView.addSubview(newMediaPlayer.view)
            newMediaPlayer.prepareToPlay()

            timer.fire()
            self.activityIndicatorView.startAnimating()
            
            let oldview = self.mediaPlayer?.view
            DispatchQueue.main.asyncAfter(deadline: .now()+5) {
                oldview?.removeFromSuperview()
            }

            mediaPlayer = newMediaPlayer
        }
    }
    
    @objc func refreshProgressSlider() {
        guard let mediaPlayer = mediaPlayer, mediaPlayer.playbackState == .playing else { return }
        
        if mediaPlayer.duration > 0, let csItem = csItem {
            let newPTS = Int64(mediaPlayer.currentPlaybackTime + Double(csItem.starttime / 1000) + 0.5)
            timelineView?.currentPTS = Double(newPTS)
        } else {
            timelineView?.currentPTS = 0
        }
    }
    
    func seek(toTime time: TimeInterval, playbackItem item: IVCSPlaybackItem) {
        if item.m3u8Url != csItem?.m3u8Url {
            seekTime = time
            prepareToPlay(item)
        } else {
            mediaPlayer?.currentPlaybackTime = time - TimeInterval(item.starttime / 1000)
        }
    }

    // MARK: - 点击事件
    
    @IBAction func playClicked(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            if csItem == nil {
                if let item = timelineView?.currentItem.rawValue as? IVCSPlaybackItem {
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
            logDebug(noti)
        }

        NotificationCenter.default.addObserver(forName: .IJKMPMoviePlayerPlaybackDidFinish, object: nil, queue: nil) { [weak self] (noti) in
            guard let `self` = self else { return }
            if self.autoPlayNextMedia, let nextCSItem = self.timelineView?.nextItem?.rawValue as? IVCSPlaybackItem {
                self.prepareToPlay(nextCSItem)
                self.mediaPlayer?.play()
            }
            logDebug(noti)
        }

        NotificationCenter.default.addObserver(forName: .IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: nil, queue: nil) {[weak self] (noti) in
            guard let `self` = self else { return }
            logDebug(noti)
            if self.seekTime != 0, let csItem = self.csItem {
                self.mediaPlayer?.currentPlaybackTime = self.seekTime - TimeInterval(csItem.starttime / 1000)
                self.seekTime = 0
            }
            self.refreshProgressSlider()
        }

        NotificationCenter.default.addObserver(forName: .IJKMPMoviePlayerPlaybackStateDidChange, object: nil, queue: nil) { [weak self](noti) in
            guard let `self` = self else { return }
            guard let mediaPlayer = self.mediaPlayer else { return }
            logDebug("IJKMPMoviePlayerPlaybackStateDidChange:", mediaPlayer.playbackState.rawValue)
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
            let timelineItems = playbackList?.compactMap({ IVTimelineItem(start: TimeInterval($0.starttime / 1000),
                                                                          end: TimeInterval($0.endtime / 1000),
                                                                          type: "",
                                                                          color: .random,
                                                                          rawValue: $0) })
            completionHandler(timelineItems)
        }
    }
    
    func timelineView(_ timelineView: IVTimelineView, didSelect item: IVTimelineItem, at time: TimeInterval) {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        let date = Date(timeIntervalSince1970: time)
        seekTimeLabel.text = fmt.string(from: date)
        seekTimeLabel.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            self.seekTimeLabel.isHidden = true
        }
        if let playbackItem = item.rawValue as? IVCSPlaybackItem {
            seek(toTime: time, playbackItem: playbackItem)
            activityIndicatorView.startAnimating()
        }
        refreshProgressSlider()
    }
}
