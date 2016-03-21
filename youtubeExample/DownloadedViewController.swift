//
//  DownloadedViewController.swift
//  youtubeExample
//
//  Created by dungvh on 9/25/15.
//  Copyright © 2015 dungvh. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import MediaPlayer
import CoreSpotlight

class DownloadCell: UITableViewCell {
    
    @IBOutlet weak var lblCreated: UILabel!
    @IBOutlet weak var lblFileName: UILabel!
}

class DownloadedViewController: UIViewController {
    var items = [FileProperties]()
    @IBOutlet weak var tableView: UITableView!
    var transition = TransitionDelegate()
    var overlayTransitioningDelegate = OverlayTransitioningDelegate()
    var currentItemPlay:Int = -1
    var filePathOpenFromSearch:String?
    var btnAlarm:UIButton!
    var timerPausePlayer:NSTimer?
    weak var player:PlayerViewController?
    var isOpenBySearch:Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "getData", name: "NewFileDownloaded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleNotificationSearch:", name: "PlayVideo", object: nil)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70
        
        self.btnAlarm = UIButton(frame: CGRect(origin: CGPointZero, size: CGSizeMake(40, 40)))
        self.btnAlarm.tintColor = UIColor.whiteColor()
        let imageAlarm = UIImage(named: "alarm")
        self.btnAlarm.setImage(imageAlarm?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        self.btnAlarm.addTarget(self, action: "openSetupAlarm", forControlEvents: .TouchUpInside)
        
        let itemRight = UIBarButtonItem(customView: self.btnAlarm)
        
        self.navigationItem.rightBarButtonItem = itemRight
//        self.navigationController?.hidesBarsOnSwipe = true
        
        
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        getData()
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
// MARK: - Alarm
extension DownloadedViewController{
    func openSetupAlarm(){
        print("Open Setup \n")
        guard let alarmController = createViewControllerFromStoryboard("Main", controllerId: "AlarmViewController") as? AlarmViewController else{
            return
        }
        
        alarmController.blockDeleteTimer = {[weak self] in
            self?.timerPausePlayer?.invalidate()
            self?.timerPausePlayer = nil
        }
        
        alarmController.blockSetTimer = {[weak self] (value:Float) in
            self?.setTimerToPausePlayVideo(value)
        }
        
        alarmController.transitioningDelegate = overlayTransitioningDelegate
        alarmController.modalPresentationStyle = .Custom
        
        self.presentViewController(alarmController, animated: true, completion: nil)
    }
    
    private func setTimerToPausePlayVideo(time:Float)
    {
        self.timerPausePlayer?.invalidate()
        self.timerPausePlayer = nil
        
        self.timerPausePlayer = NSTimer.scheduledTimerWithTimeInterval(Double(time * 60), target: self, selector: "pausePlayer", userInfo: nil, repeats: false)
    }
    
    func pausePlayer(){
       NSNotificationCenter.defaultCenter().postNotificationName("PausePlayer", object: nil, userInfo: nil)
    }
    
}

// MARK: - Setup data
extension DownloadedViewController{
    struct FileProperties {
        var path:String
        var date:NSDate
    }
    
    func moveFileInAppGroup(arr:[NSURL]){
        let documentPath = NSURL(fileURLWithPath: documentFolder())
        for linkFile in arr{
            if (linkFile.absoluteString as NSString).rangeOfString(".mp4").location != NSNotFound {
                do{
                    let fileName = linkFile.lastPathComponent ?? "file.mp4"
                    let urlSave = documentPath.URLByAppendingPathComponent(fileName)
                    try NSFileManager.defaultManager().moveItemAtURL(linkFile, toURL: urlSave)
                }catch let error as NSError{
                    print(error.description)
                    removeItem(linkFile)
                }
                
            }
        }
        
    }
    func removeItem(url:NSURL){
        do{
            
            try NSFileManager.defaultManager().removeItemAtURL(url)
        }catch let error as NSError{
            print(error.description)
            
        }
    }
    
    func getData(){
        
        if let groupURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.dungvh.youTubeExtension"){
            do{
                let arr = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(groupURL, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
                
                self.moveFileInAppGroup(arr)
                
                print("test")
            }catch let error as NSError{
                print(error.description)
            }
            
        }
        
        self.items.removeAll()
        defer{
            self.tableView.reloadData()
            self.saveDataToSearch()
            if isOpenBySearch {
                self.openItemBySearchCoreSpotlight()
            }
        }
        
        let folderUrl = NSURL(fileURLWithPath: documentFolder())
        do{
            
            let urls = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(folderUrl, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
            var filesAndProperties = [FileProperties]()
            for url in urls{
                let pathFile:String = url.path!
                let properties = try NSFileManager.defaultManager().attributesOfItemAtPath(pathFile)
                if let date = properties[NSFileModificationDate] as? NSDate
                {
                    let file = FileProperties(path: pathFile, date: date)
                    filesAndProperties.append(file)
                }
            }
            
            items = filesAndProperties.sort({ (s1:FileProperties, s2:FileProperties) -> Bool in
                return s1.date.compare(s2.date) == NSComparisonResult.OrderedDescending
            })
            
        }catch let error as NSError{
            print(error.description)
        }
    }
    
    func handleNotificationSearch(notify:NSNotification){
        guard let filePath = notify.object as? String else{
            return
        }
        isOpenBySearch = true
        filePathOpenFromSearch = filePath
        self.getData()
    }
    
    private func openItemBySearchCoreSpotlight(){
        isOpenBySearch = false
        guard let path = self.filePathOpenFromSearch else{
            return
        }
        
        for (idx,file) in items.enumerate() {
            if file.path == path {
                currentItemPlay = idx
                break
            }
        }
        
        if currentItemPlay >= 0 && currentItemPlay < self.items.count {
            let item = items[currentItemPlay]
            let urlPath = NSURL(fileURLWithPath: item.path)
            if player != nil{
                player?.playVideoUrl(urlPath)
            }else{
                openPlayer(urlPath)
            }
        }
    }
    
    private func saveDataToSearch(){
        var searchableItems = [CSSearchableItem]()
        for file in items{
            let attributeSet = CSSearchableItemAttributeSet(itemContentType: "image" as String)
            attributeSet.title = NSURL(fileURLWithPath: file.path).URLByDeletingPathExtension?.lastPathComponent ?? "Unknown Name"
            attributeSet.contentDescription = "Video From YouTube Downloader !"
            
            let item = CSSearchableItem(uniqueIdentifier: "\(file.path)", domainIdentifier: "com.defide-ix.YouTubeDowloader.file", attributeSet: attributeSet)
            searchableItems.append(item)
        }
        
        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems(searchableItems) { (error) -> Void in
            if error != nil{
                print(error?.description)
            }
        }
    }
}

let kTimeFormat = "EEEE, dd/MM/YYYY hh:mm"
extension NSDate{
    func createStringWithFormat(format:String) ->String
    {
        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = format
        return dateFormat.stringFromDate(self)
    }
}

// MARK: - Table View
extension DownloadedViewController:UITableViewDataSource{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DownloadCell") as!DownloadCell
        let item = items[indexPath.row]
        cell.lblFileName.text = NSURL(fileURLWithPath: item.path).lastPathComponent
        cell.lblCreated.text = item.date.createStringWithFormat(kTimeFormat)
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool{
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath){
        if editingStyle == .Delete{
            self.deleteFileAtIndex(indexPath)
        }
    }
}

extension DownloadedViewController:UITableViewDelegate{
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        print("tap Item !!!")
        showAlertAtIndex(indexPath)
        
    }
}

// MARK: - Show Alert
extension DownloadedViewController{
    func showAlertAtIndex(indexPath:NSIndexPath){
        let alertViewController = UIAlertController(title: "Note", message: "What do you want?", preferredStyle: .Alert)
        
        let alertViewVideo = UIAlertAction(title: "Open Video", style: .Default) { [weak self](action) -> Void in
             alertViewController.dismissViewControllerAnimated(true, completion: nil)
            self?.openVideoVideoAtIndex(indexPath)
        }
        
//        let alertDelete = UIAlertAction(title: "Delete", style: .Destructive) { [weak self](action) -> Void in
//            alertViewController.dismissViewControllerAnimated(true, completion: nil)
//            self?.deleteFileAtIndex(indexPath)
//        }
        
        let alertCancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
            alertViewController.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alertViewController.addAction(alertViewVideo)
//        alertViewController.addAction(alertDelete)
        alertViewController.addAction(alertCancel)
        
        
        self.presentViewController(alertViewController, animated: true, completion: nil)
    }
}

extension DownloadedViewController{
    func deleteFileAtIndex(index:NSIndexPath){
        let path = items[index.row].path
        do{
            let _ = try NSFileManager.defaultManager().removeItemAtPath(path)
            self.items.removeAtIndex(index.row)
            
            self.tableView.deleteRowsAtIndexPaths([index], withRowAnimation: .Fade)
            
        }catch let error as NSError{
            print(error.description)
        }
    }
}




// MARK: - Open player
extension DownloadedViewController{
    
    func openVideoVideoAtIndex(indexPath:NSIndexPath)
    {
        currentItemPlay = indexPath.row
        let item = items[indexPath.row]
        let urlPath = NSURL(fileURLWithPath: item.path)
    
        
        openPlayer(urlPath)
        
    }
    
    func openPlayer(videoUrl:NSURL){
        guard let playerController = createViewControllerFromStoryboard("Main", controllerId: "PlayerViewController") as? PlayerViewController else{
            return
        }
        self.player = playerController
        playerController.modalPresentationStyle = .Custom
        playerController.transitioningDelegate = transition
        playerController.delegate = self
        playerController.playVideoUrl(videoUrl)
        self.presentViewController(playerController, animated: true, completion: nil)
        
    }
}
// MARK: - Player Delegate
extension DownloadedViewController:PlayerViewControllerDelegate{
    func playerDidComplete(player: PlayerViewController) {
        self.playForward(player)
    }
    
    func playForward(player: PlayerViewController) {
        if currentItemPlay >= 0 && currentItemPlay < (items.count - 1){
            currentItemPlay++
            let item = items[currentItemPlay]
            let urlPath = NSURL(fileURLWithPath: item.path)
            player.playVideoUrl(urlPath)
            
        }
    }
    
    func playRewind(player: PlayerViewController) {
        if currentItemPlay > 0 {
            currentItemPlay--
            let item = items[currentItemPlay]
            let urlPath = NSURL(fileURLWithPath: item.path)
            player.playVideoUrl(urlPath)
        }
    }
    
}

// MARK: -- Class Animator
class Animator:NSObject,UIViewControllerAnimatedTransitioning{
    var duration:NSTimeInterval?
    var isPresent:Bool = true
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return duration ?? 0.5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        guard let containerView = transitionContext.containerView() else{
            return
        }
        
        if isPresent
        {
            guard let toController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else{
                transitionContext.completeTransition(true)
                return
            }
            containerView.addSubview(toController.view)
            toController.view.alpha = 0
            toController.view.transform = CGAffineTransformMakeScale(0.2, 0.2)
            UIView.animateWithDuration(self.transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 10, options: .CurveEaseInOut, animations: { () -> Void in
                toController.view.alpha = 1
                toController.view.transform = CGAffineTransformIdentity
                }, completion: { (isComplete) -> Void in
                    transitionContext.completeTransition(true)
            })
        }else{
            guard let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) else{
                transitionContext.completeTransition(true)
                return
            }
            containerView.addSubview(fromViewController.view)
            UIView.animateWithDuration(self.transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 10, options: .CurveEaseInOut, animations: { () -> Void in
                fromViewController.view.alpha = 0
                fromViewController.view.transform = CGAffineTransformMakeScale(0.1, 0.1)
                }, completion: { (isComplete) -> Void in
                    fromViewController.view.removeFromSuperview()
                    transitionContext.completeTransition(true)
            })
        }
    }
}

// MARK: -- Class Transition Delegate
class TransitionDelegate:NSObject,UIViewControllerTransitioningDelegate{
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = Animator()
        return animator
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = Animator()
        animator.isPresent = false
        return animator
    }
}


// MARK: -- Overlay Presentation controller

class OverlayPresentationController: UIPresentationController{
    var dimmingView:UIView!
    
    override init(presentedViewController: UIViewController, presentingViewController: UIViewController) {
        super.init(presentedViewController: presentedViewController, presentingViewController: presentingViewController)
        setupDimmingView()
    }
    
    func setupDimmingView(){
        let frame = containerView?.bounds ??  CGRectZero
        dimmingView = UIView(frame: frame)
        
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark)) as UIVisualEffectView
        visualEffectView.frame = dimmingView.bounds
        visualEffectView.autoresizingMask =  UIViewAutoresizing.FlexibleHeight.union(.FlexibleWidth)
        dimmingView.addSubview(visualEffectView)
        
//        let tapRecognizer = UITapGestureRecognizer(target: self, action: "dimmingViewTapped:")
//        dimmingView.addGestureRecognizer(tapRecognizer)
    }
    
    override func presentationTransitionWillBegin() {
        dimmingView.alpha = 0.0
        containerView?.insertSubview(dimmingView, atIndex: 0)
        
        presentedViewController.transitionCoordinator()?.animateAlongsideTransition({ (context) -> Void in
            self.dimmingView.alpha = 1.0
            }, completion: nil)
    }
    
    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator()?.animateAlongsideTransition({
            context in
            self.dimmingView.alpha = 0.0
            }, completion: {
                context in
                self.dimmingView.removeFromSuperview()
        })
    }
    
    override func frameOfPresentedViewInContainerView() -> CGRect {
        return containerView?.bounds.insetBy(dx: 30, dy: 30) ?? CGRectZero
    }
    
    override func containerViewWillLayoutSubviews() {
        dimmingView.frame = containerView?.bounds ?? CGRectZero
        presentedView()?.frame = frameOfPresentedViewInContainerView()
    }
}

// MARK: -- Presentation Transition
class OverlayTransitioningDelegate : NSObject, UIViewControllerTransitioningDelegate {
    
    func presentationControllerForPresentedViewController(presented: UIViewController,
        presentingViewController presenting: UIViewController,
        sourceViewController source: UIViewController) -> UIPresentationController? {
            
            return OverlayPresentationController(presentedViewController: presented,
                presentingViewController: presenting)
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController)-> UIViewControllerAnimatedTransitioning? {
        let animator = Animator()
        return animator
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = Animator()
        animator.isPresent = false
        return animator
    }
    
}



