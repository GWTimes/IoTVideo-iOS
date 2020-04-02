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
    
    var playbackList: [IVPalyBackList] = []
    var currentItem: IVPalyBackList?
    
    var seekTime: TimeInterval = 0
    
    var autoPlayNextMedia = true
    
    lazy var timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(refreshProgressSlider), userInfo: nil, repeats: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "云回放"
        
        addMediaObservers()
        timelineView?.delegate = self

        if let currenrItem = currentItem {
            self.prepareToPlay(currenrItem.m3u8Url)
        } else if !playbackList.isEmpty {
            let list = playbackList.map({ IVTimelineItem(startTime: TimeInterval($0.starttime / 1000),
                                                         endTime: TimeInterval($0.endtime / 1000),
                                                         duration: TimeInterval(($0.endtime - $0.starttime) / 1000),
                                                         type: "",
                                                         color: .random) })
            timelineView?.setDataSource(list)
        } else {
            let timezone = TimeZone.current.secondsFromGMT()
            let endTime   = "\(Int(Date().timeIntervalSince1970 * 1000))"
            let startTime = "\(Int((Date().timeIntervalSince1970 - 60*60*24*365) * 1000))"
            let hud = ivLoadingHud()
                        
            IVVAS.shared.getVideoPlaybackList(deviceId: device.deviceID,
                                              timezone: timezone,
                                              startTime: startTime,
                                              endTime: endTime)
            { (json, error) in
                hud.hide()
                guard let json = json else {
                    showAlert(msg: "\(String(describing: error))")
                    return
                }
                self.playbackList = json.ivDecode(PlayListData.self)?.palyList ?? []
                let list = self.playbackList.map({ IVTimelineItem(startTime: TimeInterval($0.starttime / 1000),
                                                                  endTime: TimeInterval($0.endtime / 1000),
                                                                  duration: TimeInterval(($0.endtime - $0.starttime) / 1000),
                                                                  type: "",
                                                                  color: .random) })
                if self.playbackList.isEmpty {
                    IVPopupView(title: "Input URL", input: ["http://cctvalih5ca.v.myalicdn.com/live/cctv1_2/index.m3u8"], actions: [.cancel(), .confirm({ (v) in
                        if let urlstr = v.inputFields[0].text, !urlstr.isEmpty {
                            self.prepareToPlay(urlstr)
                        } else {
                            self.prepareToPlay(v.inputFields[0].placeholder!)
                        }
                    })]).show()
                } else {
                    self.timelineView?.setDataSource(list)
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mediaPlayer?.shutdown()
        NotificationCenter.default.removeObserver(self)
        timer.invalidate()
    }

    private func prepareToPlay(_ urlstr: String?) {
        guard let urlstr = urlstr?.replacingOccurrences(of: "https", with: "http"), let url = URL(string: urlstr) else { return }
        
        mediaPlayer?.shutdown()

        mediaPlayer = IJKFFMoviePlayerController(contentURL: url, with: IJKFFOptions.byDefault())
        guard let mediaPlayer = mediaPlayer else { return }
        
        IJKFFMoviePlayerController.setLogLevel(k_IJK_LOG_DEFAULT)
        mediaPlayer.scalingMode = .aspectFit
        mediaPlayer.shouldAutoplay = true
        mediaPlayer.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mediaPlayer.view.frame = videoView.bounds
        videoView.autoresizesSubviews = true
        videoView.insertSubview(mediaPlayer.view, at: 0)
        mediaPlayer.prepareToPlay()
        timer.fire()
        self.activityIndicatorView.startAnimating()
    }
    
    @objc func refreshProgressSlider() {
        guard let mediaPlayer = mediaPlayer, mediaPlayer.playbackState == .playing else { return }
        
        let posstion = mediaPlayer.currentPlaybackTime
        
        let duration = mediaPlayer.duration
        let intDuration = Int(duration + 0.5)

        if intDuration > 0, let currenrItem = currentItem {
            timelineView?.currentTime = posstion + Double(currenrItem.starttime / 1000)
        } else {
            timelineView?.currentTime = 0
        }
    }
    
    func seek(toTime time: TimeInterval, playbackItem item: IVPalyBackList) {
        if item.m3u8Url != currentItem?.m3u8Url {
            currentItem = item
            seekTime = time
            prepareToPlay(item.m3u8Url)
        } else {
            mediaPlayer?.currentPlaybackTime = time - TimeInterval(item.starttime / 1000)
        }
    }

    // MARK: - 点击事件
    
    @IBAction func playClicked(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            if currentItem == nil {
                currentItem = playbackList.first
                prepareToPlay(currentItem?.m3u8Url)
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
            if self.autoPlayNextMedia,
                let currIdx = self.playbackList.firstIndex(where: { $0.m3u8Url == self.currentItem?.m3u8Url }),
                currIdx < self.playbackList.endIndex {
                self.currentItem = self.playbackList[currIdx + 1]
                self.prepareToPlay(self.currentItem?.m3u8Url)
                self.mediaPlayer?.play()
            }
            logDebug(noti)
        }

        NotificationCenter.default.addObserver(forName: .IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: nil, queue: nil) {[weak self] (noti) in
            guard let `self` = self else { return }
            logDebug(noti)
            if self.seekTime != 0, let currenrItem = self.currentItem {
                self.mediaPlayer?.currentPlaybackTime = self.seekTime - TimeInterval(currenrItem.starttime / 1000)
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
    
    func timelineView(_ timelineView: IVTimelineView, didSelect item: IVTimelineItem, at time: TimeInterval) {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        let date = Date(timeIntervalSince1970: time)
        seekTimeLabel.text = fmt.string(from: date)
        seekTimeLabel.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            self.seekTimeLabel.isHidden = true
        }
        if let playbackItem = playbackList.first(where: { $0.starttime == Int(item.startTime * 1000) }) {
            seek(toTime: time, playbackItem: playbackItem)
            activityIndicatorView.startAnimating()
        }
        refreshProgressSlider()
    }
}
