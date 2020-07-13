//
//  UIButton.swift
//  IotVideoDemoDev
//
//  Created by JonorZhang on 2020/6/10.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit

extension UIButton {
    // MARK: - 状态背景色
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: state)
    }
}

class IVButton: UIButton {
    
    enum ImagePosition {
        case top
        case left
        case bottom
        case right
    }

    var position: ImagePosition {
        didSet { setNeedsLayout() }
    }
    
    var space: CGFloat {
        didSet { setNeedsLayout() }
    }
    
    private var imageSize: CGSize {
        return currentImage?.size ?? .zero
    }

    private var titleSize: CGSize {
        if let titleLabel = subviews.first(where: { $0 is UILabel }) as? UILabel {
            return titleLabel.intrinsicContentSize
        } else {
            let font = UIFont.systemFont(ofSize: UIFont.buttonFontSize)
            return currentTitle?.sizeWithFont(font) ?? .zero
        }
    }

    init(_ position: ImagePosition = .left, space: CGFloat = 0) {
        self.position = position
        self.space = space
        super.init(frame: .zero)
        self.titleLabel?.numberOfLines = 0
    }
       
    required init?(coder aDecoder: NSCoder) {
        self.position = .left
        self.space = 0
        super.init(coder: aDecoder)
        self.titleLabel?.numberOfLines = 0
    }
            
    override func sizeToFit() {
        super.sizeToFit()
        
        let imageFitWidth = contentEdgeInsets.left + imageSize.width + contentEdgeInsets.right
        let titleFitWidth = contentEdgeInsets.left + titleSize.width + contentEdgeInsets.right

        var rect = self.frame
        switch position {
        case .left, .right:
            rect.size.width += space
        case .top, .bottom:
            rect.size.width  = max(imageFitWidth, titleFitWidth)
            rect.size.height = contentEdgeInsets.top + imageSize.height + titleSize.height + contentEdgeInsets.bottom + space
        }
        self.frame = rect
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let imageRect = super.imageRect(forContentRect: contentRect)
        let titleRect = super.titleRect(forContentRect: contentRect)
        if currentTitle == nil {
            return imageRect
        }
        switch position {
        case .top:      return imageRectForImageTop(contentRect, imageRect, titleRect)
        case .left:     return imageRectForImageLeft(contentRect, imageRect, titleRect)
        case .bottom:   return imageRectForImageBottom(contentRect, imageRect, titleRect)
        case .right:    return imageRectForImageRight(contentRect, imageRect, titleRect)
        }
    }

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let titleRect = super.titleRect(forContentRect: contentRect)
        let imageRect = super.imageRect(forContentRect: contentRect)
        if currentImage == nil {
            return titleRect
        }
        switch position {
        case .top:      return titleRectForImageTop(contentRect, imageRect, titleRect)
        case .left:     return titleRectForImageLeft(contentRect, imageRect, titleRect)
        case .bottom:   return titleRectForImageBottom(contentRect, imageRect, titleRect)
        case .right:    return titleRectForImageRight(contentRect, imageRect, titleRect)
        }
    }

    // MARK: - top
   
    private func imageRectForImageTop(_ contentRect: CGRect, _ imageRect: CGRect, _ titleRect: CGRect) -> CGRect {
        return imageRect
    }

    private func titleRectForImageTop(_ contentRect: CGRect, _ imageRect: CGRect, _ titleRect: CGRect) -> CGRect {
        return titleRect
    }
    
    // MARK: - left

    private func imageRectForImageLeft(_ contentRect: CGRect, _ imageRect: CGRect, _ titleRect: CGRect) -> CGRect {
        var newRect = imageRect
        newRect.origin.x -= space/2
        return newRect
    }

    private func titleRectForImageLeft(_ contentRect: CGRect, _ imageRect: CGRect, _ titleRect: CGRect) -> CGRect {
        var newRect = titleRect
        newRect.origin.x += space/2
        return newRect
    }
    
    // MARK: - bottom

    private func imageRectForImageBottom(_ contentRect: CGRect, _ imageRect: CGRect, _ titleRect: CGRect) -> CGRect {
        return imageRect
    }

    private func titleRectForImageBottom(_ contentRect: CGRect, _ imageRect: CGRect, _ titleRect: CGRect) -> CGRect {
        return titleRect
    }

    // MARK: - right

    private func imageRectForImageRight(_ contentRect: CGRect, _ imageRect: CGRect, _ titleRect: CGRect) -> CGRect {
        let imageSafeWidth = contentRect.width - imageEdgeInsets.left - imageEdgeInsets.right
        if imageRect.width >= imageSafeWidth { return imageRect }
        
        var newRect = imageRect
        newRect.origin.x = (contentRect.size.width - imageEdgeInsets.left - imageEdgeInsets.right - (imageRect.width + titleRect.width))/2.0 + titleRect.width + contentEdgeInsets.left + imageEdgeInsets.left + space/2;
        return newRect
    }

    private func titleRectForImageRight(_ contentRect: CGRect, _ imageRect: CGRect, _ titleRect: CGRect) -> CGRect {
        var newRect = titleRect
        newRect.origin.x = (contentRect.width - titleEdgeInsets.left - titleEdgeInsets.right - (imageRect.width + titleRect.width))/2 + contentEdgeInsets.left + titleEdgeInsets.left - space/2
        return newRect
    }

}
