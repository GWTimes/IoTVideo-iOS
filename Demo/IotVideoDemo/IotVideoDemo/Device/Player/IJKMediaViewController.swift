//
//  IJKMoviePlayer.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/1/12.
//  Copyright © 2020 gwell. All rights reserved.
//

import UIKit
import IJKMediaFramework

class IJKMediaViewController: UIViewController {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var playBtn: UIButton!
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalDurationLabel: UILabel!
    @IBOutlet weak var progressSlider: UISlider!
    
    var url: URL?
//    var url: URL? = URL(string: "http://cctvalih5ca.v.myalicdn.com/live/cctv1_2/index.m3u8")
    var urlStr: String! = "" {
        didSet {
            url = URL(string: urlStr)
        }
    }
    var mediaPlayer: IJKMediaPlayback?
    
    lazy var timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(refreshProgressSlider), userInfo: nil, repeats: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addMediaObservers()

        if let url = url {
            self.initWithURL(url)
        } else {
//            IVPopupView(title: "Input URL", input: ["http://cctvalih5ca.v.myalicdn.com/live/cctv1_2/index.m3u8"], actions: [.cancel(), .confirm({ (v) in
            IVPopupView(title: "Input URL", input: ["http://lcb.iotvideo.tencentcs.com/timeshift/live/031400005df99fe03b8d15050eb45385/timeshift.m3u8?starttime=20200112195620&endtime=20200112195732"], actions: [.cancel(), .confirm({ (v) in
                if let urlstr = v.inputFields[0].text, !urlstr.isEmpty {
                    self.initWithURL(URL(string: urlstr))
                } else {
                    self.initWithURL(URL(string: v.inputFields[0].placeholder!))
                }
            })]).show()
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mediaPlayer?.shutdown()
        NotificationCenter.default.removeObserver(self)
        timer.invalidate()
    }

    private func initWithURL(_ url: URL?) {
        guard let url = url else { return }
        self.url = url
        mediaPlayer = IJKFFMoviePlayerController(contentURL: url, with: IJKFFOptions.byDefault())
        guard let mediaPlayer = mediaPlayer else { return }
        
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
        guard let mediaPlayer = mediaPlayer else { return }
        
        let posstion = mediaPlayer.currentPlaybackTime
        let intPosstion = Int(posstion + 0.5)
        
        let duration = mediaPlayer.duration
        let intDuration = Int(duration + 0.5)

        if (intDuration > 0) {
            progressSlider.maximumValue = Float(duration)
            progressSlider.value = Float(posstion)
            totalDurationLabel.text = String(format: "%02d:%02d", intDuration / 60, intDuration % 60)
        } else {
            progressSlider.maximumValue = 1.0
            progressSlider.value = 0
            totalDurationLabel.text = "--:--"
        }
        
        if (intPosstion > 0) {
            currentTimeLabel.text = String(format: "%02d:%02d", intPosstion / 60, intPosstion % 60)
        } else {
            currentTimeLabel.text = "--:--"
        }
    }
    
    // MARK: - 点击事件
    
    @IBAction func playClicked(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            mediaPlayer?.play()
        } else {
            mediaPlayer?.pause()
        }
        refreshProgressSlider()
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        guard let mediaPlayer = mediaPlayer else { return }
        if mediaPlayer.duration < 1.0 {
            sender.value = 0
            return
        }
        mediaPlayer.currentPlaybackTime = TimeInterval(sender.value)
        refreshProgressSlider()
    }
    
    // MARK: - 播放器代理
    
    func addMediaObservers() {
        NotificationCenter.default.addObserver(forName: .IJKMPMoviePlayerLoadStateDidChange, object: mediaPlayer, queue: nil) { (noti) in
            logDebug(noti)
        }

        NotificationCenter.default.addObserver(forName: .IJKMPMoviePlayerPlaybackDidFinish, object: mediaPlayer, queue: nil) { (noti) in
            logDebug(noti)
        }

        NotificationCenter.default.addObserver(forName: .IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: mediaPlayer, queue: nil) {[weak self] (noti) in
            logDebug(noti)
            self?.refreshProgressSlider()
        }

        NotificationCenter.default.addObserver(forName: .IJKMPMoviePlayerPlaybackStateDidChange, object: mediaPlayer, queue: nil) { [weak self](noti) in
            guard let `self` = self else { return }
            guard let mediaPlayer = self.mediaPlayer else { return }
            logDebug(noti)
            mediaPlayer.isPreparedToPlay ? self.activityIndicatorView.stopAnimating() : self.activityIndicatorView.startAnimating()
            self.playBtn.isSelected = mediaPlayer.isPlaying()
        }
    }

}
