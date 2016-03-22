//
//  PlayerViewController.swift
//  youtubeExample
//
//  Created by dungvh on 1/13/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MediaPlayer
@objc protocol PlayerViewControllerDelegate:class{
    optional func playerMinimize()
    
    // control player next , rewind
    optional func playerDidComplete(player:PlayerViewController)
    optional func playRewind(player:PlayerViewController)
    optional func playForward(player:PlayerViewController)
    
    optional func playRandom()-> NSURL
    optional func playShuffer()-> NSURL
}

class PlayerViewController:UIViewController {
    
    //Public
    var delegate:PlayerViewControllerDelegate?
    var isEmbedded:Bool = false
    var alphaEmbedded:CGFloat = 0{
        didSet{
            self.setAlphaControl(self.alphaEmbedded)
        }
    }
    
    @IBOutlet weak var viewControl: UIView!
    @IBOutlet weak var viewVolume: UIView!
    
    @IBOutlet weak var lblCurrentTime: UILabel!
    @IBOutlet weak var lblRemain: UILabel!
    
    @IBOutlet weak var sliderVolume: UISlider!
    @IBOutlet weak var sliderPlaying: UISlider!
    
    @IBOutlet weak var btnRewind: UIButton!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnForward: UIButton!
    
    //Private
    private var asset: AVURLAsset!
    private var playerItem: AVPlayerItem!
    private var playerLayer = AVPlayerLayer()
    private var player:AVPlayer!
    private var timerTrackingPlaying:NSTimer?
    private var tapGesture:UITapGestureRecognizer!
    private var playingInfo:[String:AnyObject]?
    private var url:NSURL?
    private var isAlreadyAddObserverKeepUp:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preparePlay()
        
       
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    
    deinit{
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        print("Deinit PlayerViewController \n ")
        NSNotificationCenter.defaultCenter().removeObserver(self)
        self.view.removeGestureRecognizer(tapGesture)
        if player != nil
        {
            player.removeObserver(self, forKeyPath: "status")
        }
        
        
    }
    
}

// MARK: - Gesture handle
extension PlayerViewController:UIGestureRecognizerDelegate{
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if let view = touch.view where (view is UIButton) || (view is UISlider){
            return false
        }
        
        return true
    }
}

// MARK: - Handle change control in lock screen
extension PlayerViewController{
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        super.remoteControlReceivedWithEvent(event)
        guard let sEvent = event where sEvent.type == UIEventType.RemoteControl else{
            return
        }
        switch (sEvent.subtype){
        case .RemoteControlPlay,.RemoteControlPause:
            self.playAndPause()
        case .RemoteControlNextTrack:
            self.pause()
            self.delegate?.playForward?(self)
        case .RemoteControlPreviousTrack:
            self.pause()
            self.delegate?.playRewind?(self)
        default:
            break
        }
    }
}


// MARK: - Action from control
extension PlayerViewController{
    @IBAction func handlerChangeVolume(sender: UISlider) {
        if player != nil{
            player.volume = sender.value
        }
    }
    
    @IBAction func tapByClose(sender: AnyObject) {
        if !isEmbedded{
            resetPlay()
            self.dismissViewControllerAnimated(true, completion: nil)
        }else{
            self.delegate?.playerMinimize?()
        }
    }
    
    @IBAction func tapByRewind(sender: AnyObject) {
        self.pause()
        self.delegate?.playRewind?(self)
    }
    @IBAction func tapByPlayAndPause(sender: AnyObject) {
        playAndPause()
    }
    
    @IBAction func tapByForward(sender: AnyObject) {
        self.pause()
        self.delegate?.playForward?(self)
    }
    
    @IBAction func handlerSeekTime(sender: UISlider) {
        if self.player == nil {
            return
        }
        guard let currentItem = self.player.currentItem else{
            sender.value = 0
            return
        }
        currentItem.seekToTime(CMTimeMakeWithSeconds(Float64(sender.value), 60000))
        updateTimeForPlayer()
        
    }
    
}

// MARK: - Setup
extension PlayerViewController{
    private func setAlphaControl(value:CGFloat){
        viewControl.alpha = value
        viewVolume.alpha = value
        
        viewControl.hidden = value == 0
        viewVolume.hidden = value == 0
    }
    
    func preparePlay()
    {
        self.view.backgroundColor = UIColor.blackColor()
        self.view.layer.addSublayer(playerLayer)
        
        
        self.view.bringSubviewToFront(viewControl)
        
        let imagePlay = UIImage(named: "play")
        let imagePause = UIImage(named: "pause")
        let imageRewind = UIImage(named: "rewind")
        let imageForward = UIImage(named: "forward")
        
        self.btnPlay.setImage(imagePlay?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        self.btnPlay.setImage(imagePause?.imageWithRenderingMode(.AlwaysTemplate), forState: .Selected)
        self.btnRewind.setImage(imageRewind?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        self.btnForward.setImage(imageForward?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        
        if isEmbedded {
            self.setAlphaControl(0)
        }
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(playAndPause))
        self.view.addGestureRecognizer(tapGesture)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(itemPlayFinish(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(continuePlaying), name: AVPlayerItemPlaybackStalledNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(pause), name: "PausePlayer", object: nil)
        do{
            try self.setupInBackground()
        }catch let error as NSError{
            print(error.description)
        }
    }
    
    
    func setupInBackground() throws{
        do{
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            if !isEmbedded
            {
                UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
            }
            
            
        }catch let error as NSError{
            throw error
        }
    }
    
    func applicationDidEnterBackground(notification:NSNotification){
        self.pause()
    }
}


// MARK: - Handler Finish , Interrupt
extension PlayerViewController{
    func playAndPause(){
        if self.btnPlay.selected {
            self.pause()
        }else{
            self.play()
        }
        
    }
    
    func itemPlayFinish(notification:NSNotification){
        print("Play Complete!!!")
        resetPlay()
        lblCurrentTime.text = "00:00"
        lblRemain.text = "-00:00"
        self.sliderPlaying.value = 0
        self.btnPlay.selected = false
        if let delegate = self.delegate {
            delegate.playerDidComplete?(self)
        }
    }
}

// MARK: - Item Info
extension PlayerViewController{
    private func updateItemInfo(){
        self.player.volume = sliderVolume.value
        sliderPlaying.minimumValue = 0
        sliderPlaying.maximumValue = Float(CMTimeGetSeconds(playerItem.asset.duration))
        
        guard let player = self.player,currentPlaying = player.currentItem else{
            return
        }
        
        let duration = CMTimeGetSeconds(currentPlaying.asset.duration)
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let rate = player.rate
        
        if playingInfo == nil
        {
            playingInfo = [String:AnyObject]()
        }
        
        playingInfo![MPMediaItemPropertyTitle] = self.url?.lastPathComponent ?? ""
        playingInfo![MPMediaItemPropertyPlaybackDuration] = duration
        playingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        playingInfo![MPNowPlayingInfoPropertyPlaybackRate] = rate
        playingInfo![MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: UIImage(named: "Icon")!)
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = playingInfo
    }
}

// MARK: - Tracking Time
extension PlayerViewController{
    
     func updateTimeForPlayer(){
        var current = "00:00"
        var duration = "00:00"
        var value:Float = 0
        
        guard let player = self.player,currentItem = player.currentItem where btnPlay.selected else{
            return
        }
        let timeCurrent = CMTimeGetSeconds(player.currentTime())
        let timeDuration =  CMTimeGetSeconds(currentItem.asset.duration)
        current = String(format: "%02d:%02d", Int(timeCurrent) / 60,Int(timeCurrent) % 60)
        duration = String(format: "-%02d:%02d", Int(timeDuration - timeCurrent) / 60,Int(timeDuration - timeCurrent) % 60)
        
        value = Float(timeCurrent)
        lblCurrentTime.text = current
        lblRemain.text = duration
        sliderPlaying.value = value
        
    }
}


// MARK: - Play
extension PlayerViewController{
    
    private func resetPlay(){
        if self.player != nil {
            self.player.removeObserver(self, forKeyPath: "status")
            if let currentItem = self.player.currentItem where isAlreadyAddObserverKeepUp {
                self.isAlreadyAddObserverKeepUp = false
                currentItem.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            }
            
            self.player = nil
        }
        self.timerTrackingPlaying?.invalidate()
        self.timerTrackingPlaying = nil
    }
    
    func playVideoUrl(url:NSURL){
        self.view.userInteractionEnabled = false
        self.url = url
        resetPlay()
        
        self.asset = AVURLAsset(URL: url)
        self.playerItem = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: playerItem)
        playerLayer.player = player
        player.addObserver(self, forKeyPath: "status", options: .New, context: nil)
//        player.addObserver(self, forKeyPath: "rate", options: [], context: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "status"{
            self.view.userInteractionEnabled = true
            guard let player = self.player where player.status == .ReadyToPlay else{
                return
            }
            self.play()
            self.updateItemInfo()
            return
        }
        if keyPath == "playbackLikelyToKeepUp" {
            guard let player = self.player, currentItem = player.currentItem else{
                return
            }
            if currentItem.playbackLikelyToKeepUp{
                self.isAlreadyAddObserverKeepUp = false
                currentItem.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
                self.play()
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("bounds : \(view.bounds)")
        self.viewVolume.hidden = view.bounds.size.width > view.bounds.size.height
        playerLayer.frame = view.bounds
    }
    
    func continuePlaying(){
        guard let player = self.player, currentItem = player.currentItem else{
            return
        }
        
        if player.rate == 0 && CMTimeGetSeconds(currentItem.asset.duration) != CMTimeGetSeconds(player.currentTime()){
            self.pause()
            self.isAlreadyAddObserverKeepUp = true
            currentItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .New, context: nil)
        }
        
    }
    
    private func play()
    {
        if self.player != nil{
            self.btnPlay.selected = true
            self.player.play()
            self.timerTrackingPlaying = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: #selector(updateTimeForPlayer), userInfo: nil, repeats: true)
            updateTimeForPlayer()
        }
    }
    
    func pause()
    {
        if player != nil{
            self.btnPlay.selected = false
            self.player.pause()
            self.timerTrackingPlaying?.invalidate()
            self.timerTrackingPlaying = nil
        }
        
    }
    
}
