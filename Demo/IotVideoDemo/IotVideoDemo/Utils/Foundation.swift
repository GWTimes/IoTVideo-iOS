//
//  Foundation.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/1/2.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation

extension Data {
    func string(with encoding: String.Encoding) -> String? {
        return String(data: self, encoding: encoding)
    }
}

