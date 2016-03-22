//
//  SCSkypeActivityIndicatorView.swift
//  WeatherProject
//
//  Created by dungvh on 9/10/15.
//  Copyright (c) 2015 dungvh. All rights reserved.
//

import Foundation
import UIKit

let kSkypeCurveAnimationKey = "kSkypeCurveAnimationKey"
let kSkypeScaleAnimationKey = "kSkypeScaleAnimationKey"

class SCSkypeActivityIndicatorBubbleView: UIView {
    var color = UIColor.whiteColor()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextClearRect(context, rect)
        CGContextAddEllipseInRect(context, self.bounds)
        CGContextSetFillColorWithColor(context, self.color.CGColor)
        CGContextFillPath(context)
    }
}

class SCSkypeActivityIndicatorView: UIView {
    var numberOfBubbles:Int = 5
    var bubbleColor:UIColor = UIColor.whiteColor()
    var bubbleSize = CGSizeZero
    var animationDuration:NSTimeInterval = 1.5
    var isAnimating = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.commonInit()
    }
    
    deinit{
        print("Dealloc SCSkypeActivityIndicatorView")
    }
    
    func commonInit()
    {
        numberOfBubbles = 5
        bubbleColor = UIColor.whiteColor()
        animationDuration = 1.5
        bubbleSize = CGSizeMake(CGRectGetWidth(self.bounds) / 10, CGRectGetHeight(self.bounds) / 10)
    }
    
    func startAnimating()
    {
        if isAnimating
        {
            return
        }
        isAnimating = true
        
        print("function \(#function)")
        
        for i in 0..<numberOfBubbles{
            let value = 1 / CGFloat(numberOfBubbles)
            let x:CGFloat = CGFloat(i) * value
            let bubbleView = self.bubbleWithTimingFunction(CAMediaTimingFunction(controlPoints: 0.5, 0.1 + Float(x), 0.25, 1), initialScale: 1 - x, finalScale: 0.2 + x)
            bubbleView.alpha = 0
            self.addSubview(bubbleView)
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                bubbleView.alpha = 1
            })
        }
    }
    
    func stopAnimating(completion:((Bool)->())?)
    {
        if !isAnimating
        {
            return
        }
        
        var count = self.subviews.count
        for view in self.subviews
        {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                view.alpha = 0
                }, completion: { (complete) -> Void in
                    view.layer.removeAllAnimations()
                    view.removeFromSuperview()
                    count -= 1
                    if count == 0
                    {
                        completion?(true)
                    }
            })
        }
        
        isAnimating = false
    }
    
    func animationScaleBubbleView(bubbleView:SCSkypeActivityIndicatorBubbleView,initialScale:CGFloat,finalScale:CGFloat,isInit:Bool)
    {
        let minTransform = CATransform3DMakeScale(initialScale,initialScale , 1)
        let maxTransform = CATransform3DMakeScale(finalScale,finalScale , 1)
        
        let transformInit = isInit ? minTransform : maxTransform
        let transformFinal = isInit ? maxTransform : minTransform
        print("isInit : \(isInit ? "true" : "false")")
        
        bubbleView.layer.transform = transformInit
        
        let option:UIViewAnimationOptions = isInit ? .CurveEaseIn : .CurveEaseOut
        UIView.animateWithDuration(
            self.animationDuration,
            delay: 0,
            options: option,
            animations:
        {
             bubbleView.layer.transform = transformFinal
            }) { [weak self](isComplete) in
                self?.animationScaleBubbleView(bubbleView, initialScale: initialScale, finalScale: finalScale,isInit: !isInit)
        }
    }
    
    func bubbleWithTimingFunction(timingFunction:CAMediaTimingFunction,initialScale:CGFloat,finalScale:CGFloat) ->SCSkypeActivityIndicatorBubbleView{
        print("\(#function) , initialScale : \(initialScale) , finalScale : \(finalScale)")
        
        let bubbleView = SCSkypeActivityIndicatorBubbleView(frame: CGRect(origin: CGPointZero, size: bubbleSize))
        bubbleView.color = bubbleColor
        let pi = CGFloat(M_PI)
        let pathAnimation = CAKeyframeAnimation(keyPath: "position")
        pathAnimation.duration = self.animationDuration
        pathAnimation.repeatCount =  Float(CGFloat.max)
        pathAnimation.timingFunction = timingFunction
        pathAnimation.path = UIBezierPath(arcCenter: CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2),
            radius: min(self.bounds.size.width - bubbleView.bounds.size.width, self.bounds.size.height - bubbleView.bounds.size.height)/3,
            startAngle: 3 * pi / 2,
            endAngle: 3 * pi / 2 + 2 * pi,
            clockwise: true).CGPath
        
        bubbleView.layer.addAnimation(pathAnimation, forKey: kSkypeCurveAnimationKey)
        
//        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
//        scaleAnimation.duration = self.animationDuration
//        pathAnimation.repeatCount =  Float(CGFloat.max)
//        scaleAnimation.fromValue = initialScale
//        scaleAnimation.toValue = finalScale
//        
//        if initialScale > finalScale
//        {
//            scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
//        }else
//        {
//            scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
//        }
//        
//         bubbleView.layer.addAnimation(scaleAnimation, forKey: kSkypeScaleAnimationKey)
        self.animationScaleBubbleView(bubbleView, initialScale: initialScale, finalScale: finalScale,isInit:true)
        
        
        return bubbleView
    }
    
}