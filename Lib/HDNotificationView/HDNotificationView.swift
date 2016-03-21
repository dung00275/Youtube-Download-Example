//
//  HDNotificationView.swift
//  WeatherProject
//
//  Created by dungvh on 9/17/15.
//  Copyright © 2015 dungvh. All rights reserved.
//

import Foundation
import UIKit

let NOTIFICATION_VIEW_FRAME_HEIGHT:CGFloat = 84
let LABEL_TITLE_FONT_SIZE:CGFloat = 14
let LABEL_MESSAGE_FONT_SIZE:CGFloat = 13

let IMAGE_VIEW_ICON_CORNER_RADIUS:CGFloat = 3
let IMAGE_VIEW_ICON_FRAME = CGRectMake(15, 28, 20, 20)//CGRectMake(15, 8, 20, 20)
let LABEL_TITLE_FRAME = CGRectMake(45, 23, CGRectGetWidth(UIScreen.mainScreen().bounds) - 45, 26)//CGRectMake(45, 3, CGRectGetWidth(UIScreen.mainScreen().bounds) - 45, 26)
let LABEL_MESSAGE_FRAME_HEIGHT:CGFloat = 35
let LABEL_MESSAGE_FRAME = CGRectMake(45, 45, CGRectGetWidth(UIScreen.mainScreen().bounds) - 45, LABEL_MESSAGE_FRAME_HEIGHT)//CGRectMake(45, 25, CGRectGetWidth(UIScreen.mainScreen().bounds) - 45, LABEL_MESSAGE_FRAME_HEIGHT)

let NOTIFICATION_VIEW_SHOWING_DURATION = 3.0
let NOTIFICATION_VIEW_SHOWING_ANIMATION_TIME = 0.3

typealias TouchNotifyBlock = () ->()

class HDNotificationView: UIToolbar {
    var handlerTouch:TouchNotifyBlock?
    var imgIcon:UIImageView!
    var lblTitle:UILabel!
    var lblMessage:UILabel!
    
    var timerHideAuto:NSTimer?
    
    
    init(){
        super.init(frame: CGRectMake(0, 0, CGRectGetWidth(UIScreen.mainScreen().bounds), NOTIFICATION_VIEW_FRAME_HEIGHT))
        
        if !UIDevice.currentDevice().generatesDeviceOrientationNotifications
        {
            UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationStatusDidChange:", name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        self.setupUI()
        
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    struct HDNotificationInstance {
        static let instance = HDNotificationView()
    }
    
    class func sharedInstance() -> HDNotificationView{
        return HDNotificationInstance.instance
    }
    
    func setupUI()
    {
        self.barTintColor = nil
        self.translucent = true
        self.barStyle = UIBarStyle.Black
        
        self.layer.zPosition = CGFloat(FLT_MAX)
        self.backgroundColor = UIColor.clearColor()
        self.multipleTouchEnabled = false
        self.exclusiveTouch = true
        
        self.frame = CGRectMake(0, 0, CGRectGetWidth(UIScreen.mainScreen().bounds), NOTIFICATION_VIEW_FRAME_HEIGHT)
        
        if imgIcon == nil
        {
            imgIcon = UIImageView()
            imgIcon.contentMode = UIViewContentMode.ScaleAspectFill
            imgIcon.layer.cornerRadius = IMAGE_VIEW_ICON_CORNER_RADIUS
            imgIcon.clipsToBounds = true
        }
        
        imgIcon.frame = IMAGE_VIEW_ICON_FRAME
        
        if imgIcon.superview == nil
        {
            self.addSubview(imgIcon)
        }
        
        if lblTitle == nil
        {
            lblTitle = UILabel()
            lblTitle.textColor = UIColor.whiteColor()
            lblTitle.font = UIFont(name: "HelveticaNeue-Bold", size: LABEL_TITLE_FONT_SIZE)!
            lblTitle.numberOfLines = 1
        }
        
        lblTitle.frame = LABEL_TITLE_FRAME
        
        if lblTitle.superview == nil
        {
            self.addSubview(lblTitle)
        }
        
        if lblMessage == nil
        {
            lblMessage = UILabel()
            lblMessage.textColor = UIColor.whiteColor()
            lblMessage.font = UIFont(name: "HelveticaNeue", size: LABEL_MESSAGE_FONT_SIZE)!
            lblMessage.numberOfLines = 2
            lblMessage.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        }
        
        lblMessage.frame = LABEL_MESSAGE_FRAME
        
        if lblMessage.superview == nil
        {
            self.addSubview(lblMessage)
        }
        
        fixLabelMessageSize()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "notificationViewDidTap:")
        self.addGestureRecognizer(tapGesture)
        
    }
    
    deinit{
        print("Dealloc HDNotificationView \n")
    }
    
    
}

// MARK: - Helper
extension HDNotificationView{
    func fixLabelMessageSize()
    {
        let size = lblMessage.sizeThatFits(CGSizeMake(CGRectGetWidth(UIScreen.mainScreen().bounds) - 45, CGFloat.max))
        var frame = lblMessage.frame
        frame.size.height = size.height > LABEL_MESSAGE_FRAME_HEIGHT ? LABEL_MESSAGE_FRAME_HEIGHT : size.height
        lblMessage.frame = frame
    }
}

// MARK: - Orientation
extension HDNotificationView{
    func orientationStatusDidChange(notification:NSNotification)
    {
        self.setupUI()
    }
}


// MARK: - Show
extension HDNotificationView{
    
    func hideNotificationView()
    {
        self.hideNotificationViewOnComplete(nil)
    }
    
    func hideNotificationViewOnComplete(handler:TouchNotifyBlock?)
    {
        UIView.animateWithDuration(
            NOTIFICATION_VIEW_SHOWING_ANIMATION_TIME,
            delay: 0.0,
            options: .CurveEaseOut,
            animations: { [weak self]() -> Void in
                
            if let actualSelf = self
            {
                var frame = actualSelf.frame;
                frame.origin.y -= frame.size.height;
                actualSelf.frame = frame;
            }
            
            }) { [weak self](complete:Bool) -> Void in
                if let actualSelf = self
                {
                    actualSelf.removeFromSuperview()
                    appDelegate.window?.windowLevel = UIWindowLevelNormal
                    actualSelf.timerHideAuto?.invalidate()
                    actualSelf.timerHideAuto = nil
                    
                    handler?()
                }
        }
    }
    
    func notificationViewDidTap(gesture:UIGestureRecognizer)
    {
        handlerTouch?()
    }
    
    func showNotificationViewWithImage(image:UIImage?,title:String,message:String){
        self.showNotificationViewWithImage(image, title: title, message: message, isAutoHide: true, handler: nil)
    }
    
    func showNotificationViewWithImage(image:UIImage?,title:String,message:String,isAutoHide:Bool){
        self.showNotificationViewWithImage(image, title: title, message: message, isAutoHide: isAutoHide, handler: nil)
    }
    
    
    func showNotificationViewWithImage(image:UIImage?,title:String,message:String,isAutoHide:Bool,handler:TouchNotifyBlock?){
        timerHideAuto?.invalidate()
        timerHideAuto = nil
        
        self.handlerTouch = handler
        
        imgIcon.image = image
        
        lblTitle.text = title
        lblMessage.text = message
        
        fixLabelMessageSize()
            
        var frame = self.frame
        frame.origin.y = -frame.size.height
        self.frame = frame
        
        appDelegate.window?.windowLevel = UIWindowLevelNormal
        appDelegate.window?.addSubview(self)
        
        UIView.animateWithDuration(NOTIFICATION_VIEW_SHOWING_ANIMATION_TIME, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut , animations: { [weak self]() -> Void in
            if let actualSelf = self
            {
                var frame = actualSelf.frame;
                frame.origin.y += frame.size.height;
                actualSelf.frame = frame;
            }
            }) { (complete) -> Void in
                
        }
        
        if isAutoHide
        {
            timerHideAuto = NSTimer.scheduledTimerWithTimeInterval(NOTIFICATION_VIEW_SHOWING_DURATION, target: self, selector: "hideNotificationView", userInfo: nil, repeats: false)
        }
    }
    
}


