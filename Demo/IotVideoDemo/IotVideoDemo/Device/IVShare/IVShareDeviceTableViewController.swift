//
//  IVShareDeviceTableViewController.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/19.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit


class IVShareDeviceTableViewController: UITableViewController, IVDeviceAccessable {
    var device: IVDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dstVC = segue.destination as? IVDeviceAccessable {
            dstVC.device = device
        }
    }

}
