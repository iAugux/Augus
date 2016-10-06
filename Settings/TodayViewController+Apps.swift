//
//  TodayViewController+Apps.swift
//  Augus
//
//  Created by Augus on 2/24/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit


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
