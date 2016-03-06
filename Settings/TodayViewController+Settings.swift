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
        openSettingWithURL(SettingsURL.Settings.scheme)
    }
    
    @IBAction func openWifiSetting(sender: AnyObject) {
        openSettingWithURL(SettingsURL.Wifi.scheme)
    }
    
    @IBAction func openBatterySetting(sender: AnyObject) {
        openSettingWithURL(SettingsURL.Battery.scheme)
    }
    
    @IBAction func openCellularSetting(sender: AnyObject) {
        openSettingWithURL(SettingsURL.Cellular.scheme)
    }
    
    @IBAction func openPersonalHotspotSetting(sender: AnyObject) {
        openSettingWithURL(SettingsURL.PersonalHotspot.scheme)
    }
    
    @IBAction func openSiriSetting(sender: AnyObject) {
        openSettingWithURL(SettingsURL.Siri.scheme)
    }
    
    @IBAction func openDeveloperSetting(sender: AnyObject) {
        openSettingWithURL(SettingsURL.Developer.scheme)
    }
    
}
