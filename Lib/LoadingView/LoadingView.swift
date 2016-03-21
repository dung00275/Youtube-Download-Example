//
//  LoadingView.swift
//  WeatherProject
//
//  Created by dungvh on 9/10/15.
//  Copyright (c) 2015 dungvh. All rights reserved.
//

import Foundation
import UIKit

let kTagLoadingView = 41275

class LoadingView: UIView {
    
    @IBOutlet weak var containerView: SCSkypeActivityIndicatorView!
    override func awakeFromNib() {
        self.backgroundColor = UIColor.clearColor() //UIColor(white: 0, alpha: 0.1)
        self.containerView.backgroundColor = UIColor(white: 0, alpha: 0.7) //UIColor(red: 9 / 255.0, green: 21 / 255.0, blue: 37 / 255.0, alpha: 1.0)
        self.containerView.layer.cornerRadius = 5.0
        self.containerView.layer.masksToBounds = true
    }
    
    class func showInView(view:UIView){
        if view.viewWithTag(kTagLoadingView) == nil
        {
            let loadingView = NSBundle.mainBundle().loadNibNamed("LoadingView", owner: self, options: nil).first as! LoadingView
            loadingView.frame = view.bounds
            loadingView.tag = kTagLoadingView
            view.addSubview(loadingView)
            
            let topConstraint = NSLayoutConstraint(item: loadingView, attribute:.Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: 0)
            let leftConstraint = NSLayoutConstraint(item: loadingView, attribute:.Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1.0, constant: 0)
            let rightConstraint = NSLayoutConstraint(item: loadingView, attribute:.Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1.0, constant: 0)
            let bottomConstraint = NSLayoutConstraint(item: loadingView, attribute:.Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0)
            
            view.addConstraints([topConstraint,leftConstraint,rightConstraint,bottomConstraint])
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                loadingView.containerView.startAnimating()
            })
            
            
        }
    }
    
    class func hideInView(view:UIView){
        if let loadingView = view.viewWithTag(kTagLoadingView) as? LoadingView{
            loadingView.containerView.stopAnimating({ (complete) -> () in
                loadingView.removeFromSuperview()
            })
            
        }
    }
    
    deinit
    {
        print("Dealloc LoadingView")
    }
}