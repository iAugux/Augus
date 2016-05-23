
//
//  URLS.swift
//  Augus
//
//  Created by Augus on 2/24/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import Foundation

enum SettingsURL: String {
    case Settings        = "prefs:"
    case Wifi            = "prefs:root=WIFI"
    case Battery         = "prefs:root=BATTERY_USAGE"
    case Cellular        = "prefs:root=MOBILE_DATA_SETTINGS_ID"
    case PersonalHotspot = "prefs:root=INTERNET_TETHERING"
    case Siri            = "prefs:root=General&path=SIRI"
    case Developer       = "prefs:root=DEVELOPER"
    
    var scheme: String {
        return rawValue
    }
}


private let bluetoothUUID = "A1DFBC54-A551-8796-672F-0A2AC9860D09"

enum AppsURL: String {
    case MacIDClipboard
    case MacIDLock
    case MacIDWake
    case MacID           = "macid://wake/xxx" // just for opening MacID App
    case Surge           = "surge://"
    case SurgeToggle     = "surge:///toggle"
    case SurgeAutoClose  = "surge:///toggle?autoclose=true"
    case OnePassword     = "onepassword://launch"
    case OTPAuth         = "otpauth://"
    case Tumblr          = "tumblr://"
    
    var scheme: String {
        switch self {
        case .MacIDClipboard:
            return "macid://send-clipboard/\(bluetoothUUID)"
        case .MacIDLock:
            return "macid://lock/\(bluetoothUUID)"
        case .MacIDWake:
            return "macid://wake/\(bluetoothUUID)"
        default: return rawValue
        }
    }
}
