//
//  ActionViewController.swift
//  YouTubeShareExt
//
//  Created by dungvh on 1/18/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import UIKit
import MobileCoreServices
import SafariServices

var manager:Manager?
class ActionViewController: UIViewController {

    @IBOutlet weak var lblClass: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var btnDownLoad: UIButton!
    var url:NSURL?
    override func viewDidLoad() {
        super.viewDidLoad()
        print("class :\(self.parentViewController?.presentedViewController.dynamicType)")
        print("path :\(NSBundle.mainBundle().bundlePath)")
//        do{
//            let app = try self.sharedApplication(self.parentViewController)
//            
//            self.trySendLocalNotification(app)
//            
//            
//        }catch let error as NSError{
//            print(error.description)
//        }
        
        
        var urlFound = false
        for item: AnyObject in self.extensionContext!.inputItems {
            let inputItem = item as! NSExtensionItem
            for provider: AnyObject in inputItem.attachments! {
                let itemProvider = provider as! NSItemProvider
                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String){
                    itemProvider.loadItemForTypeIdentifier(kUTTypeURL as String, options: nil, completionHandler: { [weak self](item, error) -> Void in
                        if let url = item as? NSURL{
                            self?.url = url
                            self?.textField.text = url.absoluteString
                            urlFound = true
                        }
                    })
                    break
                }
            }
            
            if (urlFound) {
                // We only handle one image, so stop looking for more.
                break
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let key = "ControllerInApp"
        self.lblClass.text = getObjInAppGroup(key) != nil ? "InApp" : "OutApp"
        removeKeyInAppGroups(key)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit{
        print("Deinit ActionViewController \n")
    }
    
    private func prepareDownload(){
        guard let path = self.textField.text , url = NSURL(string: path) else{
            self.btnDownLoad.enabled = true
            return
        }
        LoadingView.showInView(self.view)
        Youtube.h264videosWithYoutubeURL(url) { [weak self](videoInfo, error) -> Void in
            print("video info : \(videoInfo) \n")
            
            guard let actualSelf = self else{
                return
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                LoadingView.hideInView(actualSelf.view)
            })
            
            guard let info = videoInfo where error == nil else{
                actualSelf.showAlert("No Infomation Found !!!", message: "Please try with other video!!!!")
                actualSelf.btnDownLoad.enabled = true
                
                return
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                actualSelf.downloadItem(info)
            })
            
        }
    }
    
    func addViewProgress()
    {
        let progessView = SDTransparentPieProgressView(frame: CGRectMake(50, 80, 100, 100))
        progessView.tag = 568
        progessView.center = self.view.center
        progessView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(progessView)
        
        let centerX = NSLayoutConstraint(item: progessView, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: progessView, attribute: .CenterY, relatedBy: .Equal, toItem: self.view, attribute: .CenterY, multiplier: 1, constant: 0)
        let width = NSLayoutConstraint(item: progessView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1, constant: 100)
        let height = NSLayoutConstraint(item: progessView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: 100)
        
        self.view.addConstraints([centerX,centerY,width,height])
    }
    
    func progressSimulation(progerss:CGFloat)
    {
        if let viewProgress = self.view.viewWithTag(568) as? SDTransparentPieProgressView
        {
            viewProgress.progress = progerss
        }
    }
    
    func downloadItem(info:[String: AnyObject]){
       
        guard let path = info["url"] as? String else{
            self.showAlert("Error!!!", message: "Not Have Url To Download")
            self.btnDownLoad.enabled = true
            return
        }
        
        let title = (info["title"] as? String)?.stringByRemovingPercentEncoding ?? "NoName"
        setKeyToAppGroup(title, key: "kTitle")
        guard let urlScheme = NSURL(string: "downloader://?link=\(path)") else{
            self.showAlert("Error!!!", message: "It's Seem Something Wrong With Link!!!!")
            return
        }
        
        defer{
            self.done()
        }
        
        
        do{
            let app = try self.sharedApplication(self.parentViewController)
            
            app.performSelector("openURL:", withObject: urlScheme)
            
        }catch let error as NSError{
            print(error.description)
        }

        
//        guard let path = info["url"] as? String , url = NSURL(string: path) , urlDownload = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.dungvh.youTubeExtension") else{
//            self.showAlert("Error!!!", message: "Not Have Url To Download")
//            self.btnDownLoad.enabled = true
//            return
//        }
        
//        self.extensionContext?.openURL(urlScheme, completionHandler: { [weak self](isComplete) -> Void in
//            self?.done()
//        })
        
//        self.addViewProgress()
//        let title = info["title"] as? String ?? "No name"
//        let downloadOp = OperationDownload(identifier: "group.dungvh.youTubeExtension", titleFile: title, urlRequest: url, pathSaveFile: urlDownload, receivedBlock: { [weak self](bytesWritten, totalBytesWritten) -> () in
//            print("Process : \(CGFloat(bytesWritten) / CGFloat(totalBytesWritten)) \n")
//                self?.progressSimulation(CGFloat(bytesWritten) / CGFloat(totalBytesWritten))
//                if bytesWritten == totalBytesWritten
//                {
//                    self?.btnDownLoad.enabled = true
//                    self?.showAlert("Download Completed", message: "Please Check In YouTubeDownloader!!!")
//                    
//                }
//            }) { (error:NSError?) -> () in
//                print(error?.description)
//        }
//        
//        let pushOp = PushOperation(fileName: title)
//        pushOp.addDependency(downloadOp)
//        let opQueue = NSOperationQueue()
//        opQueue.addOperation(downloadOp)
//        opQueue.addOperation(pushOp)
        
        
        
        
//        let time = NSDate().timeIntervalSince1970 % 1000
//        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("youtube.downloading\(time)")
//        configuration.sharedContainerIdentifier = "group.dungvh.youTubeExtension"
//        configuration.shouldUseExtendedBackgroundIdleMode = true
//         manager = Manager(configuration: configuration)
//        let destination: (NSURL, NSHTTPURLResponse) -> (NSURL) = { [weak self](temporaryURL, response) in
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                self?.progressSimulation(1.0)
//            })
//            
//            if let extensionFile = response.suggestedFilename{
//                let name = title.stringByReplacingOccurrencesOfString("/", withString: "")
//                
//                let writePath =  urlDownload.URLByAppendingPathComponent("\(name).\(extensionFile)").path!
//                guard let path = writePath.stringByRemovingPercentEncoding else{
//                    return temporaryURL
//                }
//               
//                let urlSaveFile = NSURL(fileURLWithPath: path)
//                //
//                var channel:String?
//                let userDefaults = NSUserDefaults(suiteName: "group.dungvh.youTubeExtension")
//                if let value = userDefaults?.objectForKey("channels") as? String{
//                    channel = value
//                }
//                
//                if let channel = channel{
//                    Parse.setApplicationId("mGIfH4lP8rv3rheqnMbPj6cuafy4F0qlvtgBf7QM",
//                        clientKey: "nhMAHLMeNMweZv0Y5hyfLMj3hiPmZtIaMTa2dRel")
//                    
//                    PFPush.sendPushMessageToChannelInBackground(channel, withMessage: "File \(name) is downloaded!!!", block: { (isComplete, error) -> Void in
//                        print("Send Push")
//                    })
//                }
//                
//                return urlSaveFile
//            }
//            
//            return temporaryURL
//        }
//        
//        
//        manager?.download(.GET, url, destination: destination).progress({ [weak self](_, totalBytesRead, totalBytesExpectedToRead) -> Void in
//            print("*****Total \(totalBytesExpectedToRead) *****\n")
//            print("Process : \(CGFloat(totalBytesRead) / CGFloat(totalBytesExpectedToRead)) \n")
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                self?.progressSimulation(CGFloat(totalBytesRead) / CGFloat(totalBytesExpectedToRead))
//                if totalBytesRead == totalBytesExpectedToRead
//                {
//                    self?.btnDownLoad.enabled = true
//                    self?.showAlert("Download Completed", message: "Please Check In YouTubeDownloader!!!")
//                    
//                }
//            })
//            
//        })
    }
    
// MARK: - Helper
    func trySendLocalNotification(app:UIApplication){
//        let url = NSURL(string: )
//        
//        self.extensionContext?.openURL(<#T##URL: NSURL##NSURL#>, completionHandler: <#T##((Bool) -> Void)?##((Bool) -> Void)?##(Bool) -> Void#>)
        
       self.done()
        
//        let notify = UILocalNotification()
//        notify.fireDate = NSDate(timeIntervalSinceNow: 3)
//        notify.alertBody = "Test"
//        app.scheduleLocalNotification(notify)
        
    }
    
    func sharedApplication(controller:UIResponder?) throws -> UIApplication {
        var responder: UIResponder? = controller
        while responder != nil {
            if let application = responder as? UIApplication {
                return application
            }
            
            responder = responder?.nextResponder()
        }
        
        throw NSError(domain: "UIInputViewController+sharedApplication.swift", code: 1, userInfo: nil)
    }
    
    func setKeyToAppGroup(obj:AnyObject?,key:String){
        let appGroup = NSUserDefaults(suiteName: "group.dungvh.youTubeExtension")
        appGroup?.setObject(obj, forKey: key)
        appGroup?.synchronize()
    }
    
    func removeKeyInAppGroups(key:String){
        let appGroup = NSUserDefaults(suiteName: "group.dungvh.youTubeExtension")
        appGroup?.removeObjectForKey(key)
        appGroup?.synchronize()
    }
    
    func getObjInAppGroup(key:String) -> AnyObject?
    {
        let appGroup = NSUserDefaults(suiteName: "group.dungvh.youTubeExtension")
        return appGroup?.objectForKey(key)
    }
    
    
    // MARK: - Show Alert
    func showAlert(titleAlert:String?,message:String?){
        let alert = UIAlertController(title: titleAlert, message: message, preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        alert.addAction(action)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Action
    
    @IBAction func done() {
        self.extensionContext!.completeRequestReturningItems(self.extensionContext!.inputItems, completionHandler: nil)
    }

    @IBAction func tapByDownload(sender: UIButton) {
        self.view.endEditing(true)
        if !Reachability.isConnectedToNetwork(){
            showAlert("Network Error!!!", message: "Please Check NetWork!!!!!")
            return
        }
        
        if self.textField.text?.characters.count > 0
        {
            sender.enabled = false
            prepareDownload()
        }else{
            
            showAlert("Notice", message: "No Link Download!!!")
        }
        
    }
}


// MARK: - Create Operation Download And Push
/*
    Step 1:
        - Create operation
        - Session background
        - Callback value

    Step 2:
        - Create operation dependency operation in step 1
        - Push

*/

// Step 1
/* Because it need retain so we use class */

// MARK: --- Download
typealias DownloadErrorBlock = (NSError?)->()
typealias DownloadReceivedBlock = (bytesWritten: Int64,totalBytesWritten: Int64)->()
typealias DownloadCompletedBlock = ()->()

class OperationDownload:NSOperation,NSURLSessionDownloadDelegate{
    
    private var session:NSURLSession!
    private var _finished:Bool = false
    private var _cancelled:Bool = false
    private var _executing:Bool = false
    private var titleFile:String!
    private var pathSaveFile:NSURL!
    private var urlRequest:NSURL!
    private var task:NSURLSessionDownloadTask!
    private var receivedBlock:DownloadReceivedBlock?
    private var errorBlock:DownloadErrorBlock?
    
    override var finished:Bool{
        return _finished
    }
    
    override var executing:Bool{
        return _executing
    }
    
    init(identifier:String,
        titleFile:String,
        urlRequest:NSURL,
        pathSaveFile:NSURL,
        receivedBlock:DownloadReceivedBlock?,
        errorBlock:DownloadErrorBlock?)
    {
        super.init()
        let time = NSDate().timeIntervalSince1970 % 1000
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("youtube.downloading\(time)")
        configuration.sharedContainerIdentifier = identifier
        self.titleFile = titleFile
        self.urlRequest = urlRequest
        self.session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        self.task = self.session.downloadTaskWithURL(urlRequest)
        self.pathSaveFile = pathSaveFile
        self.receivedBlock = receivedBlock
        self.errorBlock = errorBlock
        self.qualityOfService = .Background
    }
    
    override func start() {
        if cancelled {
            finish()
            return
        }
        
        super.start()
        self.task.resume()
        
        willChangeValueForKey("isExecuting")
        willChangeValueForKey("isFinished")
        _executing = true
        _finished = false
        didChangeValueForKey("isExecuting")
        didChangeValueForKey("isFinished")
        
        main()
    }
    
    override func cancel() {
        super.cancel()
        self.task.cancel()
        finish()
    }
    
    func finish(){
        willChangeValueForKey("isExecuting")
        willChangeValueForKey("isFinished")
        _executing = false
        _finished = true
        didChangeValueForKey("isExecuting")
        didChangeValueForKey("isFinished")
    }
    
    
    // MARK: - session delegate
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        self.finish()
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        print(error.debugDescription)
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        self.errorBlock?(error)
        self.cancel()
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        self.finish()
        
        guard let response  = downloadTask.response, extensionFile = response.suggestedFilename ,pathCache = location.path else{
            let error = NSError(domain: "com.download", code: 54554, userInfo: [NSLocalizedDescriptionKey:"Error Download!!"])
            self.errorBlock?(error)
            return
        }
        
        let name = titleFile.stringByReplacingOccurrencesOfString("/", withString: "")
        
        let writePath =  pathSaveFile.URLByAppendingPathComponent("\(name).\(extensionFile)").path!
        guard let path = writePath.stringByRemovingPercentEncoding else{
            let error = NSError(domain: "com.download", code: 54558, userInfo: [NSLocalizedDescriptionKey:"No Path!!"])
            self.errorBlock?(error)
            return
        }
        
        if NSFileManager.defaultManager().fileExistsAtPath(path){
            let error = NSError(domain: "com.download", code: 54534, userInfo: [NSLocalizedDescriptionKey:"File Exists!!!"])
            self.errorBlock?(error)
            self.cancel()
            
            return
        }
        
        do{
            try NSFileManager.defaultManager().moveItemAtPath(pathCache, toPath: path)
            self.completionBlock?()
        }catch let error2 as NSError{
            self.errorBlock?(error2)
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
             self.receivedBlock?(bytesWritten:totalBytesWritten,totalBytesWritten:totalBytesExpectedToWrite)
        }

    }
}

//Step 2:

// MARK: --- Push
class PushOperation:NSOperation{
    private var fileName:String!
    private var _finished:Bool = false
    private var _executing:Bool = false
    
    override var finished:Bool{
        return _finished
    }
    
    override var executing:Bool{
        return _executing
    }
    
    init(fileName:String)
    {
        super.init()
        self.fileName = fileName
    }
    
    override func start() {
        if cancelled{
            finish()
            return
        }
        super.start()
        
        willChangeValueForKey("isExecuting")
        willChangeValueForKey("isFinished")
        _executing = true
        _finished = false
        didChangeValueForKey("isExecuting")
        didChangeValueForKey("isFinished")
        
        var channel:String?
        let userDefaults = NSUserDefaults(suiteName: "group.dungvh.youTubeExtension")
        if let value = userDefaults?.objectForKey("channels") as? String{
            channel = value
        }
        
        if let channel = channel{
            Parse.setApplicationId("mGIfH4lP8rv3rheqnMbPj6cuafy4F0qlvtgBf7QM",
                clientKey: "nhMAHLMeNMweZv0Y5hyfLMj3hiPmZtIaMTa2dRel")
            
            PFPush.sendPushMessageToChannelInBackground(channel, withMessage: "File \(self.fileName) is downloaded!!!", block: { [weak self](isComplete, error) -> Void in
                self?.finish()
            })
        }else{
            self.finish()
        }
    }
    
    func finish(){
        willChangeValueForKey("isExecuting")
        willChangeValueForKey("isFinished")
        _executing = false
        _finished = true
        didChangeValueForKey("isExecuting")
        didChangeValueForKey("isFinished")
    }
    
}







