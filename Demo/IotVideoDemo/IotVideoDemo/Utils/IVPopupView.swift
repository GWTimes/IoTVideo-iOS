//
//  IVPopupView.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/3/8.
//  Copyright © 2019年 Tencentcs. All rights reserved.
//

import UIKit
import WebKit
import Then
import SnapKit

@objc enum IVPopupActionStyle : Int {
    case `default`
    case cancel
    case destructive
}

class IVPopupAction: UIButton {
    
    typealias Style = IVPopupActionStyle
    
    fileprivate var style: Style
    
    fileprivate var title: String?

    fileprivate var handler: ((IVPopupView) -> Void)?
    
    fileprivate weak var owner: IVPopupView!
    
    @objc init(title: String? = nil, style: Style = .default, handler: ((IVPopupView) -> Void)? = nil) {
        self.title   = title
        self.style   = style
        self.handler = handler
        super.init(frame: .zero)
        
        switch style {
        case .default:
            setTitleColor(UIColor(rgb: 0x2E6DEA), for: .normal)
            titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        case .cancel:
            setTitleColor(UIColor(rgb: 0x999999), for: .normal)
            titleLabel?.font = UIFont.systemFont(ofSize: 17)
        case .destructive:
            setTitleColor(UIColor.red, for: .normal)
            titleLabel?.font = UIFont.systemFont(ofSize: 17)
        }
        backgroundColor = UIColor.white
        setTitle(title, for: .normal)
        addTarget(self, action: #selector(didClicked), for: .touchUpInside)
        titleLabel?.numberOfLines = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didClicked() {
        handler?(owner)
    }
}

@objc enum IVPopupViewStyle : Int {
    /// 警告： title + message + actions
    case alert
    /// 消息： title + image + message + actions
    case information
    /// 输入: message + input + actions
    case input
    /// 网页: webView + closeBtn
    case webpage
}

class IVPopupView: UIView {
    
    typealias Style = IVPopupViewStyle
        
    // MARK: - 
    /// 标题
    @objc lazy var titleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 16)
        $0.textAlignment = .center
        $0.textColor = UIColor(rgb: 0x333333)
        $0.numberOfLines = 0
    }
    
    /// 输入框
    @objc lazy var inputFields: [UITextField] = []

    private func makeInputField() -> UITextField {
        return UITextField().then {
            $0.clearButtonMode = .whileEditing
            $0.leftView = UIView().then{ $0.frame = CGRect(x: 0, y: 0, width: 5, height: 0) }
            $0.leftViewMode = .always
            $0.font = .systemFont(ofSize: 13, weight: .regular)
            $0.layer.borderWidth = 1.0 / UIScreen.main.scale
            $0.layer.borderColor = UIColor.lightGray.cgColor
            $0.layer.cornerRadius = 2.0
            $0.layer.masksToBounds = true
        }
    }
    
    private let checkcontentView = UIView().then {
        $0.backgroundColor = .clear
        $0.layer.cornerRadius = 12
        $0.layer.masksToBounds = true
    }
    
    /// 勾选标题
    @objc lazy var checktitleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 14)
        $0.textAlignment = .left
        $0.textColor = UIColor(rgb: 0x333333)
        $0.numberOfLines = 0
    }
    /// 勾选标题
    @objc lazy var checkButton = UIButton().then {
        let btn:UIButton  = $0
        btn.setImage(#imageLiteral(resourceName: "point_unsel"), for: .normal)
        btn.setImage(#imageLiteral(resourceName: "cell_select"), for: .selected)
        btn.addEvent(action: { (obc) in
            btn.isSelected = !btn.isSelected
            UserDefaults.standard.set(btn.isSelected, forKey: "surpportProtectionPlanTip")
        
        })
       
    }
    /// 图片
    @objc lazy var imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    /// 正文
    @objc lazy var messageLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        $0.textAlignment = .center
        $0.textColor = UIColor(rgb: 0x333333)
        $0.numberOfLines = 0
    }
    
    /// 网页
    @objc lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.userContentController.add(self, name: "jsCallOC")
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = preferences
        
        let webView = WKWebView(frame: UIScreen.main.bounds, configuration: config)
        webView.isOpaque = false
        webView.navigationDelegate = self
        
        return webView
    }()
    
    /// 交互按钮
    @objc lazy var actions: [IVPopupAction] = []

    @objc var cancelBtn: IVPopupAction? {
        return actions.first(where: { $0.style == .cancel })
    }
    
    @objc var defaultBtn: IVPopupAction? {
        return actions.first(where: { $0.style == .default })
    }
    
    @objc var destructiveBtn: IVPopupAction? {
        return actions.first(where: { $0.style == .destructive })
    }
    
    /// 整体使用垂直布局
    private let stackViewV = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 20
    }
    
    /// 按钮使用水平布局
    private let stackViewH = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 0.5
        $0.distribution = .fillEqually
    }
    
    private let contentView = UIView().then {
        $0.backgroundColor = UIColor(white: 0.8, alpha: 1)
        $0.layer.cornerRadius = 12
        $0.layer.masksToBounds = true
    }
    
    private let topContainer = UIView().then {
        $0.backgroundColor = .white
    }
    
    // MARK: - 生命周期
    @objc convenience init(title: String = "", message: String = "", input placeholder: [String]? = nil, actions: [IVPopupAction] = [.confirm()]) {
        self.init(title: title, message: message, input: placeholder, image: nil, url: nil, checkString: nil, actions: actions)
    }
    
    @objc init(title: String = "", message: String = "", input placeholder: [String]? = nil, image: UIImage? = nil, url: URL? = nil, checkString: String? = nil, actions: [IVPopupAction] = [.confirm()]) {
        super.init(frame: .zero)
        
        backgroundColor = UIColor(white: 0, alpha: 0.3)
        
        NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification, object: nil, queue: nil) { [weak self](noti) in
            guard let `self` = self else { return }
            let value = noti.userInfo?[UIApplication.statusBarOrientationUserInfoKey] as! Int
            if let orientation = UIInterfaceOrientation(rawValue: value) {
                self.layoutUI(orientation)
            }
        }
                
        if !title.isEmpty {
            titleLabel.text = title
            stackViewV.addArrangedSubview(titleLabel)
        }
        
        placeholder?.forEach({ (pl) in
            let inField = makeInputField()
            inField.delegate = self
            inField.placeholder = pl
            inputFields.append(inField)
            stackViewV.addArrangedSubview(inField)
            inField.snp.makeConstraints { make in
                make.height.equalTo(40)
            }
        })
                
        if let image = image {
            imageView.image = image
            stackViewV.addArrangedSubview(imageView)
        }

        if !message.isEmpty {
            if !title.isEmpty {
                messageLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            } else {
                messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            }
            messageLabel.text = message
            stackViewV.addArrangedSubview(messageLabel)
        }
        if let checkString = checkString{
            checktitleLabel.text = checkString
            stackViewV.addArrangedSubview(self.checkcontentView)
            checkcontentView.snp.makeConstraints { make in
                make.height.equalTo(35)
            }
            checkcontentView.addSubview(checkButton)
            checkcontentView.addSubview(checktitleLabel)
            checkButton.snp.makeConstraints { (make) in
                make.width.height.equalTo(20)
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(8)
            }
            checktitleLabel.snp.makeConstraints { (make) in
                make.top.bottom.right.equalToSuperview()
                make.left.equalTo(checkButton.snp.right)
            }
        }
        if let url = url {
            webView.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10));
            addSubview(webView)
            self.alpha = 0
            logDebug(url)
            webView.snp.makeConstraints { make in
                make.top.left.bottom.right.equalTo(self)
            }
        }
        
        actions.forEach { (action) in
            let oriHandler = action.handler
            action.owner = self
            action.handler = { [weak self](owner) in
                self?.dismiss { oriHandler?(owner) }
            }
            self.actions.append(action)
            stackViewH.addArrangedSubview(action)
        }
        
        // self: { contentView:{ topContainer:{ stackViewV }, stackViewH } }, 以下顺序不能变动
        if stackViewV.subviews.count > 0 { topContainer.addSubview(stackViewV) }
        if stackViewH.subviews.count > 0 { contentView.addSubview(stackViewH) }
        if topContainer.subviews.count > 0 { contentView.addSubview(topContainer) }
        if contentView.subviews.count > 0 { addSubview(contentView) }

        layoutUI(UIApplication.shared.statusBarOrientation)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logVerbose()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 公开方法
    @available(swift 10)
    @objc func show() {
        show(in: UIApplication.shared.windows.first)
    }
    
    @objc func show(in view: UIView? = nil) {
        DispatchQueue.main.async {
            let view = view ?? UIApplication.shared.windows.first ?? AppDelegate.shared.window!
            view.addSubview(self)
            self.snp.makeConstraints { (make) in
                make.top.left.bottom.right.equalTo(view)
            }
            self.transfromAnimation(true)
        }
    }

    @objc func dismiss(_ completion: (() -> Void)? = nil) {
        transfromAnimation(false) { [weak self] _ in
            self?.removeFromSuperview()
            completion?()
        }
    }
    
    // MARK: - 私有方法
    
    private func transfromAnimation(_ show: Bool, completion: ((Bool) -> Void)? = nil) {
        if show {
            self.contentView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.contentView.alpha = 0
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: [.curveEaseOut], animations: {
                self.contentView.transform = CGAffineTransform.identity
                self.contentView.alpha = 1
            }, completion: completion)

        } else {
            UIView.animate(withDuration: 0.1, animations: {
                self.contentView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.contentView.alpha = 0
            }, completion: completion)
        }
    }

    private func layoutUI(_ orientation: UIInterfaceOrientation) {
        if let _ = contentView.superview {
            contentView.snp.remakeConstraints { make in
                make.width.equalTo(self).multipliedBy(orientation.isPortrait ? 0.8 : 0.5)
                make.center.equalTo(self)
            }
        }
        
        if let _ = topContainer.superview {
            topContainer.snp.remakeConstraints { make in
                make.top.left.right.equalTo(contentView)
                make.bottom.equalTo(stackViewH.snp.top).offset(-0.5)
            }
        }
        
        if let _ = stackViewV.superview {
            stackViewV.snp.remakeConstraints { make in
                make.top.left.equalTo(topContainer).offset(20)
                make.center.equalTo(topContainer)
            }
        }

        if let _ = stackViewH.superview {
            stackViewH.snp.remakeConstraints { make in
                make.bottom.left.right.equalTo(contentView)
                make.height.equalTo(50)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}

private extension IVPopupView {
    func dictFromScriptMessage(_ message: WKScriptMessage) -> [AnyHashable : Any]? {
        if let dict = message.body as? [AnyHashable : Any] {
            return dict
        } else if let data = message.body as? Data {
            return try? JSONSerialization.jsonObject(with: data) as? [AnyHashable : Any]
        } else if let json = message.body as? String,
            let data = json.data(using: .utf8) {
            return try? JSONSerialization.jsonObject(with: data) as? [AnyHashable : Any]
        }
        return nil
    }
    
}

extension IVPopupView: UITextFieldDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    
    // MARK:-WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        logDebug(webView, navigation as Any)
        //页面开始加载，可在这里给用户loading提示
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        logDebug(webView, navigation as Any)
        //内容开始到达时
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        logDebug(webView, navigation as Any)
        //页面加载完成时
        self.alpha = 1
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logDebug(webView, navigation as Any, error)
        //页面加载出错，可在这里给用户错误提示
        self.removeFromSuperview()
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        logDebug(webView, navigation as Any)
        //收到服务器重定向请求
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        logDebug(webView, navigationAction)
        // 在请求开始加载之前调用，决定是否跳转
        guard let url = navigationAction.request.url else { return }
        
        if url.absoluteString.contains("apps.apple.com") == true {
            UIApplication.shared.openURL(url)
            decisionHandler(WKNavigationActionPolicy.cancel)
        } else if url.absoluteString.hasPrefix("http") == true {
            decisionHandler(WKNavigationActionPolicy.allow)
        } else {
            UIApplication.shared.openURL(url)
            decisionHandler(WKNavigationActionPolicy.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        logDebug(webView, navigationResponse)
        //在收到响应开始加载后，决定是否跳转
        decisionHandler(WKNavigationResponsePolicy.allow)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        logDebug(webView, challenge)
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        }
    }

    
    // MARK:-WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        logDebug(userContentController, message)
        //h5给端传值的内容，可在这里实现h5与原生的交互时间
        guard let dict = dictFromScriptMessage(message) else { return }
        logDebug(dict)
      }
}

extension IVPopupAction {
    @objc static func cancel(_ handler: ((IVPopupView)->Void)? = nil) -> IVPopupAction {
        return IVPopupAction(title: "取消", style: .cancel, handler: handler)
    }
    
    @objc static func delete(_ handler: ((IVPopupView)->Void)? = nil) -> IVPopupAction {
        return IVPopupAction(title: "删除", style: .destructive, handler: handler)
    }

    @objc static func confirm(_ handler: ((IVPopupView)->Void)? = nil) -> IVPopupAction {
        return IVPopupAction(title: "确定", style: .default, handler: handler)
    }

    @objc static func iKnow(_ handler: ((IVPopupView)->Void)? = nil) -> IVPopupAction {
        return IVPopupAction(title: "我知道了", style: .default, handler: handler)
    }

    @objc static func tryAgain(_ handler: ((IVPopupView)->Void)? = nil) -> IVPopupAction {
        return IVPopupAction(title: "再试一次", style: .default, handler: handler)
    }

    @objc static func ignor(_ handler: ((IVPopupView)->Void)? = nil) -> IVPopupAction {
        return IVPopupAction(title: "忽略", style: .cancel, handler: handler)
    }

    @objc static func accept(_ handler: ((IVPopupView)->Void)? = nil) -> IVPopupAction {
        return IVPopupAction(title: "接受", style: .default, handler: handler)
    }
}

extension IVPopupView {
    @objc static func passwordWrongAlert(_ actions: [IVPopupAction] = [.iKnow()]) -> IVPopupView {
        let title = "密码错误"
        let message = """
            \("1.如果您是设备主人，可先删除，然后复位重新添加该设备；")\n
            \("2.如果您不是设备主人，可请主人将设备重新分享给您。")
        """
        
        let alert = IVPopupView(title: title, message: message, actions: actions)
        alert.messageLabel.textAlignment = .left
        
        return alert
    }
}
