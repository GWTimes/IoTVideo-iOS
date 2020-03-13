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

class IVDevicePlayerViewController: UIViewController, IVDeviceAccessable {
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var screenshotBtn: UIButton!
    @IBOutlet weak var userdataFiled: UITextField!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    // IVPlayerTalkable
    @IBOutlet weak var speakerBtn: UIButton?
    @IBOutlet weak var micBtn: UIButton?
    
    // IVLivePlayer
    @IBOutlet weak var cameraBtn: UIButton?


    var device: IVDevice!
    var player: IVPlayer!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(stopPlayerIfNeed), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopPlayerIfNeed), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopPlayerIfNeed), name: UIApplication.willTerminateNotification, object: nil)
    
        player.delegate = self
        player.videoView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        player.videoView!.frame = videoView.bounds
        videoView.autoresizesSubviews = true
        videoView.insertSubview(player.videoView!, at: 0)
    
    }
    
    deinit {
        print(self.classForCoder, #function)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func stopPlayerIfNeed() {
        if player.status != .stoped {
            player.stop()
        }
    }
}

// MARK: - 点击事件
extension IVDevicePlayerViewController {
    @IBAction func playClicked(_ sender: UIButton) {
        if let player = player as? IVPlaybackPlayer, player.playbackItem == nil {
            showAlert(msg: "未选择回放文件")
            return
        }
        
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
        if sender.isSelected {
            player.stopRecord()
        } else {
            let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let mp4Path = docPath + "/\(Date().timeIntervalSince1970).mp4"
            player.startRecord(mp4Path) { (savePath, error) in
                guard let savePath = savePath else {
                    print("录像失败", error as Any)
                    return
                }
                print("录像成功", savePath)
                let url = URL(fileURLWithPath: savePath)
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { (success, error) in
                    guard success == true else {
                        print("视频保存到相册失败", error as Any)
                        return
                    }
                    print("视频保存到相册成功", url)
                }
            }
        }
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func screenshotClicked(_ sender: UIButton) {
        player.takeScreenshot({ (image) in
            guard let image = image else { return }
            DispatchQueue.main.sync {
                let imgW: CGFloat = 150
                let imgH = imgW / image.size.width * image.size.height
                let imgVrect = CGRect(x: 8, y: self.videoView.bounds.size.height - imgH - 8, width: imgW, height: imgH)
                let imgView = UIImageView(frame: imgVrect)
                imgView.image = image
                self.videoView.addSubview(imgView)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    imgView.removeFromSuperview()
                }
            }
        })
    }
    
    @IBAction func micClicked(_ sender: UIButton) {
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
        player.mute = sender.isSelected
    }
}

extension IVDevicePlayerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let cmd = textField.text, !cmd.isEmpty,
            let cmdData = cmd.data(using: .utf8) {
            player.sendUserData(cmdData)
            showAlert(msg: "\(cmdData)", title: "已发送")
        }
        return true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        userdataFiled.resignFirstResponder()
    }

}

extension IVDevicePlayerViewController: IVPlayerDelegate {
    func player(_ player: IVPlayer, didUpdate status: IVPlayerStatus) {
        let animating = (status == .loading || status == .preparing)
        animating ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating()
        playBtn.isSelected = (status == .playing)
        speakerBtn?.isSelected = player.mute
        
        if let player = player as? IVPlayerTalkable {
            micBtn?.isSelected = !player.isTalking
        }
        
        if let player = player as? IVLivePlayer {
            cameraBtn?.isSelected = !player.isCameraOpening
        }
    }
    
    func player(_ player: IVPlayer, didUpdatePTS PTS: TimeInterval) {
        logVerbose(PTS)
    }
    
    func player(_ player: IVPlayer, didReceiveError error: Error) {
        logError(error)
    }
    
    func player(_ player: IVPlayer, didReceive avHeader: IVAVHeader) {
//        logInfo(avHeader)
    }
    
    func player(_ player: IVPlayer, didReceiveUserData userData: Data) {
        logInfo(userData)
    }
}
