//
//  IVObservable.swift
//  IotVideoDemoDev
//
//  Created by JonorZhang on 2020/7/2.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation

class IVObservable<T> {
    typealias Observer = (T) -> Void
    var observer: Observer?
    
    func observe(_ observer: Observer?) {
        self.observer = observer
//        observer?(value)
    }
    
    var value: T {
        didSet {
            observer?(value)
        }
    }
    
    init(_ value: T) {
        self.value = value
    }
}
