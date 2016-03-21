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
class TabbarViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate.tabbarViewController = self
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