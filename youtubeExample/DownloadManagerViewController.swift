//
//  DownloadManagerViewController.swift
//  youtubeExample
//
//  Created by dungvh on 1/28/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Download Manager
class DownloaderManager:NSObject,NSURLSessionDownloadDelegate {
    
    var savedCompletionHandler: (() -> ())?
    var arrayDownloadItem = [FileDownloadInfo]()
    var session:NSURLSession!
    
    struct DownloaderManagerStatic {
         static let instance = DownloaderManager()
    }
    
    override init() {
        super.init()
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("youtube.downloading")
        configuration.sessionSendsLaunchEvents = true
        configuration.HTTPMaximumConnectionsPerHost = 5
        self.session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
    }
    
    class func sharedInstance() ->DownloaderManager{
        return DownloaderManagerStatic.instance
    }
    
    
    func addDownload(url:NSURL?,fileName:String?) throws{
        
        // Check file if exist
        func checkFileExist(fileName:String) -> Bool{
            if arrayDownloadItem.count == 0 {return false}
            
            let items = arrayDownloadItem.filter {
                return $0.fileName == fileName
            }
            
//            for item in arrayDownloadItem {
//                if item.fileName == fileName{
//                    return true
//                }
//            }
            return items.count > 0
        }
        
        guard let name = fileName else{
            throw NSError(domain: "com.downloadManager", code: 7894, userInfo: [NSLocalizedDescriptionKey:"No File Name!!!"])
        }
        
        guard !checkFileExist(name) else{
            throw NSError(domain: "com.downloadManager", code: 8462, userInfo: [NSLocalizedDescriptionKey:"Link File Download Added !!!!"])
        }
        
        let file = FileDownloadInfo(url: url, fileName: fileName)
        file.session = self.session
        arrayDownloadItem.insert(file, atIndex: 0)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if error == nil{
            
            print("Downloaded Finish One File")
            
        }else{
            print(error?.description)
        }
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        self.session.getTasksWithCompletionHandler { [weak self](_, _, downloadTask) -> Void in
            if downloadTask.count == 0 {
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self?.savedCompletionHandler?()
                    self?.savedCompletionHandler = nil
                    NSNotificationCenter.defaultCenter().postNotificationName("NewFileDownloaded", object: nil, userInfo: nil)
                    let notify = UILocalNotification()
                    notify.alertBody = "All File Downloaded!!!"
                    UIApplication.sharedApplication().presentLocalNotificationNow(notify)
                    showNotificationWithImage("success", title: "Success", message: "All File Downloaded !!!!!!!!")
                })
                
            }
        }
        
    }
    
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        guard let response  = downloadTask.response, extensionFile = response.suggestedFilename ,pathCache = location.path else{
            return
        }
        var itemCurrent:FileDownloadInfo?
        
        for item in arrayDownloadItem where item.taskIdentifier != -1{
            if item.taskIdentifier == downloadTask.taskIdentifier{
                itemCurrent = item
                break
            }
        }
        guard let itemCurrent2 = itemCurrent , urlDownload = NSURL(string: documentFolder()) else{
            return
        }
        let name = itemCurrent2.fileName?.stringByReplacingOccurrencesOfString("/", withString: "") ?? "NoName"
        defer{
            itemCurrent2.isDownloading = false
            itemCurrent2.taskIdentifier = -1
            itemCurrent2.isCompleted = true
            itemCurrent2.currentProgress = 1
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                showNotificationWithImage("success", title: "Success", message: "File \(name) Downloaded !!!!!!!!")
                NSNotificationCenter.defaultCenter().postNotificationName("NewFileDownloaded", object: nil, userInfo: nil)
            })
        }
        
        let writePath =  urlDownload.URLByAppendingPathComponent("\(name).\(extensionFile)").path!
        guard let path = writePath.stringByRemovingPercentEncoding else{
            return
        }
        
        if NSFileManager.defaultManager().fileExistsAtPath(path){
            return
        }
        
        do{
            try NSFileManager.defaultManager().moveItemAtPath(pathCache, toPath: path)
        }catch let error2 as NSError{
            print(error2.description)
        }
    }
}

// MARK: - Tableview Cell
class FileDownloadCell: UITableViewCell {
    
    var deleteDownloadTaskBlock:((FileDownloadCell)->())?
    var startDownloadTaskBlock:((FileDownloadCell)->())?
    
    @IBOutlet weak var lblPercent: UILabel!
    @IBOutlet weak var lblFileName: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var btnPauseDownload: UIButton!
    @IBOutlet weak var btnDelete: UIButton!
    
    weak var fileDownload:FileDownloadInfo?{
        didSet{
            self.lblFileName.text = fileDownload?.fileName
            self.btnPauseDownload.selected = fileDownload?.isDownloading ?? false
            self.progressBar.progress = fileDownload?.currentProgress ?? 0
            self.lblPercent.text = getPercentFromProgress(fileDownload?.currentProgress ?? 0)
        }
    }
    
    @IBAction func tapByDelete(sender: UIButton) {
        fileDownload?.deleteTask()
        self.deleteDownloadTaskBlock?(self)
    }
    
    @IBAction func tapByStartDownload(sender: UIButton) {
        self.startDownloadTaskBlock?(self)
    }
    
    deinit{
        self.startDownloadTaskBlock = nil
        self.deleteDownloadTaskBlock = nil
    }
    
}

// MARK: - File Info
class FileDownloadInfo: NSObject {
    weak var session:NSURLSession?
    var isCompleted:Bool = false
    var isDownloading:Bool = false{
        didSet(newValue){
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.cellOperation?.btnPauseDownload.selected = !newValue
            })
            
        }
    }
    var fileName:String?
    var taskIdentifier:Int = -1
    var currentProgress:Float = 0{
        didSet(newValue){
            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                self?.cellOperation?.progressBar.progress = newValue
                self?.cellOperation?.lblPercent.text = getPercentFromProgress(newValue)
                })
        }
    }
    var downloadTask:NSURLSessionDownloadTask?{
        willSet{
            if let task = self.downloadTask{
                task.removeObserver(self, forKeyPath: "countOfBytesReceived")
                task.removeObserver(self, forKeyPath: "countOfBytesExpectedToReceive")
            }
        }
        
        didSet{
            if let task = self.downloadTask{
                task.addObserver(self, forKeyPath: "countOfBytesReceived", options: .New, context: nil)
                task.addObserver(self, forKeyPath: "countOfBytesExpectedToReceive", options: .New, context: nil)
            }
        }
    }
    var url:NSURL?
    var dataResume:NSData?
    
    weak var cellOperation:FileDownloadCell?
    
    // MARK: ---Init
    init(url:NSURL?,fileName:String?){
        super.init()
        self.url = url
        self.fileName = fileName
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "removeDataGotMemoryWarning",
            name: UIApplicationDidReceiveMemoryWarningNotification,
            object: nil)
    }
    
    // MARK: ---Memory
    func removeDataGotMemoryWarning(){
        self.currentProgress = 0
        self.dataResume = nil
    }
    
    // MARK: ---Observer New Value
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if keyPath == "countOfBytesReceived"
        {
        
            guard let vl1 = self.downloadTask?.countOfBytesReceived, vl2 = self.downloadTask?.countOfBytesExpectedToReceive else{
                return
            }
            self.currentProgress = Float(vl1) / Float(vl2)
            print("value 1:\(vl1) ,value 2:\(vl2)")
            
        }

    }
    // MARK: ---Action
    func cancel(){
        isDownloading = false
        downloadTask?.cancelByProducingResumeData({ [weak self](data) -> Void in
            self?.dataResume = data
        })
    }
    
    func deleteTask(){
        downloadTask?.cancel()
        self.dataResume = nil
        self.downloadTask = nil
    }
    
    func startDownload(){
        defer{
            self.dataResume = nil
        }
        guard let session = self.session else{
            return
        }
        
        guard let dataResume = self.dataResume else{
            if let url = self.url{
                isDownloading = true
                self.isCompleted = false
                self.downloadTask = session.downloadTaskWithURL(url)
                self.taskIdentifier = self.downloadTask!.taskIdentifier
                self.downloadTask?.resume()
            }
            
            return
        }
        self.isCompleted = false
        isDownloading = true
        self.downloadTask = session.downloadTaskWithResumeData(dataResume)
        self.taskIdentifier = self.downloadTask!.taskIdentifier
        self.downloadTask?.resume()
        
    }
    
    // MARK: ---Memory
    deinit{
        print("\(__FUNCTION__) class: \(self.dynamicType) \n")
        NSNotificationCenter.defaultCenter().removeObserver(self)
        self.dataResume = nil
        self.downloadTask = nil
    }
    
    
}
// MARK: - Controller
class DownloadManagerViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 92
        tableView.rowHeight = UITableViewAutomaticDimension
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleNewFile", name: "NewFile", object: nil)
    }
    
    func handleNewFile(){
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
        print("\(__FUNCTION__) class : \(self.dynamicType)")
    }
    
    
}

// MARK: - TableView
extension DownloadManagerViewController:UITableViewDataSource{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DownloaderManager.sharedInstance().arrayDownloadItem.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FileDownloadCell") as! FileDownloadCell
        let fileInfo = DownloaderManager.sharedInstance().arrayDownloadItem[indexPath.row]
        cell.fileDownload = fileInfo
        fileInfo.cellOperation = cell
        cell.startDownloadTaskBlock = {[weak self](cell) in
            self?.downloadItem(cell)
        }
        
        cell.deleteDownloadTaskBlock = {[weak self](cell) in
            self?.deleteTaskAtCell(cell)
        }
        return cell
    }
    
}

extension DownloadManagerViewController:UITableViewDelegate
{
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let cellInfo = cell as? FileDownloadCell else{
            return
        }
        
        guard let file = cellInfo.fileDownload else{
            return
        }
        
        guard let index = DownloaderManager.sharedInstance().arrayDownloadItem.indexOf(file) else{
            return
        }
        
        let fileInfo = DownloaderManager.sharedInstance().arrayDownloadItem[index]
        fileInfo.cellOperation = nil
    }
}

// MARK: - Action
extension DownloadManagerViewController{
    func deleteTaskAtCell(cell:FileDownloadCell){
        guard let indexPath = self.tableView.indexPathForCell(cell) else{
            return
        }
        print("item at index :\(indexPath.row)\n")
        
        DownloaderManager.sharedInstance().arrayDownloadItem.removeAtIndex(indexPath.row)
        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        
    }
    
    func downloadItem(cell:FileDownloadCell){
        guard let indexPath = self.tableView.indexPathForCell(cell) else{
            return
        }
        
        let sender = cell.btnPauseDownload
        let fileInfo = DownloaderManager.sharedInstance().arrayDownloadItem[indexPath.row]
        
        if !sender.selected
        {
            fileInfo.startDownload()
        }else{
            fileInfo.cancel()
        }

        
    }
}

// MARK: - Helper
func getPercentFromProgress(value:Float) -> String?{
    let format = NSNumberFormatter()
    format.positiveFormat = "0.## %"
    return format.stringFromNumber(NSNumber(float: value))
}


