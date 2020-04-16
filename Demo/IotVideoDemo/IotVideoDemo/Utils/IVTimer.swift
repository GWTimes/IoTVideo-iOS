//
//  IVTimer.swift
//  IotVideoDemo
//
//  Created by zhaoyong on 2020/4/13.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation

//MARK: 直接使用 Block,会自动加入defaultRunLoop且自动运行，但是如果要立马运行需要调用 fire()
// 通过weak self 打破循环:  Timer -> weakSelf --> Timer
extension Timer {
    /// 使用block的弱引用timer
    ///
    /// 调用时请使用
    ///
    ///     Timer.iv_scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self](_) in
    ///         //do something
    ///     }
    ///
    class func iv_scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping(Timer) -> Void) -> Timer {
        if #available(iOS 10, *) {
            return Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
        } else {
            return scheduledTimer(timeInterval: interval, target: self, selector: #selector(iv_handerTimerAction(_:)), userInfo: IVTimerBlock(block), repeats: repeats)
        }
    }
    
    //通过 userInfo 将 block内容传递过来
    @objc class private func iv_handerTimerAction(_ sender: Timer) {
        if let block = sender.userInfo as? IVTimerBlock<(Timer) -> Void> {
            block.type(sender)
        }
    }
}

//Block模型类
private class IVTimerBlock<T> {
    let type: T
    init(_ type: T) {
        self.type = type
    }
}

//MARK: 直接使用 SEL,会自动加入defaultRunLoop且自动运行，但是如果要立马运行需要调用 fire()
// 通过替换target打破引用：Timer -> proxy -> weakself -> Timer
extension Timer {
    /// 类似proxy 的弱引用Timer
    class func iv_scheduledTimer(withTimeInterval interval: TimeInterval, target: NSObjectProtocol, selector: Selector, userInfo: Any?, repeats: Bool) -> Timer {
        let proxy = IVTimerProxy.init(target: target, selector: selector)
        let timer = Timer.scheduledTimer(timeInterval: interval, target: proxy, selector: selector, userInfo: userInfo, repeats: repeats)
        proxy.timer = timer
        return timer
    }
}

private class IVTimerProxy: NSObject {
    weak var target: NSObjectProtocol?
    var selector: Selector?
    /// required，实例化timer之后需要将timer赋值给proxy，否则就算target释放了，timer本身依然会继续运行
    public weak var timer: Timer?
    
    public required init(target: NSObjectProtocol?, selector: Selector?) {
        self.target = target
        self.selector = selector
        super.init()
        // 加强安全保护
        guard target?.responds(to: selector) == true else {
            return
        }
        // 将target的selector替换为redirectionMethod，该方法会重新处理事件
        let method = class_getInstanceMethod(self.classForCoder, #selector(IVTimerProxy.redirectionMethod))!
        class_replaceMethod(self.classForCoder, selector!, method_getImplementation(method), method_getTypeEncoding(method))
    }
    
    @objc private func redirectionMethod () {
        // 如果target未被释放，则调用target方法，否则释放timer
        if self.target != nil {
            self.target?.perform(self.selector)
        } else {
            self.timer?.invalidate()
            self.timer = nil
            print("IVTimeProxy: invalidate timer.")
        }
    }
}
