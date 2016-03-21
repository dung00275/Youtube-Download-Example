 //
//  ViewController.swift
//  youtubeExample
//
//  Created by dungvh on 9/24/15.
//  Copyright © 2015 dungvh. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer
 
let keyYouTubeApi = "AIzaSyAC2xwyoy-DEIzslrpZj8EnHCDxitc3RSE"
let ApiPath = "https://www.googleapis.com/youtube/v3/search"
let kBackgroudId = "kBackgroudId"

 // MARK: - Queue Excute
 protocol ExcutableQueue {
    var queue: dispatch_queue_t { get }
 }
 
 extension ExcutableQueue {
    func execute(closure: () -> Void) {
        dispatch_async(queue, closure)
    }
 }
 
 enum Queue: ExcutableQueue {
    case Main
    case UserInteractive
    case UserInitiated
    case Utility
    case Background
    
    var queue: dispatch_queue_t {
        switch self {
        case .Main:
            return dispatch_get_main_queue()
        case .UserInteractive:
            return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
        case .UserInitiated:
            return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
        case .Utility:
            return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
        case .Background:
            return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
        }
    }
 }
 // MARK: -- Init With Setup
 public func Init<Type>(value : Type, @noescape block: (object: Type) -> Void) -> Type
 {
    block(object: value)
    return value
 }
 
 
 // MARK: - Route
struct Router:URLRequestConvertible{
    var keyWord:String = ""
    var pageToken:String = ""
    
    var URLRequest:NSMutableURLRequest{
        var parameters = [String:AnyObject]()
        parameters["key"] = keyYouTubeApi
        parameters["q"] = keyWord
        parameters["order"] = "viewCount"
        parameters["part"] = "snippet"
        parameters["alt"] = "json"
        parameters["maxResults"] = 20
        if pageToken.characters.count > 0{
            parameters["pageToken"] = pageToken
        }
        
        let URL = NSURL(string: ApiPath)
        let URLRequest = NSURLRequest(URL: URL!)
        let encoding = ParameterEncoding.URL
        
        return encoding.encode(URLRequest, parameters: parameters).0
    }
}

// MARK: - Table Cell
typealias DownloadBlock = (youTubeCell)->()
class youTubeCell: UITableViewCell {
    
    @IBOutlet weak var imgVideo: UIImageView!
    @IBOutlet weak var lblNameVideo: UILabel!
    @IBOutlet weak var btnDownload: UIButton!
    
    var handler:DownloadBlock?
    override func prepareForReuse() {
        imgVideo.hnk_cancelSetImage()
        imgVideo.image = nil
    }
    
    override func awakeFromNib() {
        self.imgVideo.layer.cornerRadius = 5
        self.imgVideo.layer.masksToBounds = true
    }
    
    func setupDisplay(item:youTubeItem){
        if let thumpPath = item.thumbnails , url = NSURL(string: thumpPath){
            imgVideo.hnk_setImageFromURL(url)
        }
        
        lblNameVideo.text = item.title
        
    }
    
    @IBAction func tapByDownload(sender: AnyObject) {
        handler?(self)
    }
}

 func delay(delayInSeconds:Float,block:(()->())){
    let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSeconds) * Int64(NSEC_PER_SEC))
    dispatch_after(popTime, dispatch_get_main_queue(), block)
    
 }
 
 class BackgroundManager: Manager {
    var savedCompletionHandler: (() -> ())?
    
    init(){
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(kBackgroudId)
        super.init(configuration: configuration)
        
        delegate.sessionDidFinishEventsForBackgroundURLSession = { [weak self](session) in
            self?.savedCompletionHandler?()
            self?.savedCompletionHandler = nil
        }
        
        
    }

    struct Static {
        static let instance = BackgroundManager()
    }
    
    class func shareIntance() -> BackgroundManager{
        return Static.instance
    }
    
    
 }
 
class ViewController: UIViewController {
    //Constraint
    @IBOutlet weak var constraintRight: NSLayoutConstraint!
    @IBOutlet weak var constraintWidth: NSLayoutConstraint!
    @IBOutlet weak var constraintHeight: NSLayoutConstraint!
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var player:PlayerViewController!
    
    var items = [youTubeItem]()
    var currentTextSearch:String?
    var request:Request?
    var pageToken:String! = ""
    var isRequesting = false{
        didSet{
            if !isRequesting{
                self.refreshControl.endRefreshing()
            }
        }
    }
    var distanceTop:CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        return screenSize.width < screenSize.height ? 104 : 74
    }
    
    
    var currentNumberPage:Int = 0
    var refreshControl:UIRefreshControl!
    var isDownloading:Bool = false
//    var manager:BackgroundManager!
    var completeDownLoad:Bool = false{
        didSet{
            if completeDownLoad == true{
                delay(0.8, block: { () -> () in
                    NSNotificationCenter.defaultCenter().postNotificationName("NewFileDownloaded", object: nil, userInfo: nil)
                })
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    showNotificationWithImage("success", title: "Success", message: "Downloaded!!!!!!!!")
                })
            }
        }
    }
    
    var statePreview = PreViewState.Normal
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension

        let gesture = UIGestureRecognizer(target: self, action: nil)
        gesture.delegate = self
        self.view.addGestureRecognizer(gesture)
        
        preparePreview()
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "pullToRefresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handlerDownloadFromExtension:", name: kURLDownload, object: nil)
        self.requestData()
        
        guard let url = appDelegate.urlDownload else{
            return
        }
        appDelegate.urlDownload  = nil
        self.downloadWithUrl(url)
        
        
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if self.player != nil
        {
            self.player.pause()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


}
 
// MARK: - Gesture Handle
 extension ViewController:UIGestureRecognizerDelegate{
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if let view = touch.view where (view is UITextField) || (view is UISlider){
            return false
        }
        if gestureRecognizer is UIPanGestureRecognizer
        {
            return true
        }
        
        self.view.endEditing(true)
        
        return false
    }
    
 }

// MARK: - table view data source
extension ViewController:UITableViewDataSource{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("youTubeCell") as! youTubeCell
        cell.setupDisplay(self.items[indexPath.row])
        cell.handler = ({[weak self](youtubeCell:youTubeCell) in
            
            guard let actualSelf = self else
            {
                return
            }
            
            print("Cell : \(indexPath.row)")
            
            actualSelf.downloadFileAtIndexPath(indexPath)
            
        })
        return cell
    }
}

extension ViewController:UITableViewDelegate{
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row > currentNumberPage * 20 - 10{
            requestData()
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        guard let item = self.items[indexPath.row] as youTubeItem?, videoId = item.videoId else
        {
            showNotificationWithImage("errorNetwork", title: "Error", message: "Can't decode file!!!!!!!")
            return
        }
        
        LoadingView.showInView(self.view)

        Youtube.h264videosWithYoutubeID(videoId) { [weak self](params:[String:AnyObject]?) -> () in
            
            LoadingView.hideInView(self!.view)
            guard let param = params,videoURLString = param["url"] as? String , url = NSURL(string: videoURLString) else{
                showNotificationWithImage("errorNetwork", title: "Error", message: "Can't find link file!!!!!!!")
                return
            }
            do{
                try self?.openPlayer(url)
            }catch let error as NSError {
                print(error.description)
            }
            
        }
        
    }
}

// MARK: - Pull to refresh
extension ViewController{
    func pullToRefresh(){
        self.refreshControl.beginRefreshing()
        
        self.resetDataAndSearchAgain()
    }
}

// MARK: - Request data
extension ViewController{
    func requestData(){
        
        if !Reachability.isConnectedToNetwork()
        {
            showNotificationWithImage("errorNetwork", title: "Error", message: "No Internet !!!!!!!!!")
            return
        }
        
        
        if pageToken == nil
        {
            return
        }
        
        if isRequesting
        {
           return
        }
        
        guard let keyWord = currentTextSearch else
        {
            return
        }
        
        if keyWord.characters.count == 0 {
            isRequesting = false
            return
        }
        isRequesting = true
        request = Manager.sharedInstance.request(Router(keyWord: keyWord, pageToken: pageToken))
        request?.response(completionHandler: { [weak self](request, response, data:NSData?, error:NSError?) -> Void in
            self?.isRequesting = false
            if error == nil
            {
                Queue.Background.execute({ () -> Void in
                    self?.parseData(data)
                })
            }
        })
        
    }
    
}

extension ViewController{
    func parseData(data:NSData?)
    {
        guard let data = data else{
            return
        }
        
        do{
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            guard let response = Mapper<youTubeList>().map(json) as youTubeList?, items = response.items as [youTubeItem]? else{
                return
            }
            if let token = response.nextPageToken
            {
                pageToken = token
            }else{
                pageToken = nil
            }
            currentNumberPage++
            let oldItem = self.items.count
            var arrCell = [NSIndexPath]()
            for (index,item) in items.enumerate()
            {
                self.items.append(item)
                let indexPath = NSIndexPath(forRow: oldItem + index, inSection: 0)
                arrCell.append(indexPath)
            }
            dispatch_async(dispatch_get_main_queue(), { [weak self]() -> Void in
                self?.tableView.beginUpdates()
                self?.tableView.insertRowsAtIndexPaths(arrCell, withRowAnimation: .Fade)
                self?.tableView.endUpdates()
                })
        
            print("finsh!!!!!!")
            
        }catch let error as NSError{
            print(error.description)
        }
        
        
    }
}

// MARK: - Reset data
extension ViewController{
    
    func resetDataAndSearchAgain(){
        self.request?.cancel()
        currentNumberPage = 0
        isRequesting = false
        items.removeAll()
        tableView.reloadData()
        pageToken = ""
        requestData()
    }
    
}



extension ViewController:UISearchBarDelegate{
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"
        {
            searchBar.resignFirstResponder()
            if let text = searchBar.text where text.characters.count > 0{
                self.currentTextSearch = text.stringByRemovingPercentEncoding
            }
            resetDataAndSearchAgain()
        }
        
        return true
    }
}


// MARK: - Download
extension ViewController{
    
    func handlerDownloadFromExtension(notify:NSNotification){
        guard let url = notify.object as? String else{
            return
        }
        
        self.downloadWithUrl(url)
        
        
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
    
    
    func downloadFileAtIndexPath(indexPath:NSIndexPath)
    {
        if !Reachability.isConnectedToNetwork()
        {
            showNotificationWithImage("errorNetwork", title: "Error", message: "No Internet !!!!!!!!!")
            return
        }
        
        guard let item = self.items[indexPath.row] as youTubeItem?, videoId = item.videoId, title = item.title else
        {
            showNotificationWithImage("errorNetwork", title: "Error", message: "No Information Found To Download!!!!")
            return
        }
        
        LoadingView.showInView(self.view)
        Youtube.h264videosWithYoutubeID(videoId) { [weak self](params:[String:AnyObject]?) -> () in
            LoadingView.hideInView(self!.view)
            guard let param = params,videoURLString = param["url"] as? String else{
                self?.isDownloading = false
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self?.progressSimulation(1.0)
                    showNotificationWithImage("errorNetwork", title: "Error", message: "Failed Download!!!!!")
                })
                return
            }
            
            do{
                try DownloaderManager.sharedInstance().addDownload(NSURL(string: videoURLString), fileName: title)
                showNotificationWithImage("success", title: "Success", message: "Link Download Added!!!!!!!!")
                NSNotificationCenter.defaultCenter().postNotificationName("NewFile", object: nil, userInfo: nil)
            }catch let error as NSError{
                showNotificationWithImage("errorNetwork", title: "Error", message: error.localizedDescription)
            }
        }
        
    }
    
    func pathSaveFile(title:String) ->(NSURL, NSHTTPURLResponse) -> (NSURL)
    {
        return {[weak self] (temporaryURL, response) in
            self?.isDownloading = false
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self?.progressSimulation(1.0)
            })
            
            if let extensionFile = response.suggestedFilename, urlDownload = NSURL(string: documentFolder()){
                let name = title.stringByReplacingOccurrencesOfString("/", withString: "")
                
                let writePath =  urlDownload.URLByAppendingPathComponent("\(name).\(extensionFile)").path!
                guard let path = writePath.stringByRemovingPercentEncoding else{
                    return temporaryURL
                }
                let urlSaveFile = NSURL(fileURLWithPath: path)
                self?.completeDownLoad = true
                
                return urlSaveFile
            }
            
            return temporaryURL
        }

    }
    
    func downloadWithUrl(url:String){
        let title = getObjInAppGroup("kTitle") as? String ?? "NoName"
        do{
            try DownloaderManager.sharedInstance().addDownload(NSURL(string: url), fileName: title)
            showNotificationWithImage("success", title: "Success", message: "Link Download Added!!!!!!!!")
            NSNotificationCenter.defaultCenter().postNotificationName("NewFile", object: nil, userInfo: nil)
        }catch let error as NSError{
            showNotificationWithImage("errorNetwork", title: "Error", message: error.localizedDescription)
        }
        
    }
}
 // MARK: - Helper
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
 
 func showNotificationWithImage(image:String,title:String,message:String)
 {
    HDNotificationView.sharedInstance().showNotificationViewWithImage(UIImage(named: image), title: title, message: message, isAutoHide: true) { () -> () in
        HDNotificationView.sharedInstance().hideNotificationView()
    }

 }
 
 func createViewControllerFromStoryboard<T:UIViewController>(nameStoryBoard:String,bundlePath:String? = nil,controllerId:String) -> T?{
    let bundle:NSBundle? = bundlePath != nil ? NSBundle(path: bundlePath!) : nil
    let storyboard = UIStoryboard(name: nameStoryBoard, bundle: bundle)
    return storyboard.instantiateViewControllerWithIdentifier(controllerId) as? T
 }
 
let minHeight:CGFloat = 100
let minWidth:CGFloat = 160

 enum PreViewState:Int{
    case Normal = 0,
    Zooming,
    Hidden
 }
 
 
 // MARK: - Prepare Preview View
 extension ViewController{
    func preparePreview(){
        guard let playerController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PlayerViewController") as? PlayerViewController else{
            return
        }
        
        self.player = playerController
        self.player.delegate = self
        self.player.isEmbedded = true
        self.player.view.translatesAutoresizingMaskIntoConstraints = true
        self.player.view.autoresizingMask = [.FlexibleWidth,.FlexibleHeight]//UIViewAutoresizing.FlexibleWidth.union(.FlexibleHeight)
        self.player.view.frame = previewView.bounds
        
        self.addChildViewController(self.player)
        self.previewView.addSubview(self.player.view)
        self.player.didMoveToParentViewController(self)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: "pan:")
        panGesture.delegate = self
        self.previewView.addGestureRecognizer(panGesture)
        
        
        let doubleTap = UITapGestureRecognizer(target: self, action: "openFullScreen:")
        doubleTap.numberOfTapsRequired = 2
        
        self.previewView.addGestureRecognizer(doubleTap)
    }
    
    func openFullScreen(recognizer:UITapGestureRecognizer){
        self.player.alphaEmbedded = 1
        let sizeScreen = UIScreen.mainScreen().bounds.size
        self.constraintHeight.constant = sizeScreen.height - self.distanceTop
        self.constraintWidth.constant = sizeScreen.width
        
        self.player.view.setNeedsLayout()
        statePreview = .Zooming
    }
    
    func pan(recognizer:UIPanGestureRecognizer){
        let location = recognizer.locationInView(self.view)
        let sizeScreen = UIScreen.mainScreen().bounds.size
        let valueChangeY = sizeScreen.height - location.y - distanceTop
        let tuple:(Bool,Bool) = (valueChangeY >= minHeight , location.x != 0)
        switch recognizer.state {
        case .Changed:
            switch tuple{
                case (true,_):
                    if statePreview == .Hidden {
                        return
                    }
                    statePreview = .Zooming
                    previewView.alpha  = 1.0
                    self.constraintHeight.constant = valueChangeY
                    self.player.alphaEmbedded = valueChangeY / (sizeScreen.height - distanceTop)
                    let ratio = (valueChangeY - minHeight) / sizeScreen.height
                    self.constraintWidth.constant = min(ratio * sizeScreen.width + minWidth,sizeScreen.width)
                case (false,true):
                    if statePreview == .Zooming{
                        return
                    }
                    statePreview = .Hidden
                    let translation = recognizer.translationInView(view)
                    
                    let alpha = max(1 - fabs(translation.x)/120, 0)
                    constraintRight.constant = -translation.x
                    previewView.alpha = alpha

                default:
                    break
                }
        case .Ended:
            
            if location.y < CGRectGetMidY(UIScreen.mainScreen().bounds) && statePreview == .Zooming{
                self.player.alphaEmbedded = 1.0
                self.constraintHeight.constant = sizeScreen.height - distanceTop
                self.constraintWidth.constant = sizeScreen.width
                
            }else{
                
//                if statePreview == .Zooming && valueChangeY < minHeight {
//                    return
//                }
                
                self.player.alphaEmbedded = 0
                self.constraintHeight.constant = minHeight
                self.constraintWidth.constant = minWidth
                if statePreview != .Zooming
                {
                    let translation = recognizer.translationInView(view)
                    let alpha = max(1 - fabs(translation.x)/120, 0)
                    if alpha == 0
                    {
                        previewView.hidden = true
                        self.player.pause()
                    }
                    
                    constraintRight.constant = 0
                    previewView.alpha = 1
                }
                statePreview = .Normal
                
            }
            
            self.player.view.setNeedsLayout()
            
        default:
            break
        }
        
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ (context) -> Void in
            if self.statePreview == .Zooming {
                let sizeScreen = UIScreen.mainScreen().bounds.size
//                self.player.viewVolume.hidden = sizeScreen.width > sizeScreen.height
                self.constraintHeight.constant = sizeScreen.height - self.distanceTop
                self.constraintWidth.constant = sizeScreen.width
                self.player.view.setNeedsLayout()
            }
            
            }, completion: nil)
    }
 }
 
 // MARK: - Open safari Viewcontroller
 
 extension ViewController{
    
    @IBAction func tapByOpenSafari(sender: AnyObject) {
        appDelegate.tabbarViewController?.openSafari()
    }
 }
 
 
 // MARK: - Play Video
extension ViewController{
    func playYoutubeWithUrl(url:NSURL){
        Youtube.h264videosWithYoutubeURL(url) {[weak self] (videoInfo, error) -> Void in
            if let
                videoURLString = videoInfo?["url"] as? String{
                    guard let videoUrl = NSURL(string: videoURLString) else{
                        return
                    }
                    do{
                        try self?.openPlayer(videoUrl)
                    }catch let error as NSError {
                        print(error.description)
                    }
            }
        }
        
    }
    
    func openPlayer(videoUrl:NSURL) throws{
        self.previewView.hidden = false
        guard let playerController = self.player else{
            return
        }
        playerController.playVideoUrl(videoUrl)
        
        
    }
}
 // MARK: - PlayViewController delegate
 extension ViewController:PlayerViewControllerDelegate{
    func playerDidComplete(player: PlayerViewController) {
        self.playerMinimize()
    }
    
    func playerMinimize() {
        statePreview = .Normal
        self.player.alphaEmbedded = 0
        self.constraintHeight.constant = minHeight
        self.constraintWidth.constant = minWidth
        self.player.view.setNeedsLayout()
    }
    
    func playForward(player: PlayerViewController) {
        
    }
    
    func playRewind(player: PlayerViewController) {
        
    }
 }
 

