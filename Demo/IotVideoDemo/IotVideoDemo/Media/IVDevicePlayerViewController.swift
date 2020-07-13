//
//  IVDevicePlayerViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/12/25.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo
import Photos
import Then

private let minVScale: CGFloat = 1.0
private let maxVScale: CGFloat = 3.0

class IVDevicePlayerViewController: UIViewController, IVDeviceAccessable {
    @IBOutlet weak var playBtn: UIButton!
    
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var screenshotBtn: UIButton!
    @IBOutlet weak var userdataFiled: UITextField!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var deviceIdLabel: UILabel?
    
    // IVPlayerTalkable
    @IBOutlet weak var speakerBtn: UIButton?
    @IBOutlet weak var micBtn: UIButton?
    
    // IVLivePlayer
    @IBOutlet weak var cameraBtn: UIButton?
    
    var sourceID: Int = 0
    var device: IVDevice!
    var player: IVPlayer?
    var mediaView: UIView? { player?.videoView }
    
    private lazy var vscale: CGFloat = 1.0
    private lazy var focus: (sx:CGFloat, sy:CGFloat) = (0, 0)
    private lazy var lastViewSize = view.bounds.size
    
    // MARK: - 生命周期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for ctrl in [recordBtn, screenshotBtn, speakerBtn, micBtn, cameraBtn, userdataFiled] {
            ctrl?.isEnabled = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let player = player else { return }
        
        UIApplication.shared.isIdleTimerDisabled = true //禁止锁屏
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopIfNeed), name: UIApplication.didEnterBackgroundNotification, object: nil)
                
        deviceIdLabel?.text = device.deviceID + "_\(sourceID)"
        
        player.delegate = self
        if let mediaView = mediaView {
            mediaView.frame = view.bounds
            mediaView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.insertSubview(mediaView, at: 0)
            
            // 添加手势
            mediaView.addPinchGesture {[unowned self] in
                self.pinchGestureHandler($0)
            }
            mediaView.addPanGesture {[unowned self] in
                self.panGestureHandler($0)
            }
            mediaView.addTapGesture(numberOfTapsRequired: 2) {[unowned self] in
                self.doubleTapGestureHandler($0)
            }
        }
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if player == nil {
            IVPopupView(title: "播放器创建失败").show(in: self.view)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.stop()
        UIApplication.shared.isIdleTimerDisabled = false //允许锁屏
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let player = player else { return }
        resizeVideoView(player.avheader, reset: lastViewSize != view.frame.size)
        lastViewSize = view.frame.size
    }
    
    deinit {
        logInfo(self.classForCoder, #function, device.deviceID)
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - 私有方法

private extension IVDevicePlayerViewController {

    @objc func stopIfNeed() {
        guard let player = player else { return }

        if player.status != .stopped {
            player.stop()
        }
    }
    
    func requestAuthorization(_ work: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization { (status) in
            if status != .authorized {
                IVPopupView.showAlert(message: "未授权访问相册", in: self.view)
                return
            }
            DispatchQueue.main.async(execute: work)
        }
    }
    
    static func creationRequestForAsset(_ asset: Any, target: IVDevicePlayerViewController?) {
        PHPhotoLibrary.shared().performChanges({
            if let image = asset as? UIImage {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } else if let url = asset as? URL {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
        }) { (_, error) in
            DispatchQueue.main.async {
                let msg = (asset is UIImage ? "图片" : "录像") + (error != nil ? "保存失败 \(asset), \(error!)" : "已保存到相册")
                error != nil ? logError(msg, asset) : logInfo(msg, asset)
                if let target = target {
                    IVPopupView.showAlert(message: msg, in: target.view)
                } else {
                    IVPopupView.showAlert(message: msg)
                }
            }
        }
    }
    
    func resizeVideoView(_ avHeader: IVAVHeader, reset: Bool) {
        guard avHeader.videoWidth > 0, avHeader.videoHeight > 0 else { return }
        guard let mediaView = mediaView else { return }

        if reset { vscale = 1.0 }
        
        let videoRate = CGFloat(avHeader.videoWidth) / CGFloat(avHeader.videoHeight)
        let viewRate = view.frame.size.width / view.frame.size.height

        if videoRate >= viewRate {
            mediaView.frame.size.width  = view.frame.size.width * vscale
            mediaView.frame.size.height = view.frame.size.width / videoRate * vscale
            logInfo("resizeVideoView0:", device.deviceID, mediaView.frame.size)
        } else {
            mediaView.frame.size.height = view.frame.size.height * vscale
            mediaView.frame.size.width  = view.frame.size.height * videoRate * vscale
            logInfo("resizeVideoView1:", device.deviceID, mediaView.frame.size)
        }
        
        if reset { mediaView.center = view.center }
    }
    
    func adjustVideoViewFrame() {
        guard let mediaView = mediaView else { return }
        
        if mediaView.frame.width <= self.view.frame.width {
            mediaView.center.x = self.view.center.x
        } else {
            if mediaView.frame.minX > 0 { mediaView.frame.origin.x = 0 }
            if mediaView.frame.maxX < self.view.frame.maxX { mediaView.frame.origin.x = self.view.frame.maxX - mediaView.frame.width }
        }
        
        if mediaView.frame.height <= self.view.frame.height {
            mediaView.center.y = self.view.center.y
        } else {
            if mediaView.frame.minY > 0 { mediaView.frame.origin.y = 0 }
            if mediaView.frame.maxY < self.view.frame.maxY { mediaView.frame.origin.y = self.view.frame.maxY - mediaView.frame.height }
        }
    }
}

// MARK: - 点击/手势
extension IVDevicePlayerViewController {
    
    func doubleTapGestureHandler(_ ges: UIGestureRecognizer) {
        let tap = ges as! UITapGestureRecognizer
        guard let mediaView = mediaView else { return }

        if tap.state == .ended {
            UIView.animate(withDuration: 0.3) {
                var newScale = self.vscale
                if abs(self.vscale - minVScale) < 0.1 {
                    newScale = maxVScale
                } else {
                    newScale = minVScale
                }
                
                if abs(newScale - self.vscale) > 0.001 {
                    let loc = tap.location(in: mediaView)
                    let rate = newScale / self.vscale
                    let X = mediaView.frame.origin.x + (self.view.center.x - loc.x * rate)
                    let Y = mediaView.frame.origin.y + (self.view.center.y - loc.y * rate)
                    let W = mediaView.frame.width * rate
                    let H = mediaView.frame.height * rate
                    mediaView.frame = CGRect(x: X, y: Y, width: W, height: H)
                    
                    self.adjustVideoViewFrame()
                    
                    self.vscale = newScale
                    logInfo("dtap", self.vscale, mediaView.frame)
                }
            }
        }
    }
    
    func panGestureHandler(_ ges: UIGestureRecognizer) {
        let pan = ges as! UIPanGestureRecognizer
        guard let mediaView = mediaView else { return }

        if pan.state == .changed {
            let translation = pan.translation(in: mediaView)
            mediaView.center.x += translation.x
            mediaView.center.y += translation.y
            
            self.adjustVideoViewFrame()
            
            pan.setTranslation(.zero, in: mediaView)
            logInfo("pan", self.vscale, mediaView.frame)
        }
    }
    
    func pinchGestureHandler(_ ges: UIGestureRecognizer) {
        let pinch = ges as! UIPinchGestureRecognizer
        guard let mediaView = mediaView else { return }

        switch pinch.state {
        case .began:
            let loc = pinch.location(in: mediaView)
            focus = (loc.x / mediaView.frame.width, loc.y / mediaView.frame.height)
            break
        case .changed:
            var newScale = self.vscale * pinch.scale
            newScale = max(minVScale, min(maxVScale, newScale))
            
            if abs(newScale - self.vscale) > 0.001 {
                let foucsPoint = CGPoint(x: focus.sx * mediaView.frame.width, y: focus.sy * mediaView.frame.height)
                let loc = pinch.location(in: mediaView)
                let X = mediaView.frame.origin.x + (loc.x - foucsPoint.x)
                let Y = mediaView.frame.origin.y + (loc.y - foucsPoint.y)
                let W = mediaView.frame.width * newScale / self.vscale
                let H = mediaView.frame.height * newScale / self.vscale
                mediaView.frame = CGRect(x: X, y: Y, width: W, height: H)
                
                self.vscale = newScale
            }
        case .ended:
            self.adjustVideoViewFrame()
            logInfo("pinch", self.vscale, mediaView.frame)
        default:
            break
        }
        pinch.scale = 1
    }
    
    @IBAction func playClicked(_ sender: UIButton) {
        guard let player = player else { return }

        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            if let player = player as? IVPlaybackPlayer,
                player.status == .paused {
                player.resume()
            } else {
                player.play()
            }
        } else {
            if let player = player as? IVPlaybackPlayer {
                player.pause()
            } else {
                player.stop()
            }
        }
    }
    
    @IBAction func recordClicked(_ sender: UIButton) {
        guard let player = player else { return }

        if player.isRecording {
            player.stopRecord()
            sender.isSelected = false
        } else {
            requestAuthorization { [weak self] in
                let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
                let mp4Path = docPath + "/" + Date().string() + ".mp4"
                self?.player?.startRecord(mp4Path) { (savePath, error) in
                    sender.isSelected = false
                    guard let savePath = savePath else {
                        IVPopupView.showAlert(message: error?.localizedDescription ?? "录像失败", in: self?.view)
                        return
                    }
                    let url = URL(fileURLWithPath: savePath)
                    IVDevicePlayerViewController.creationRequestForAsset(url, target: self)
                }
                sender.isSelected = true
            }
        }
    }
    
    @IBAction func screenshotClicked(_ sender: UIButton) {
        requestAuthorization {  [weak self] in
            self?.player?.takeScreenshot({ (image) in
                guard let image = image else {
                    IVPopupView.showAlert(message: "截图失败", in: self?.view)
                    return
                }
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    let imgW: CGFloat = 150
                    let imgH = imgW / image.size.width * image.size.height
                    let imgVrect = CGRect(x: 8, y: self.view.bounds.size.height - imgH - 8, width: imgW, height: imgH)
                    let imgView = UIImageView(frame: imgVrect)
                    imgView.image = image
                    self.view.addSubview(imgView)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        imgView.removeFromSuperview()
                    }
                    IVDevicePlayerViewController.creationRequestForAsset(image, target: self)
                }
            })
        }
    }
    
    @IBAction func micClicked(_ sender: UIButton) {
        
        let status = AVAudioSession.sharedInstance().recordPermission
        if status == AVAudioSession.RecordPermission.denied {
            let errStr = "没有麦克风权限，请在设置中开启"
            logWarning(errStr)
            IVPopupView.showAlert(message: errStr, in: self.view)
            return
        }
        
        if let player = player as? IVPlayerTalkable {
            sender.isSelected = !sender.isSelected
            if sender.isSelected {
                player.stopTalk()
            } else {
                player.startTalk()
            }
        }
    }
    
    @IBAction func speakerClicked(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        player?.mute = sender.isSelected
    }
}

// MARK: - 文本框代理
extension IVDevicePlayerViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let cmd = textField.text, !cmd.isEmpty,
            let cmdData = cmd.data(using: .utf8) {
            player?.send(cmdData)
            IVPopupView.showAlert(title: "已发送", message: "\(cmdData)", in: self.view)
        }
        return true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        userdataFiled.resignFirstResponder()
    }
    
}

// MARK: - 播放器代理
extension IVDevicePlayerViewController: IVPlayerDelegate {
    func connection(_ connection: IVConnection, didUpdate status: IVConnStatus) {
        logInfo(connection.deviceId, connection.channel, "connection status:\(status.rawValue)")
    }
    
    func connection(_ connection: IVConnection, didReceiveError error: Error) {
        logError(connection.deviceId, connection.channel, error)
        IVPopupView.showConfirm(title: "通道错误", message: error.localizedDescription, in: self.view)
    }
    
    func connection(_ connection: IVConnection, didReceive data: Data) {
        logInfo(connection.deviceId, connection.channel, data.count)
    }

    func player(_ player: IVPlayer, didUpdate status: IVPlayerStatus) {
        let animating = (status == .preparing || status == .loading)
        animating ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating()
        
        playBtn.isSelected = (status == .playing)
        speakerBtn?.isSelected = player.mute
        
        if let player = player as? IVPlayerTalkable {
            micBtn?.isSelected = !player.isTalking
        }
        
        if let player = player as? IVLivePlayer {
            cameraBtn?.isSelected = !player.isCameraOpening
        }
        
        for ctrl in [recordBtn, screenshotBtn, speakerBtn, micBtn, cameraBtn, userdataFiled] {
            ctrl?.isEnabled = (status == .playing)
        }
    }
    
    func player(_ player: IVPlayer, didUpdatePTS PTS: TimeInterval) {
        logVerbose("PTS: ", PTS)
    }
    
    func player(_ player: IVPlayer, didReceiveError error: Error) {
        logError(player.deviceId, player.channel, error)
        IVPopupView.showConfirm(title: "播放器错误", message: error.localizedDescription, in: self.view)
    }
    
    func player(_ player: IVPlayer, didReceive avHeader: IVAVHeader) {
        resizeVideoView(avHeader, reset: true)
    }
}
