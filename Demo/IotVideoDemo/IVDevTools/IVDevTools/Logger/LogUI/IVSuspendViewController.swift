//
//  IVSuspendViewController.swift
//  IVLogger
//
//  Created by JonorZhang on 2019/12/25.
//  Copyright © 2019 JonorZhang. All rights reserved.
//

import UIKit

class IVSuspendViewController: UIViewController {
    
    var canceled = false
    var refreshEnable = true
    
    lazy var pinBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 25))
        btn.setTitle("钉住", for: .normal)
        btn.addTarget(self, action: #selector(pinBtnClicked(_:)), for: .touchUpInside)
        buttonCommonSetting(btn)
        return btn
    }()

    lazy var refreshBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: 40, y: 0, width: 35, height: 25))
        btn.setTitle("刷新", for: .normal)
        btn.addTarget(self, action: #selector(refreshBtnClicked(_:)), for: .touchUpInside)
        btn.isSelected = true
        buttonCommonSetting(btn)
        return btn
    }()

    lazy var closeBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: self.view.frame.width - 40, y: 0, width: 35, height: 25))
        btn.setTitle("关闭", for: .normal)
        btn.addTarget(self, action: #selector(closeBtnClicked(_:)), for: .touchUpInside)
        btn.autoresizingMask = [.flexibleLeftMargin]
        buttonCommonSetting(btn)
        return btn
    }()

    private func buttonCommonSetting(_ btn: UIButton) {
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.layer.cornerRadius = 8
        btn.layer.masksToBounds = true
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.white.cgColor
        btn.setTitleColor(.white, for: .normal)
        btn.setTitleColor(.cyan, for: .selected)
    }
    
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.textColor = .white
        textView.font = .systemFont(ofSize: 7)
        textView.backgroundColor = .clear
        textView.isUserInteractionEnabled = false
        textView.layoutManager.allowsNonContiguousLayout = false
        return textView
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("IVSuspendViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(textView)
        view.addSubview(pinBtn)
        view.addSubview(refreshBtn)
        view.addSubview(closeBtn)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        canceled = false
        scheduleRefreshText()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        canceled = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textView.frame = view.bounds
    }
    
    @objc func pinBtnClicked(_ btn: UIButton) {
        btn.isSelected.toggle()
        IVDevToolsAssistant.shared.isPinUp = btn.isSelected
        textView.isUserInteractionEnabled = btn.isSelected
    }

    @objc func refreshBtnClicked(_ btn: UIButton) {
        btn.isSelected.toggle()
        refreshEnable = btn.isSelected
    }

    @objc func closeBtnClicked(_ btn: UIButton) {
        IVDevToolsAssistant.shared.minimize()
    }
        
    func scheduleRefreshText() {
        DispatchQueue.global().async { [weak self] in
            guard let fh = try? FileHandle.init(forReadingFrom: IVFileLogger.shared.currLogFileURL) else {
                print("IVSuspendViewController open forReading failed")
                IVFileLogger.shared.insertText("IVSuspendViewController open forReading failed")
                return
            }
            DispatchQueue.main.async { self?.textView.text = nil }

            let end = fh.seekToEndOfFile()
            fh.seek(toFileOffset: (end > 2000) ? end - 2000 : 0)
            
            print("IVSuspendViewController start refresh \(end) \(fh.offsetInFile)")

            while let `self` = self {
                if self.canceled {
                    print("IVSuspendViewController cancel refresh")
                    break
                }
                
                if self.refreshEnable == true {
                    fflush(stdout)
                    let data = fh.readDataToEndOfFile()
                                                                                
                    DispatchQueue.main.async {
                        if !self.textView.isDragging, data.count > 0 {
                            if let text = self.stringFromData(data) {
                                self.insertText(text)
                            }
                        }
                    }
                }
                
                usleep(useconds_t(1000000 * 0.5))
            }
            fh.closeFile()
            
            print("IVSuspendViewController stop refresh")
        }
    }

    func insertText(_ text: String) {
        DispatchQueue.main.async {
            self.textView.insertText(text)
            let maxTextCount = 40000, delta = 2000
            if (self.textView.text.count > maxTextCount + delta) {
                let offset = self.textView.text.count - delta
                let endRemoveIndex = self.textView.text.index(self.textView.text.startIndex, offsetBy: offset)
                self.textView.text.removeSubrange(self.textView.text.startIndex ..< endRemoveIndex)
            }
            let visiRect = self.textView.caretRect(for: self.textView.endOfDocument)
            self.textView.scrollRectToVisible(visiRect, animated: true)
        }
    }
    
    func stringFromData(_ data: Data) -> String? {
        if let utf8Str = String(data: data, encoding: .utf8) {
            return utf8Str
        }
        
        return String(data: data, encoding: .ascii)
    }
}


