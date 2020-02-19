//
//  IVMonitorViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/12/11.
//  Copyright © 2019 gwell. All rights reserved.
//

import UIKit
import IoTVideo


class IVMonitorViewController: IVDevicePlayerViewController {
    
    var monitorPlayer: IVMonitorPlayer {
        get { return player as! IVMonitorPlayer }
        set { player = newValue }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        monitorPlayer = IVMonitorPlayer(deviceId: device.deviceID)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppDelegate.shared.allowRotation = true
        monitorPlayer.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppDelegate.shared.allowRotation = false
        UIDevice.setOrientation(.portrait)
        monitorPlayer.stop()
    }
}
