//
//  TodayViewController+Apps.swift
//  Augus
//
//  Created by Augus on 2/24/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


// MARK: - MacID
extension TodayViewController {
    
    internal func configureMacIDPanel() {
        macIDClipboardButton.setImageForMacIDButton(UIColor.yellowColor())
        macIDWakeButton.setImageForMacIDButton(UIColor.greenColor())
        
        macIDClipboardButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(TodayViewController.openMacID)))
        macIDWakeButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(TodayViewController.openMacID)))
        macIDLockButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(TodayViewController.openMacID)))
    }
    
    @IBAction func macIDSendClipboard(sender: AnyObject) {
        openSettingWithURL(AppsURL.MacIDClipboard.scheme)
    }
    
    @IBAction func macIDLock(sender: AnyObject) {
        openSettingWithURL(AppsURL.MacIDLock.scheme)
    }
    
    @IBAction func macIDWake(sender: AnyObject) {
        openSettingWithURL(AppsURL.MacIDWake.scheme)
    }
    
    internal func openMacID() {
        openSettingWithURL(AppsURL.MacID.scheme)
    }
    
    private func image(named: String) -> UIImage? {
        return UIImage(named: "mac_id")?.imageWithRenderingMode(.AlwaysTemplate)
    }
    
}


// MARK: - Surge

let kSurgeAutoClose = "kSurgeAutoClose"
let kSurgeAutoCloseDefaultBool = true

extension TodayViewController {
    
    internal func configureSurgePanel() {
        
        surgeAutoCloseSwitch.transform = CGAffineTransformMakeScale(0.55, 0.55)
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(surgeToggleDidLongPress(_:)))
        surgeButton?.addGestureRecognizer(recognizer)
    }
    
    internal func surgeToggleDidLongPress(sender: UILongPressGestureRecognizer) {
        
        guard sender.state == .Began else { return }
        
        let url = surgeAutoCloseSwitch.on ? AppsURL.SurgeAutoClose.scheme : AppsURL.SurgeToggle.scheme
        openSettingWithURL(url)
    }
    
    @IBAction func surgeAutoCloseSwitchDidTap(sender: UISwitch) {
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: kSurgeAutoClose)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    @IBAction func surgeToggleDidTap(sender: AnyObject) {
        let url = AppsURL.Surge.scheme
        openSettingWithURL(url)
    }
}


// MARK: - 

extension TodayViewController {
    
    @IBAction func open1Password(sender: AnyObject) {
        openSettingWithURL(AppsURL.OnePassword.scheme)
    }
    
    @IBAction func openOTPAuth(sender: AnyObject) {
        openSettingWithURL(AppsURL.OTPAuth.scheme)
    }
    
    @IBAction func openDuetDisplay(sender: AnyObject) {
        openSettingWithURL(AppsURL.Duet.scheme)
    }
    
    @IBAction func openReminders(sender: AnyObject) {
        openSettingWithURL(AppsURL.Reminders.scheme)
    }
    
    @IBAction func openNotes(sender: AnyObject) {
        openSettingWithURL(AppsURL.Notes.scheme)
    }
    
}

extension TodayViewController {
    
    @IBAction func openTumblr(sender: AnyObject) {
        openSettingWithURL(AppsURL.Tumblr.scheme)
    }
}

extension UIButton {
    
    private func setImageForMacIDButton(tintColor: UIColor) {
        setImage("mac_id", tintColor: tintColor)
    }

    private func setImage(named: String, tintColor: UIColor) {
        imageView?.tintColor = tintColor
        imageView?.layer.cornerRadius = imageView!.bounds.width / 2
        imageView?.layer.borderWidth  = 1.5
        imageView?.layer.borderColor  = UIColor.whiteColor().CGColor
        setImage(UIImage(named: named)?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    }
    
   }