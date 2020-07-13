//
//  IVApplication.swift
//  IotVideoDemoDev
//
//  Created by JonorZhang on 2020/6/10.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit

var gStatusBarHeight: CGFloat {
    return UIApplication.shared.statusBarFrame.size.height
}

var gOrientation: UIInterfaceOrientation {
    return UIApplication.shared.statusBarOrientation
}

var gIsLandscape: Bool {
    return gOrientation.isLandscape // .landscapeLeft || .landscapeRight
}

var gIsPortrait: Bool {
    return gOrientation.isPortrait // .portrait || .portraitUpsideDown
}

var kScreenWidth:  CGFloat {
    return UIScreen.main.bounds.width
}

var kScreenHeight: CGFloat {
    return UIScreen.main.bounds.height
}
