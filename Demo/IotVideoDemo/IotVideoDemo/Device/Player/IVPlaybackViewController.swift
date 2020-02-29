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
            timelineView?.setDataSource(list)
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

        var list = [IVPlaybackItem]()

        IVPlaybackPlayer.getPlaybackList(ofDevice: device.deviceID, pageIndex: 0, countPerPage: 50, startTime: 0, endTime: Date().timeIntervalSince1970, completionHandler: { (page, err) in
            guard let items = page?.items else {
                logError(err as Any)
                return
            }
            logInfo(items)
            list += items
        })
        
    #if false //假数据
        let tb = 1582624578.0
        let times = [(0, 10.3), (15.123, 30.345), (30.5, 40.213), (60.7, 93.2), (93.5, 100), (200, 1000), (1100, 2000), (2020, 4000), (5000, 7060), (8100, 9000), (10086, 11888), (11986, 15888), (17986, 21888), (70000, 86400)]
        for (t0, t1) in times {
            let item = IVPlaybackItem()
            item.startTime = t0 + tb
            item.endTime = t1 + tb
            item.duration = item.endTime - item.startTime
            item.type = ""
            list.append(item)
        }
    #endif
        
        self.playbackList += list
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
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        let date = Date(timeIntervalSince1970: time)
        seekTimeLabel.text = fmt.string(from: date)
        seekTimeLabel.isHidden = false

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
