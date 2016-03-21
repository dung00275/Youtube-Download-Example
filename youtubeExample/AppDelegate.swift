//
//  AppDelegate.swift
//  youtubeExample
//
//  Created by dungvh on 9/24/15.
//  Copyright © 2015 dungvh. All rights reserved.
//

import UIKit

let kSavePath = NSUserDefaults.standardUserDefaults().objectForKey("folderSave")
let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
let kURLDownload = "kURLDownload"
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var applicationState = UIApplicationState.Inactive
    weak var tabbarViewController:TabbarViewController?
    var urlDownload:String?
    var window: UIWindow?
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        applicationState = .Active
        Parse.setApplicationId("mGIfH4lP8rv3rheqnMbPj6cuafy4F0qlvtgBf7QM",
            clientKey: "nhMAHLMeNMweZv0Y5hyfLMj3hiPmZtIaMTa2dRel")
        PFUser.enableAutomaticUser()
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Sound, .Badge], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        application.statusBarStyle = .LightContent
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        return true
    }

    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Fail Register")
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        
        let name = "t_\((deviceToken.base64EncodedStringWithOptions([]) as NSString).substringToIndex(4))"
        let userDefaults = NSUserDefaults(suiteName: "group.dungvh.youTubeExtension")
        userDefaults?.setObject(name, forKey: "channels")
        userDefaults?.synchronize()
        
        let arrChannels = [name]
        installation.channels = arrChannels
        installation.saveInBackground()
        print("Successful Register")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        print("Receive Push!!!!")
        NSNotificationCenter.defaultCenter().postNotificationName("NewFileDownloaded", object: nil, userInfo: nil)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        applicationState = .Inactive
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        applicationState = .Background
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        applicationState = .Active
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        removeKeyInAppGroups("ControllerInApp")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
        guard var path = url.query else{
            return false
        }
        
        path = path.stringByReplacingOccurrencesOfString("link=", withString: "")
        handleDownLoadFromExtension(path)
        
        return true
    }

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        return true
    }
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        DownloaderManager.sharedInstance().savedCompletionHandler = completionHandler
    }
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        guard let fileIdStr = userActivity.userInfo?["kCSSearchableItemActivityIdentifier"] as? String else{
            return true
        }

        guard let tabbarController = self.tabbarViewController  else{
            NSNotificationCenter.defaultCenter().postNotificationName("PlayVideo", object: fileIdStr, userInfo: nil)
            return true
        }
        
        if tabbarController.selectedIndex != 1 {
            tabbarController.selectedIndex = 1
        }
        
        
        guard let naviDownloader =  tabbarController.selectedViewController as? UINavigationController, downloadController =  naviDownloader.visibleViewController as? DownloadedViewController else{
            return true
        }
        if !downloadController.isViewLoaded(){
            downloadController.isOpenBySearch = true
            downloadController.filePathOpenFromSearch = fileIdStr
        }else{
            NSNotificationCenter.defaultCenter().postNotificationName("PlayVideo", object: fileIdStr, userInfo: nil)
        }
        
        return true
    }

}

// MARK: - Open To Download
extension AppDelegate{
    
    func handleDownLoadFromExtension(url:String){
        
        defer{
            applicationState = .Active
        }
        
        guard let tabbar = self.tabbarViewController else{
            self.urlDownload = url
            return
        }
        
        if tabbar.selectedIndex == 1{
            tabbar.selectedIndex = 0
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(kURLDownload, object: url)
        
    }
    
}





// MARK: - Create Folder
func documentFolder() -> String{
    return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String!
}

extension AppDelegate{
    func checkFileExist(path:String) -> Bool{
        return NSFileManager.defaultManager().fileExistsAtPath(path)
    }

    func createFolderDownLoad(){
        
        if let urlDocument = NSURL(string: documentFolder()){
            
            let pathDownload = urlDocument.URLByAppendingPathComponent("Downloads").path!
            
            if !checkFileExist(pathDownload)
            {
                do{
                    //folderSave
                    let _ = try NSFileManager.defaultManager().createDirectoryAtPath(pathDownload, withIntermediateDirectories: false, attributes: nil)
                    NSUserDefaults.standardUserDefaults().setObject(pathDownload, forKey: "folderSave")
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                    
                }catch let error as NSError{
                    print(error.description)
                }
            }
        }
    }
}

