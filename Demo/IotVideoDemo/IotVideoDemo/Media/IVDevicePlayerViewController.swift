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

        // 方式1. 默认使用内置采集器、编解码器、渲染器、录制器，[可选]修改某些参数；
        // 方式2. 自定义采集器、编解码器、渲染器、录制器。
        
        // ----- 高级设置 开始 ----------
         
        var cfgkvs: [String : String] = [:]
        for cfg in device.avconfig.split(separator: " ") {
            let kv = cfg.split(separator: ":")
            if kv.count > 1 {
                cfgkvs[String(kv[0])] = String(kv[1])
            } else {
                logError("非法配置: \(cfg)")
            }
        }

        if let player = player as? IVPlayerTalkable {
            if let ae = cfgkvs["-aenc"]?.lowercased(), ae == "amr" {
                player.audioEncoder.audioType = .AMR // 默认AAC
            }
            if let ar = cfgkvs["-ar"], let ari = UInt32(ar) {
                player.audioCapture.sampleRate = ari // 默认8000
            }
            // player.audioEncoder = MyAudioEncoder() // 自定义audioEncoder
        }
        if let player = player as? IVPlayerVideoable {
            // player.videoEncoder.videoType = .H264 // 默认H264
            player.videoCapture.definition = .mid // 默认low
            if let vr = cfgkvs["-vr"], let vri = Int32(vr) {
                player.videoCapture.frameRate = vri // 默认16
            }
        }
        // player.videoRender = MyVideoRender() // 自定义videoRender
        // player.audioDecoder = MyAudioDecoder() // 自定义audioDecoder
        // ....
        // ✅更多内置采集器、编解码器、渲染器、录制器详见见<IoTVideo/IVAVUtils.h>及其协议。
        
        // ----- 高级设置 结束 ----------
        
        player.delegate = self
        
        if let mediaView = mediaView {
            mediaView.frame = view.bounds
            mediaView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.insertSubview(mediaView, at: 0)
            
            // 添加手势
            view.addPinchGesture {[unowned self] in
                self.pinchGestureHandler($0)
            }
            view.addPanGesture {[unowned self] in
                self.panGestureHandler($0)
            }
            view.addTapGesture(numberOfTapsRequired: 2) {[unowned self] in
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
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
//            logDebug("resizeVideoView0:", device.deviceID, mediaView.frame.size)
        } else {
            mediaView.frame.size.height = view.frame.size.height * vscale
            mediaView.frame.size.width  = view.frame.size.height * videoRate * vscale
//            logDebug("resizeVideoView1:", device.deviceID, mediaView.frame.size)
        }
        
        if reset { mediaView.center = view.center }
    }
    
    func adjustMediaViewPosition() {
        guard let mediaView = mediaView else { return }
        if mediaView.frame.width <= self.view.frame.width {
            mediaView.center.x = self.view.center.x
        } else {
            if mediaView.frame.minX > 0 {
                mediaView.frame.origin.x = 0
            }
            if mediaView.frame.maxX < self.view.frame.maxX {
                mediaView.frame.origin.x = self.view.frame.maxX - mediaView.frame.width
            }
        }
        if mediaView.frame.height <= self.view.frame.height {
            mediaView.center.y = self.view.center.y
        } else {
            if mediaView.frame.minY > 0 {
                mediaView.frame.origin.y = 0
            }
            if mediaView.frame.maxY < self.view.frame.maxY {
                mediaView.frame.origin.y = self.view.frame.maxY - mediaView.frame.height
            }
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
                    
                    self.adjustMediaViewPosition()
                    
                    self.vscale = newScale
                    logInfo("dtap", self.vscale, mediaView.frame)
                }
            }
        }
    }
    
    func panGestureHandler(_ ges: UIGestureRecognizer) {
        let pan = ges as! UIPanGestureRecognizer
        guard let mediaView = mediaView else { return }
        
        switch pan.state {
        case .began:
            logInfo("pan began", self.vscale, mediaView.frame)
        case .changed:
            let translation = pan.translation(in: mediaView)
            mediaView.center.x += translation.x
            mediaView.center.y += translation.y
            self.adjustMediaViewPosition()
            pan.setTranslation(.zero, in: mediaView)
        case .ended:
            logInfo("pan ended", self.vscale, mediaView.frame)
        default:
            break
        }
    }
    
    func pinchGestureHandler(_ ges: UIGestureRecognizer) {
        let pinch = ges as! UIPinchGestureRecognizer
        guard let mediaView = mediaView else { return }

        switch pinch.state {
        case .began:
            let loc = pinch.location(in: mediaView)
            let locX = min(max(loc.x, 0), mediaView.frame.width)
            let locY = min(max(loc.y, 0), mediaView.frame.height)
            focus = (sx: locX / mediaView.frame.width - 0.5, sy: locY / mediaView.frame.height - 0.5)

        case .changed:
            if pinch.scale < 1.0 && self.vscale <= minVScale { return }
            if pinch.scale > 1.0 && self.vscale >= maxVScale { return }
                
            var pinchScale = pinch.scale
            if pinchScale * self.vscale > maxVScale {
                pinchScale = maxVScale / self.vscale
            } else if pinchScale * self.vscale < minVScale {
                pinchScale = minVScale / self.vscale
            }
            self.vscale = pinchScale * self.vscale
            // 缩放
            let loc0 = CGPoint(x: focus.sx * mediaView.frame.width, y: focus.sy * mediaView.frame.height)
            mediaView.transform = mediaView.transform.scaledBy(x: pinchScale, y: pinchScale)
            // 移动
            let loc1 = CGPoint(x: focus.sx * mediaView.frame.width, y: focus.sy * mediaView.frame.height)
            let offX = (loc0.x - loc1.x) / mediaView.transform.a
            let offY = (loc0.y - loc1.y) / mediaView.transform.d
            mediaView.transform = mediaView.transform.translatedBy(x: offX, y: offY)

        case .ended:
            let oldFrame = mediaView.frame
            mediaView.transform = .identity
            mediaView.frame = oldFrame
            UIView.animate(withDuration: 0.3) {
                self.adjustMediaViewPosition()
            }
            
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
            player.stopRecording()
            sender.isSelected = false
        } else {
            requestAuthorization { [weak self] in
                let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
                let mp4Path = docPath + "/" + Date().string() + ".mp4"
                self?.player?.startRecording(mp4Path) { (savePath, error) in
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
            /*
             ⚠️温馨提示：如开启/关闭对讲前后需发送其他通信数据，如唤醒/关闭设备扬声器等，可通过`发送自定义数据`方法实现，即`func send(_ data: Data)`
            */
            if sender.isSelected {
                player.stopTalking()
            } else {
                player.startTalking()
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
            /*
             ⚠️温馨提示：此为`发送自定义数据`接口，OC接口为`-[IVConnection sendData:]`
            */
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
        logInfo(device.deviceID + "_\(sourceID)", "connection status:\(status.rawValue)")
    }
    
    func connection(_ connection: IVConnection, didUpdateSpeed speed: UInt32) {
        logVerbose(device.deviceID + "_\(sourceID)", String(format: "%.2f KB/s", Float(speed)/1024))
    }
    
    func connection(_ connection: IVConnection, didReceiveError error: Error) {
        let err = error as NSError
        let code = err.userInfo["ReasonCode"] ?? err.code
//        logError(device.deviceID + "_\(sourceID)", err)
        DispatchQueue.main.async {[weak self] in
            guard let `self` = self else { return }
            IVPopupView.showConfirm(title: "通道错误(\(code))", message: error.localizedDescription, in: self.view)
        }
    }
    
    func connection(_ connection: IVConnection, didReceive data: Data) {
        logInfo(device.deviceID + "_\(sourceID)", data.count)
    }
    
    func player(_ player: IVPlayer, didUpdate status: IVPlayerStatus) {
        let animating = (status == .preparing || status == .loading)
        DispatchQueue.main.async {[weak self] in
            guard let `self` = self else { return }
            animating ? self.activityIndicatorView.startAnimating() : self.activityIndicatorView.stopAnimating()
            
            self.playBtn.isEnabled = (status != .preparing && status != .stopping)
            self.playBtn.isSelected = (status == .playing)
            self.speakerBtn?.isSelected = player.mute
            
            if let player = player as? IVPlayerTalkable {
                self.micBtn?.isSelected = !player.isTalking
            }
            
            if let player = player as? IVLivePlayer {
                self.cameraBtn?.isSelected = !player.isCameraOpening
            }
            
            for ctrl in [self.recordBtn, self.screenshotBtn, self.speakerBtn, self.micBtn, self.cameraBtn, self.userdataFiled] {
                ctrl?.isEnabled = (status == .playing)
            }
        }
    }
    
    func player(_ player: IVPlayer, didUpdatePTS PTS: TimeInterval) {
//        logVerbose(device.deviceID + "_\(sourceID)", "PTS:", PTS)
    }
    
    func player(_ player: IVPlayer, didFinishPlaybackFile startTime: TimeInterval) {
        logVerbose(device.deviceID + "_\(sourceID)", "didFinishPlaybackFile:", startTime)
    }
    
    func player(_ player: IVPlayer, didUpdateAudience audience: Int) {
        logInfo(device.deviceID + "_\(sourceID)", audience)
        DispatchQueue.main.async {[weak self] in
            guard let `self` = self else { return }
            IVPopupView.showAlert(title: "观众人数变更", message: "当前观看人数：\(audience)", in: self.view, duration: 1.5)
        }
    }

    func player(_ player: IVPlayer, didReceiveError error: Error) {
        let err = error as NSError
        let code = err.userInfo["ReasonCode"] ?? err.code
//        logError(device.deviceID + "_\(sourceID)", error)
        DispatchQueue.main.async {[weak self] in
            guard let `self` = self else { return }
            IVPopupView.showConfirm(title: "播放器错误(\(code))", message: error.localizedDescription, in: self.view)
        }
    }
    
    func player(_ player: IVPlayer, didReceive avHeader: IVAVHeader) {
        DispatchQueue.main.async {
            self.resizeVideoView(avHeader, reset: true)
        }
    }
}
