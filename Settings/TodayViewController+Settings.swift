//
//  TodayViewController+Settings.swift
//  Augus
//
//  Created by Augus on 2/24/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation



extension TodayViewController {
    
    @IBAction func openSettings(sender: AnyObject) {
        openSettingWithURL(SettingsURL.Settings.rawValue)
    }
    
    @IBAction func openWifiSetting(sender: AnyObject) {
        openSettingWithURL(SettingsURL.Wifi.rawValue)
    }
    
    @IBAction func openBatterySetting(sender: AnyObject) {
        openSettingWithURL(SettingsURL.Battery.rawValue)
    }
    
    @IBAction func openCellularSetting(sender: AnyObject) {
        openSettingWithURL(SettingsURL.Cellular.rawValue)
    }
    
    @IBAction func openPersonalHotspotSetting(sender: AnyObject) {
        openSettingWithURL(SettingsURL.PersonalHotspot.rawValue)
    }
    
    @IBAction func openSiriSetting(sender: AnyObject) {
        openSettingWithURL(SettingsURL.Siri.rawValue)
    }
    
    @IBAction func openDeveloperSetting(sender: AnyObject) {
        openSettingWithURL(SettingsURL.Developer.rawValue)
    }
    
}
