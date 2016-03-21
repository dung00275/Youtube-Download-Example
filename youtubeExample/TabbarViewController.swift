//
//  TabbarViewController.swift
//  youtubeExample
//
//  Created by dungvh on 1/13/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
let keyURL = "keyURL"

class AnimatedTransition:NSObject,UIViewControllerAnimatedTransitioning{
    
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let vc1 = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let vc2 = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        
        let con = transitionContext.containerView()!
        
        let r1start = transitionContext.initialFrameForViewController(vc1)
        let r2end = transitionContext.finalFrameForViewController(vc2)
        
        let v1 = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let v2 = transitionContext.viewForKey(UITransitionContextToViewKey)!
        
        let tbc = appDelegate.tabbarViewController!
        let ix1 = tbc.viewControllers!.indexOf(vc1)!
        let ix2 = tbc.viewControllers!.indexOf(vc2)!
        
        let dir : CGFloat = ix1 < ix2 ? 1 : -1
        var r1end = r1start
        r1end.origin.x -= r1end.size.width * dir
        var r2start = r2end
        r2start.origin.x += r2start.size.width * dir
        
        v2.frame = r2start
        con.addSubview(v2)
        UIView.animateWithDuration(self.transitionDuration(transitionContext), animations: {
            v1.frame = r1end
            v2.frame = r2end
            }, completion: {
                _ in
                let cancelled = transitionContext.transitionWasCancelled()
                transitionContext.completeTransition(!cancelled)
        })
    }
    
}


class TabbarViewController: UITabBarController {
    
    let transition = AnimatedTransition()
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate.tabbarViewController = self
        self.delegate = self
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    
    deinit{
        
    }
    
    
    func openSafari(){
        let urlPath = getURLFromUSerDefaults() ?? "https://m.youtube.com"
        guard let url = NSURL(string: urlPath) else{
            return
        }
        
        let safariViewController = SFSafariViewController(URL: url)
        safariViewController.delegate = self
        setKeyToAppGroup(true, key: "ControllerInApp")
        self.navigationController?.pushViewController(safariViewController, animated: true)
        
    }
}

extension TabbarViewController:UITabBarControllerDelegate{
    func tabBarController(tabBarController: UITabBarController, animationControllerForTransitionFromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transition
    }
}

extension TabbarViewController:SFSafariViewControllerDelegate{
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func safariViewController(controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        
        print("Loaded!!!!")
        
    }
}

func saveURLToUserDefaults(url:String?){
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setObject(url, forKey: keyURL)
    defaults.synchronize()
}

func getURLFromUSerDefaults() -> String?
{
    let defaults = NSUserDefaults.standardUserDefaults()
    return defaults.objectForKey(keyURL) as? String
}

class ActivityCustom:UIActivity {
    private var title:String?
    private var url:NSURL?
    init(title:String?,url:NSURL?) {
        super.init()
        self.title = title
        self.url = url
    }
    
    
    override func activityTitle() -> String? {
        return title
    }
    
    override func activityType() -> String? {
        return UIActivityTypeMessage
    }
    
    override func activityImage() -> UIImage? {
        return nil
    }
    
    override func performActivity() {
        guard let url = NSURL(string: "mailto:") else {
            return
        }
        
        UIApplication.sharedApplication().openURL(url)
        self.activityDidFinish(true)
    }
}