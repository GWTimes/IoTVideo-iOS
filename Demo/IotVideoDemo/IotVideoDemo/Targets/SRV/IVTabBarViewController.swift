//
//  IVTabBarViewController.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2019/12/3.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit

class IVTabBarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = true
        self.navigationController?.navigationBar.isHidden = true
    }        
}





