//
//  IVObservable.swift
//  IotVideoDemoDev
//
//  Created by JonorZhang on 2020/7/2.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation

class IVObservable<T> {
    typealias Action = ((new: T, old: T)) -> Void
    
    private var actions: [Action] = []
    
    func addObserve(_ action: @escaping Action) {
        self.actions.append(action)
    }
    
    func observe(_ action: @escaping Action) {
        self.actions = [action]
    }
        
    var value: T {
        didSet {
            actions.forEach { action in
                action((value, oldValue))
            }
        }
    }
    
    init(_ value: T) {
        self.value = value
    }
}
