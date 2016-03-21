//
//  SDBaseProgressView.swift
//  500pxPicture
//
//  Created by dungvh on 8/14/15.
//  Copyright (c) 2015 dungvh. All rights reserved.
//

import Foundation
import UIKit

let SDProgressViewItemMargin:CGFloat = 10

// MARK: - Base Progress View
class SDBaseProgressView: UIView{
    var progress:CGFloat = 0 {
        didSet{
            if progress >= 1.0
            {
                self.removeFromSuperview()
            }else
            {
                self.setNeedsDisplay()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.grayColor()//ColorHelper.SDProgressViewBackgroundColor
        self.layer.cornerRadius = 5
        self.clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setCenterProgressText(text:String,attributes:[String:AnyObject])
    {
        let xCenter:CGFloat = CGRectGetWidth(self.frame) * 0.5
        let yCenter:CGFloat = CGRectGetHeight(self.frame) * 0.5
        
        let strSize = (text as NSString).sizeWithAttributes(attributes)
        let strX = xCenter - strSize.width * 0.5
        let strY = yCenter - strSize.height * 0.5
        
        (text as NSString).drawAtPoint(CGPointMake(strX, strY), withAttributes: attributes)
    }
    
    func dismiss()
    {
        self.progress = 1.0
    }
}

// MARK: - Helper
struct ColorHelper {
    
    func colorMakerWithRGB(r:CGFloat,g:CGFloat,b:CGFloat,alpha:CGFloat) -> UIColor{
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: alpha)
    }
    static let sharedInstance = ColorHelper()
    static let SDProgressViewBackgroundColor:UIColor = sharedInstance.colorMakerWithRGB(240, g: 240, b: 240, alpha: 0.9)
}

extension SDBaseProgressView{
    
    func SDProgressViewFontScale() -> CGFloat
    {
        return min(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)) / 100.0
    }
}

