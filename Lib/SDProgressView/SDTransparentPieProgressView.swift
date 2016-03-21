//
//  SDTransparentPieProgressView.swift
//  500pxPicture
//
//  Created by dungvh on 8/14/15.
//  Copyright (c) 2015 dungvh. All rights reserved.
//

import Foundation
import UIKit

class SDTransparentPieProgressView: SDBaseProgressView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.grayColor()//UIColor.clearColor()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        guard let ctx:CGContextRef = UIGraphicsGetCurrentContext() else{
            return
        }
        
        let xCenter:CGFloat = CGRectGetWidth(rect) * 0.5
        let yCenter:CGFloat = CGRectGetHeight(rect) * 0.5
        
        let radius = min(xCenter, yCenter) - SDProgressViewItemMargin
        ColorHelper.SDProgressViewBackgroundColor.set()
        let lineW:CGFloat = max(xCenter, yCenter)
        
        CGContextSetLineWidth(ctx, lineW)
        CGContextAddArc(ctx, xCenter, yCenter, radius + lineW * 0.5 + 5, 0.0, CGFloat(M_PI * 2.0), 1)
        CGContextStrokePath(ctx)
        
        
        CGContextSetLineWidth(ctx, 1)
        CGContextMoveToPoint(ctx, xCenter, yCenter)
        CGContextAddLineToPoint(ctx, xCenter, 0)
        let to:CGFloat = CGFloat(-M_PI * 0.5) + self.progress * CGFloat(M_PI * 2) + 0.001
        
        CGContextAddArc(ctx, xCenter, yCenter, radius, CGFloat(-M_PI * 0.5), to, 1)
        CGContextClosePath(ctx)
        CGContextFillPath(ctx)
        
    }
}