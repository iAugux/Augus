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
    
    @IBAction func macIDSendClipboard(sender: AnyObject) {
        openSettingWithURL(AppsURL.MacID.rawValue)
    }

}


// MARK: - Surge

let kSurgeAutoClose = "kSurgeAutoClose"
let kSurgeAutoCloseDefaultBool = true

extension TodayViewController {
    
    internal func configureSurgePanel() {
        
        surgeAutoCloseSwitch.transform = CGAffineTransformMakeScale(0.55, 0.55)
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: "openSurgeApp")
        surgeButton?.addGestureRecognizer(recognizer)
    }
    
    internal func openSurgeApp() {
        let url = AppsURL.Surge.rawValue
        openSettingWithURL(url)
    }
    
    @IBAction func surgeAutoCloseSwitchDidTap(sender: UISwitch) {
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: kSurgeAutoClose)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    @IBAction func surgeToggleDidTap(sender: AnyObject) {
        
        let url = surgeAutoCloseSwitch.on ? AppsURL.SurgeAutoClose.rawValue : AppsURL.SurgeToggle.rawValue        
        openSettingWithURL(url)
    }
}