
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


private let bluetoothUUID = "C3B46A81-4F90-9B01-47FB-B04D70FF87D0"

enum AppsURL: String {
    case MacID
    case MacIDLock
    case MacIDWake
    case Surge           = "surge://"
    case SurgeToggle     = "surge:///toggle"
    case SurgeAutoClose  = "surge:///toggle?autoclose=true"
    
    var scheme: String {
        switch self {
        case .MacID:
            return "macid://send-clipboard/\(bluetoothUUID)"
        case .MacIDLock:
            return "macid://lock/\(bluetoothUUID)"
        case .MacIDWake:
            return "macid://wake/\(bluetoothUUID)"
        default: return rawValue
        }
    }
}
