//
//  IVLiveViewController.swift
//  IoTVideoDemo
//
//  Created by ZhaoYong on 2019/11/29.
//  Copyright © 2019 gwell. All rights reserved.
//

import UIKit
import IoTVideo

class IVLiveViewController: IVDevicePlayerViewController {
        
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var switchBtn: UIButton!

    var livePlayer: IVLivePlayer {
        get { return player as! IVLivePlayer }
        set { player = newValue }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        livePlayer = IVLivePlayer(deviceId: device.deviceID)
        
        previewView.layer.addSublayer(livePlayer.previewLayer)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        livePlayer.play()
        livePlayer.openCamera()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        livePlayer.stop()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        livePlayer.previewLayer.frame = previewView.bounds
    }

    // MARK: - 点击事件

    @IBAction func cameraClicked(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            livePlayer.closeCamera()
        } else {
            livePlayer.openCamera()
        }
    }
    
    @IBAction func switchClicked(_ sender: UIButton) {
        livePlayer.switchCamera()
    }
}


