//
//  AlarmViewController.swift
//  youtubeExample
//
//  Created by dungvh on 1/15/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import Foundation
import UIKit

let minTime:Float = 1

typealias AlarmSetTimerBlock = (Float)->()
typealias AlarmDeleteTimerBlock = ()->()

class AlarmViewController: UIViewController {
    
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var lblCurrentChoose: UILabel!
    
    var currentTime:Float = 0
    var blockSetTimer:AlarmSetTimerBlock?
    var blockDeleteTimer:AlarmDeleteTimerBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.clearColor()
        
        viewContainer.layer.cornerRadius = 20.0
        viewContainer.layer.shadowColor = UIColor.blackColor().CGColor
        viewContainer.layer.shadowOffset = CGSizeMake(0, 0)
        viewContainer.layer.shadowRadius = 10
        viewContainer.layer.shadowOpacity = 0.5
        viewContainer.layer.masksToBounds = true
        lblCurrentChoose.text = "\(Int(minTime))m"
        
    }
    
    @IBAction func tapByDismiss(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func handlerChooseTime(sender: UISlider) {
        defer{
            lblCurrentChoose.text = "\(Int(currentTime))m"
        }
        
        guard sender.value > minTime else {
            currentTime = minTime
            sender.value = minTime
            return
        }
        currentTime = sender.value
        
    }
    @IBAction func tapByDeleteTimer(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) {[weak self] () -> Void in
            self?.blockDeleteTimer?()
        }
    }
    
    @IBAction func tapBySetTimer(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) {[weak self] () -> Void in
            guard let actualSelf = self else{
                return
            }
            actualSelf.blockSetTimer?(actualSelf.currentTime)
        }
    }
    
    deinit {
        print("Deinit AlarmViewController\n")
    }
}