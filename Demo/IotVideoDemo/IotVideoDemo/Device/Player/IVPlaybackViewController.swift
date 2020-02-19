//
//  IVPlaybackViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/12/11.
//  Copyright © 2019 gwell. All rights reserved.
//

import UIKit
import IoTVideo

class IVPlaybackViewController: IVDevicePlayerViewController {
    
    @IBOutlet weak var timelineView: IVTimelineView?
    @IBOutlet weak var seekTimeLabel: UILabel!
    
    var playbackList: [IVPlaybackItem] = [] {
        didSet {
            let list = playbackList.map({ IVTimelineItem(startTime: $0.startTime,
                                                         endTime: $0.endTime,
                                                         duration: $0.endTime-$0.startTime,
                                                         type: $0.type,
                                                         color: .random) })
            timelineView?.appendItems(list)
        }
    }
    
    var playbackPlayer: IVPlaybackPlayer {
        get { return player as! IVPlaybackPlayer }
        set { player = newValue }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playbackPlayer = IVPlaybackPlayer(deviceId: device.deviceID)
        
        timelineView?.delegate = self
        seekTimeLabel.isHidden = true

        IVPlaybackPlayer.getPlaybackList(ofDevice: device.deviceID, pageIndex: 0, countPerPage: 50, startTime: 0, endTime: Date().timeIntervalSince1970, completionHandler: { (page, err) in
            guard let items = page?.items else {
                logError(err as Any)
                return
            }
            logInfo(items)
            self.playbackList += items
        })
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppDelegate.shared.allowRotation = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppDelegate.shared.allowRotation = false
        UIDevice.setOrientation(.portrait)
        playbackPlayer.stop()
    }
    
    @IBAction func deviceRecordClicked(_ sender: UIButton) {
        let data: Data
        if !sender.isSelected {
            data = "record_start".data(using: .utf8)!
        } else {
            data = "record_stop".data(using: .utf8)!
        }
        sender.isEnabled = false
        IVMessageMgr.sharedInstance.sendData(toDevice: device.deviceID, data: data, withoutResponse: { _, err in
            if let err = err {
                showAlert(msg: err.localizedDescription)
            } else {
                showAlert(msg: "发送成功")
                sender.isSelected = !sender.isSelected
                sender.isEnabled = true
            }
        })
    }
}

extension IVPlaybackViewController: IVTimelineViewDelegate {
    
    func timelineView(_ timelineView: IVTimelineView, didSelect item: IVTimelineItem, at time: TimeInterval) {
        seekTimeLabel.isHidden = false
        seekTimeLabel.text = "\(Int64(time))"
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            self.seekTimeLabel.isHidden = true
        }
        if let playbackItem = playbackList.first(where: { $0.startTime == item.startTime }) {
            if playbackPlayer.status == .stoped {
                playbackPlayer.setPlaybackItem(playbackItem, seekToTime: time)
                playbackPlayer.play()
            } else {
                playbackPlayer.seek(toTime: time, playbackItem: playbackItem)
            }
            activityIndicatorView.startAnimating()
        }
    }
    
    override func player(_ player: IVPlayer, didUpdatePTS PTS: TimeInterval) {
        super.player(player, didUpdatePTS: PTS)
        timelineView?.currentTime = PTS
    }
}
