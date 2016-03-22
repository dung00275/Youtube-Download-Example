//
//  WebViewViewController.swift
//  youtubeExample
//
//  Created by dungvh on 3/21/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import Foundation
import UIKit
import WebKit

let kUrlLastVisit = "kUrlLastVisit"
let kUrlDefaultHttp = "https://m.youtube.com/?"
class WebViewViewController:UIViewController
{
    private var viewSearch:UIView!
    private var sizeItemsBar:CGFloat = -1
    private var webView:WKWebView!
    private var textField:UITextField!
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var contentView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        let path = getValueFromUserDefaults(kUrlLastVisit) as String? ?? kUrlDefaultHttp
        let url = NSURL(string: path)
        textField.text = path
        self.webView.loadRequest(NSURLRequest(URL: url!))
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    
    deinit{
        print("func \(#function) class:\(self.dynamicType)")
        self.webView.removeObserver(self, forKeyPath: "estimatedProgress")
        self.webView.removeObserver(self, forKeyPath: "loading")
    }
}

// MARK: --- Helper
func saveToUserDefaults(object:AnyObject?,key:String){
    let userDefaults = NSUserDefaults.standardUserDefaults()
    userDefaults.setObject(object, forKey: key)
    userDefaults.synchronize()
}

func getValueFromUserDefaults<T>(key:String)->T?{
    let userDefaults = NSUserDefaults.standardUserDefaults()
    return userDefaults.objectForKey(key) as? T
}

func removeValueFromUserDefaults(key:String){
    let userDefaults = NSUserDefaults.standardUserDefaults()
    userDefaults.removeObjectForKey(key)
    userDefaults.synchronize()
}

// MARK: --- Setup views
extension WebViewViewController:UIGestureRecognizerDelegate{
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if !(touch.view is UITextField) {
            self.textField.resignFirstResponder()
        }
        
        return false
    }
    
}

extension WebViewViewController{
    private func setupView()
    {
        let gesture = UIGestureRecognizer(target: self, action: nil)
        gesture.delegate = self
        self.view.addGestureRecognizer(gesture)
        
        let frame = CGRect(origin: CGPointZero, size: CGSizeMake(80, 30))
        textField = UITextField(frame: frame)
        textField.borderStyle = .RoundedRect
        textField.clearButtonMode = .WhileEditing
        textField.returnKeyType = .Go
        textField.keyboardType = .URL
        textField.delegate = self
        
        viewSearch = UIView(frame: frame)
        viewSearch.addSubview(textField)
        viewSearch.backgroundColor = UIColor.clearColor()
        self.navigationItem.titleView = viewSearch
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        let left = textField.leftAnchor.constraintEqualToAnchor(viewSearch.leftAnchor)
        let top = textField.topAnchor.constraintEqualToAnchor(viewSearch.topAnchor)
        let right = textField.rightAnchor.constraintEqualToAnchor(viewSearch.rightAnchor)
        
        NSLayoutConstraint.activateConstraints([left,top,right])
        
        setupWebView()
        self.view.setNeedsLayout()
        
    }
    
    private func setupWebView(){
        
        let configurationWeb = WKWebViewConfiguration()
        configurationWeb.allowsInlineMediaPlayback = true
        configurationWeb.userContentController.addScriptMessageHandler(self, name: "MyApp")
        
        
        self.webView = WKWebView(frame: self.contentView.bounds, configuration: configurationWeb)
        self.webView.translatesAutoresizingMaskIntoConstraints = false

        self.webView.navigationDelegate = self
        self.contentView.addSubview(self.webView)
        
        let left = webView.leftAnchor.constraintEqualToAnchor(contentView.leftAnchor)
        let top = webView.topAnchor.constraintEqualToAnchor(contentView.topAnchor, constant: 0)
        let right = webView.rightAnchor.constraintEqualToAnchor(contentView.rightAnchor)
        let bottom = webView.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor)
        
        NSLayoutConstraint.activateConstraints([left,top,right,bottom])
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
        self.webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
    }
    
    private func layoutViewSearch()
    {
        if sizeItemsBar == -1
        {
            let leftItemWidth = self.navigationItem.leftBarButtonItem?.width ?? 0
            let rightItemWidth = self.navigationItem.rightBarButtonItem?.width ?? 0
            
            sizeItemsBar = leftItemWidth + rightItemWidth + 100
        }
        
        let screenSize = UIScreen.mainScreen().bounds.size
        let sizeSearch = screenSize.width - sizeItemsBar
        
        var frame = self.navigationItem.titleView?.bounds ?? CGRectZero
        frame.size.width = sizeSearch
        
        self.navigationItem.titleView?.bounds = frame
        
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        print("Progress : \(self.webView.estimatedProgress)")
//        self.progressView.hidden = false
        self.progressView.progress = Float(self.webView.estimatedProgress)
        print("Loading :\(self.webView.loading ? "Loading Url ..." : "Finish ....")")
        
        
    }
    
    override func viewWillLayoutSubviews() {
        
        self.layoutViewSearch()
        super.viewWillLayoutSubviews()
    }
    
    // MARK: - Show Alert
    func showAlert(titleAlert:String?,message:String?){
        let alert = UIAlertController(title: titleAlert, message: message, preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        alert.addAction(action)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}


// MARK: --- Webview delegate
extension WebViewViewController:WKScriptMessageHandler{
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        print("massage : \(message)")
        
    }
}


extension WebViewViewController:WKNavigationDelegate{
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        print("\(#function)")
        self.textField.text = webView.URL?.absoluteString
        saveToUserDefaults(self.textField.text, key: kUrlLastVisit)
        decisionHandler(.Allow)
    }
    
    func webViewWebContentProcessDidTerminate(webView: WKWebView) {
        print("\(#function)")
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        print("\(#function)")
//        self.textField.text = webView.URL?.absoluteString
//        saveToUserDefaults(self.textField.text, key: kUrlLastVisit)
        decisionHandler(.Allow)
    }

    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("\(#function)")
    }
    
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("\(#function)")
        self.progressView.hidden = false
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        print("\(#function)")
        self.progressView.hidden = true
    }
    
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        print("\(#function)")
        self.progressView.hidden = true
    }
    
}

// MARK: --- TextField Delegate
extension WebViewViewController:UITextFieldDelegate{
    func openLinkFromTextField() throws{
        guard var path = self.textField.text else{
            throw NSError(domain: "com.youtube", code: 466, userInfo: [NSLocalizedDescriptionKey:"Link Error!!!"])
        }
        if path.rangeOfString("http") == nil && path.rangeOfString("https") == nil {
            path = "http://" + path
        }
        guard let url = NSURL(string: path) where UIApplication.sharedApplication().canOpenURL(url) else {
            throw NSError(domain: "com.youtube", code: 467, userInfo: [NSLocalizedDescriptionKey:"Link Error!!!"])
        }
        
        let request = NSURLRequest(URL: url)
        self.webView.loadRequest(request)
    }
    
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        do{
            try self.openLinkFromTextField()
        }catch let error as NSError {
            showAlert("Error!!!", message: error.localizedDescription)
        }
        
        return true
    }
    
    
}


// MARK: --- Action
extension WebViewViewController {
    
    private func prepareDownload(){
        guard let url = self.webView.backForwardList.currentItem?.URL else{
            self.showAlert("Error!!", message: "Link Error, Please check")
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
            
            guard let info = videoInfo, urlLink = info["url"] as? String  where error == nil else{
                actualSelf.showAlert("No Infomation Found !!!", message: "Please try with other video!!!!")
                return
            }
            
            let title = info["title"] ?? "No Title"
            setKeyToAppGroup(title, key: "kTitle")

            appDelegate.handleDownLoadFromExtension(urlLink)
        }
    }
    
    @IBAction func tapBySendDownload(sender: AnyObject) {
        self.prepareDownload()
        
    }
    
    @IBAction func tapByBack(sender: AnyObject) {
        guard self.webView.canGoBack else {return}
        let url = self.webView.backForwardList.backItem?.URL.absoluteString
        self.textField.text = url
        self.webView.goBack()
    }
    
    @IBAction func tapByNext(sender: AnyObject) {
        guard self.webView.canGoForward else {return}
        let url = self.webView.backForwardList.forwardItem?.URL.absoluteString
        self.textField.text = url
        self.webView.goForward()
        
    }
    
    @IBAction func tapByReload(sender: AnyObject) {
        self.webView.reload()
    }
    
    @IBAction func tapBySetHttpDefault(sender: AnyObject) {
        saveURLToUserDefaults(kUrlDefaultHttp)
        self.textField.text = kUrlDefaultHttp
        do{
            try self.openLinkFromTextField()
        }catch let error as NSError {
            showAlert("Error!!!", message: error.localizedDescription)
        }
    }
    
    @IBAction func tapByOpenSafari(sender: AnyObject) {
        guard let link = self.textField.text , url = NSURL(string: link) where UIApplication.sharedApplication().canOpenURL(url) else{
            self.showAlert("Error Link", message: "Please check it again!!!")
            return
        }
        
        UIApplication.sharedApplication().openURL(url)
        
    }
}

