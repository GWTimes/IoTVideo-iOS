//
//  FileLogTextViewController.swift
//  IVLogger
//
//  Created by JonorZhang on 2019/8/21.
//  Copyright © 2019 JonorZhang. All rights reserved.
//

import UIKit

class IVFileLogTextViewController: UIViewController, IVFileLoggerDelegate {
    
    // MARK: - UI控件

    @IBOutlet weak var regExpBtn: UIButton!
    
    @IBOutlet weak var caseSensitiveBtn: UIButton!
    
    @IBOutlet weak var wholeWordBtn: UIButton!
    
    @IBOutlet weak var searchBar: UITextField!
    
    @IBOutlet weak var filterBtn: UIButton!
    
    @IBOutlet weak var moreSettingBtn: UIButton!
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var symbolCollView: UICollectionView!
    
    @IBOutlet weak var toolbarView: UIStackView!
    
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var moreSettingPanel: UIView!
    
    @IBOutlet weak var fontSizeSlider: UISlider!
    
    @IBOutlet weak var searchResultView: UIView!
    
    @IBOutlet weak var resultCountLabel: UILabel!
    
    @IBOutlet weak var tipsMessageLabel: UILabel!
    
    @IBOutlet weak var autoScrollSwitch: UISwitch!
    
    @IBOutlet weak var logLevelSlider: UISlider!
    
    // MARK: - 其他变量

    private let kFontSizeKey = "key.FontSize.IVFileLogTextViewController"
    private let kAutoScrollKey = "key.AutoScroll.IVFileLogTextViewController"

    private let regExpSymbols = [".", "*", "?", "^", "$", "-", "+", ",", "{", "}", "[", "]", "(", ")", ":", "\\", "/", "<", ">"]

    var content: LogContent!

    var textCount: Int = 0
    
    // 该表达式非nil时，控制器只显示筛选搜索结果
    var regExp: NSRegularExpression?
    
    private var matcheResults: (curIdx: Int, all: [NSTextCheckingResult]?) = (0, nil) {
        didSet {
            guard let resultAll = matcheResults.all, resultAll.count > 0 else { return }
            // 1. 如果是prev/next进来需要还原当前文本为未选中颜色
            if let oldResultAll = oldValue.all, oldResultAll == resultAll {
                textView.textStorage.addAttributes([.backgroundColor : UIColor.yellow], range: oldResultAll[oldValue.curIdx].range)
            }
            
            // 2. 更新prev/next文本为选中颜色
            let range = resultAll[matcheResults.curIdx].range
            resultCountLabel.text = "\(matcheResults.curIdx + 1)/\(resultAll.count)"
            textView.scrollRangeToVisible(range)
            textView.textStorage.addAttributes([.backgroundColor : UIColor.red], range: range)
        }
    }
    
    // MARK: - 生命周期
        
    override func viewDidLoad() {
        super.viewDidLoad()
        if case .url(let url)? = content, IVFileLogger.shared.currLogFileURL == url {
            navigationItem.rightBarButtonItems = [
                UIBarButtonItem(title: "分享", style: .plain, target: self, action: #selector(sharing)),
                UIBarButtonItem(title: "悬浮", style: .plain, target: self, action: #selector(suspend))
            ]
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "分享", style: .plain, target: self, action: #selector(sharing))
        }
        setupTextView(content)
        searchBar.delegate = self
        
        symbolCollView.register(IVSymbolCollViewCell.self, forCellWithReuseIdentifier: "IVSymbolCollViewCell")
        symbolCollView.collectionViewLayout = IVSymbolCollViewLayout()
        logLevelSlider.value = Float(IVLogSettingViewController.logLevel.rawValue)

        observeKeyboard()
    }

    func stringFromData(_ data: Data) -> String? {
        if let utf8Str = String(data: data, encoding: .utf8) {
            return utf8Str
        }
        
        return String(data: data, encoding: .ascii)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if case .url(let url)? = content {
            toggleTipsMessage("努力加载中...🏃🏿‍♂️", show: true)
            DispatchQueue.global().async { [weak self] in
                guard let data = IVFileLogger.shared.readLogFile(url),
                    let text = self?.stringFromData(data) else {
                        self?.toggleTipsMessage("IVFileLogTextViewController内容错误 url:\(url)", show: true)
                        return
                }
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    IVFileLogger.shared.delegate = self

                    self.toggleTipsMessage(show: false)
                    self.textView.text = text
                    self.textCount = text.count
                    self.scrollToBottomIfNeed(true)
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print(#function, self.classForCoder)
    }

    // MARK: - 私有函数
    
    @objc func suspend() {
        navigationController?.popToRootViewController(animated: false)
        IVDevToolsAssistant.shared.suspend(content: content)
    }
    
    @objc func sharing() {
        var activityItems: [Any] = []
        switch content {
        case .url(let logFileUrl)?:
            activityItems.append(logFileUrl)
        case .text(let logText)?:
            activityItems.append(logText)
        case .none:
            break
        }
        let actVc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        self.present(actVc, animated: true)
    }
    
    private func toggleTipsMessage(_ message: String = "", show: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.tipsMessageLabel.superview?.isHidden = !show
            self?.tipsMessageLabel.text = message
        }
    }
    
    private func setupTextView(_ content: LogContent) {
        textView.isEditable = false
        textView.textColor = .black
        if case .text(let text) = content {
            textView.text = text
            textCount = text.count
            if let regExp = regExp {
                searchBar.text = regExp.pattern
                search(in: text, regExp: regExp)
            }
            scrollToBottomIfNeed(true)
        }
        if let fontSize = UserDefaults.standard.value(forKey: kFontSizeKey) as? CGFloat {
            textView.font = .systemFont(ofSize: fontSize)
            fontSizeSlider.value = Float(fontSize)
        }
        
        if let isAutoScroll = UserDefaults.standard.value(forKey: kAutoScrollKey) as? Bool {
            autoScrollSwitch.isOn = isAutoScroll
        } else {
            autoScrollSwitch.isOn = true
        }
    }
    
    func fileLogger(_ logger: IVFileLogger, didInsert text: String) {
        if case .url(let url)? = content, logger.currLogFileURL == url {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.textView?.insertText(text)
                self.textCount += text.count
                self.scrollToBottomIfNeed()
            }
        }
    }

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(forName: UIApplication.keyboardWillShowNotification, object: nil, queue: nil) { [weak self](note) in
            print("keyboardWillShowNotification ")
            guard let `self` = self else { return }
            if let endFrame = note.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect {
                let dy = endFrame.origin.y - self.toolbarView.frame.origin.y - self.toolbarView.frame.size.height
                self.toolbarBottomConstraint.constant += dy
                self.view.layoutIfNeeded()
                self.scrollToBottomIfNeed()
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.keyboardWillHideNotification, object: nil, queue: nil) { [weak self](note) in
            print("keyboardWillHideNotification ")
            guard let `self` = self else { return }
            self.toolbarBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    private func makeToast(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: {
            alert.dismiss(animated: true)
        })
    }
    
    private func search(in string: String, regExp: NSRegularExpression) {
        self.toggleTipsMessage("正在搜索......🔍", show: true)
        DispatchQueue.global().async {
            let date = Date()
            print("search+ 1", Date().timeIntervalSince(date))
            let strRange = NSRange(location: 0, length: self.textCount)
            print("search+ 2", Date().timeIntervalSince(date))
            let results = regExp.matches(in: string, options: .reportCompletion, range: strRange)
            print("search+ 3", Date().timeIntervalSince(date))
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.textView.textStorage.removeAttribute(.backgroundColor, range: strRange)
                print("search+ 4", Date().timeIntervalSince(date))
                results.forEach({ (res) in
                    self.textView.textStorage.addAttributes([.backgroundColor : UIColor.yellow], range: res.range)
                })
                print("search+ 5", Date().timeIntervalSince(date))
                self.searchResultView.isHidden = !(results.count > 0)
                self.view.bringSubviewToFront(self.searchResultView)
                self.toggleTipsMessage(show: false)

                if results.count > 0 {
                    self.matcheResults = (0, results)
                    if self.moreSettingBtn.isSelected { self.moreSettingClicked(self.moreSettingBtn) }
                    if self.regExpBtn.isSelected { self.regExpClicked(self.regExpBtn) }
                } else {
                    self.makeToast("无搜索结果")
                }
                print("search+ 6", Date().timeIntervalSince(date))
            }
        }
    }
    
    private func scrollToBottomIfNeed(_ force: Bool = false) {
        if force || self.autoScrollSwitch.isOn {
            DispatchQueue.main.async {
//                let visiRect = self.textView.caretRect(for: self.textView.endOfDocument)
//                self.textView.scrollRectToVisible(visiRect, animated: true)
                self.textView.scrollRangeToVisible(NSRange(location: self.textView.text.count, length: 1))
            }
        }
    }
    
    // MARK: - 按键处理

    @IBAction func logLevelChanged(_ sender: UISlider) {
        sender.value = Float(Int(sender.value + 0.5) > Int(sender.value) ? Int(sender.value + 0.5) : Int(sender.value))
        IVLogSettingViewController.logLevel = Level(rawValue: Int(sender.value))!
    }
    
    @IBAction func regExpClicked(_ sender: UIButton) {
        print(#function)
        sender.isSelected = !sender.isSelected
        symbolCollView.isHidden = !sender.isSelected
        view.bringSubviewToFront(symbolCollView)
    }
    
    @IBAction func caseSensitiveClicked(_ sender: UIButton) {
        print(#function)
        sender.isSelected = !sender.isSelected
        self.scrollToBottomIfNeed()
    }
    
    @IBAction func wholeWordClicked(_ sender: UIButton) {
        print(#function)
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func filterClicked(_ sender: UIButton) {
        print(#function)
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func moreSettingClicked(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let sx: CGFloat = 0.5, sy: CGFloat = 0.3
        let tx = moreSettingPanel.frame.size.width * (1.0 - sx) / 2.0
        let ty = moreSettingPanel.frame.size.height * (1.0 - sy) / 2.0
        moreSettingPanel.transform = CGAffineTransform(a: sx, b: 0, c: 0, d: sy, tx: tx, ty: ty)
        view.bringSubviewToFront(moreSettingPanel)
        UIView.animate(withDuration: 0.2) {
            self.moreSettingPanel.isHidden = !sender.isSelected
            self.moreSettingPanel.transform = .identity
        }
    }
    
    @IBAction func fontSizeValueChanged(_ sender: UISlider) {
        UserDefaults.standard.set(sender.value, forKey: kFontSizeKey)
        textView.font = .systemFont(ofSize: CGFloat(sender.value))
    }
    
    @IBAction func prevSearchResultClicked(_ sender: Any) {
        guard let resultAll = matcheResults.all else { return }
        if matcheResults.curIdx > 0 {
            matcheResults.curIdx -= 1
        } else {
            matcheResults.curIdx = resultAll.count - 1
            makeToast("最后一个")
        }
    }
    
    @IBAction func nextSearchResultClicked(_ sender: Any) {
        guard let resultAll = matcheResults.all else { return }
        if matcheResults.curIdx < resultAll.count - 1 {
            matcheResults.curIdx += 1
        } else {
            matcheResults.curIdx = 0
            makeToast("第一个")
        }
    }
    
    @IBAction func showSearchResultsClicked(_ sender: Any) {
        if let regExp = matcheResults.all?.first?.regularExpression {
            let date = Date()
            print("search+0 \(Date().timeIntervalSince(date))")

            if self.regExp?.pattern == regExp.pattern { return }
            
            let linePattern = #"^.*\#(regExp.pattern).*\n"#
            if let lineRegExp = try? NSRegularExpression(pattern: linePattern, options: regExp.options) {
                
                print("search+1 \(Date().timeIntervalSince(date))")

                let strRange = NSRange(location: 0, length: self.textCount)

                print("search+2 \(Date().timeIntervalSince(date))")
                let results = lineRegExp.matches(in: textView.text, options: .reportCompletion, range: strRange)
                print("search+3 \(Date().timeIntervalSince(date))")

                var matchsLines: String = ""
                results.forEach({ (res) in
                    if let range = Range<String.Index>(res.range, in: textView.text) {
                        matchsLines += textView.text[range]
                    }
                })
                print("search+4 \(Date().timeIntervalSince(date))")

                let logTextVc = storyboard?.instantiateViewController(withIdentifier: "IVFileLogTextViewController") as! IVFileLogTextViewController
                logTextVc.content = .text(matchsLines)
                logTextVc.title = linePattern
                logTextVc.regExp = regExp
                navigationController?.pushViewController(logTextVc, animated: true)
                print("search+5 \(Date().timeIntervalSince(date))")

            } else {
                makeToast("正则表达式不正确")
            }
        }
    }
    
    @IBAction func toggleSearchResultViewClicked() {
        searchResultView.isHidden = !searchResultView.isHidden
        view.bringSubviewToFront(searchResultView)
        if let string = self.textView.text, searchResultView.isHidden {
            let strRange = NSRange(location: 0, length: string.count)
            self.textView.textStorage.removeAttribute(.backgroundColor, range: strRange)
        }
    }
    
    @IBAction func autoScrollValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: kAutoScrollKey)
    }
}

extension IVFileLogTextViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return regExpSymbols.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IVSymbolCollViewCell", for: indexPath) as! IVSymbolCollViewCell
        cell.textLabel.text = regExpSymbols[indexPath.item]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        searchBar.insertText(regExpSymbols[indexPath.item])
    }
}

extension IVFileLogTextViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchBar.resignFirstResponder()
        if let string = textView.text, var pattern = searchBar.text, pattern.count > 0 {
            var options: NSRegularExpression.Options = [.anchorsMatchLines]
            if !caseSensitiveBtn.isSelected { options.insert(.caseInsensitive) }
            if wholeWordBtn.isSelected { pattern = #"\b\#(pattern)\b"# }
            if let regExp = try? NSRegularExpression(pattern: pattern, options: options) {
                search(in: string, regExp: regExp)
            } else {
                makeToast("正则表达式不正确")
            }
        }
        return true
    }
}

fileprivate class IVSymbolCollViewCell: UICollectionViewCell {
    
    lazy var textLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = #colorLiteral(red: 0.2389338315, green: 0.4465256333, blue: 1, alpha: 1)
        lb.backgroundColor = #colorLiteral(red: 0.8558645442, green: 0.8643384506, blue: 0.8643384506, alpha: 1)
        lb.layer.cornerRadius = 10
        lb.layer.masksToBounds = true
        lb.font = UIFont.systemFont(ofSize: 23)
        lb.textAlignment = .center
        return lb
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(textLabel)
        textLabel.frame = contentView.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class IVSymbolCollViewLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        minimumLineSpacing = 1
        minimumInteritemSpacing = 1
        itemSize = CGSize(width: 40, height: 40)
        estimatedItemSize = CGSize(width: 40, height: 40)
        scrollDirection = .horizontal
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

