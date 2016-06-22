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
        macIDClipboardButton.setImageForMacIDButton(UIColor.yellow())
        macIDWakeButton.setImageForMacIDButton(UIColor.green())
        
        macIDClipboardButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(TodayViewController.openMacID)))
        macIDWakeButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(TodayViewController.openMacID)))
        macIDLockButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(TodayViewController.openMacID)))
    }
    
    @IBAction func macIDSendClipboard(_ sender: AnyObject) {
        openSettingWithURL(AppsURL.MacIDClipboard.scheme)
    }
    
    @IBAction func macIDLock(_ sender: AnyObject) {
        openSettingWithURL(AppsURL.MacIDLock.scheme)
    }
    
    @IBAction func macIDWake(_ sender: AnyObject) {
        openSettingWithURL(AppsURL.MacIDWake.scheme)
    }
    
    internal func openMacID() {
        openSettingWithURL(AppsURL.MacID.scheme)
    }
    
    private func image(_ named: String) -> UIImage? {
        return UIImage(named: "mac_id")?.withRenderingMode(.alwaysTemplate)
    }
    
}


// MARK: - Surge

let kSurgeAutoClose = "kSurgeAutoClose"
let kSurgeAutoCloseDefaultBool = true

extension TodayViewController {
    
    internal func configureSurgePanel() {
        
        surgeAutoCloseSwitch.transform = CGAffineTransform(scaleX: 0.55, y: 0.55)
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(surgeToggleDidLongPress(_:)))
        surgeButton?.addGestureRecognizer(recognizer)
    }
    
    internal func surgeToggleDidLongPress(_ sender: UILongPressGestureRecognizer) {
        
        guard sender.state == .began else { return }
        
        let url = surgeAutoCloseSwitch.isOn ? AppsURL.SurgeAutoClose.scheme : AppsURL.SurgeToggle.scheme
        openSettingWithURL(url)
    }
    
    @IBAction func surgeAutoCloseSwitchDidTap(_ sender: UISwitch) {
        UserDefaults.standard().set(sender.isOn, forKey: kSurgeAutoClose)
        UserDefaults.standard().synchronize()
    }
    
    @IBAction func surgeToggleDidTap(_ sender: AnyObject) {
        let url = AppsURL.Surge.scheme
        openSettingWithURL(url)
    }
}


// MARK: - 

extension TodayViewController {
    
    @IBAction func open1Password(_ sender: AnyObject) {
        openSettingWithURL(AppsURL.OnePassword.scheme)
    }
    
    @IBAction func openOTPAuth(_ sender: AnyObject) {
        openSettingWithURL(AppsURL.OTPAuth.scheme)
    }
    
    @IBAction func openDuetDisplay(_ sender: AnyObject) {
        openSettingWithURL(AppsURL.Duet.scheme)
    }
    
    @IBAction func openReminders(_ sender: AnyObject) {
        openSettingWithURL(AppsURL.Reminders.scheme)
    }
    
    @IBAction func openNotes(_ sender: AnyObject) {
        openSettingWithURL(AppsURL.Notes.scheme)
    }
    
}

extension TodayViewController {
    
    @IBAction func openTumblr(_ sender: AnyObject) {
        openSettingWithURL(AppsURL.Tumblr.scheme)
    }
}

extension UIButton {
    
    private func setImageForMacIDButton(_ tintColor: UIColor) {
        setImage("mac_id", tintColor: tintColor)
    }

    private func setImage(_ named: String, tintColor: UIColor) {
        imageView?.tintColor = tintColor
        imageView?.layer.cornerRadius = imageView!.bounds.width / 2
        imageView?.layer.borderWidth  = 1.5
        imageView?.layer.borderColor  = UIColor.white().cgColor
        setImage(UIImage(named: named)?.withRenderingMode(.alwaysTemplate), for: UIControlState())
    }
    
   }
