// Created by Augus
// Copyright © 2026 Augus <iAugux@gmail.com>

import Foundation
import Combine

#if os(macOS)
import AppKit
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "hasLaunchedBefore") {
            defaults.set(true, forKey: "hasLaunchedBefore")
            defaults.set(true, forKey: "isLaunchAtLogin")
            try? SMAppService.mainApp.register()
        } else {
            let launch = defaults.bool(forKey: "isLaunchAtLogin")
            if launch && SMAppService.mainApp.status != .enabled {
                try? SMAppService.mainApp.register()
            } else if !launch && SMAppService.mainApp.status == .enabled {
                try? SMAppService.mainApp.unregister()
            }
        }
        
        // Notify the app that it is safe to generate the menu bar icon
        NotificationCenter.default.post(name: NSNotification.Name("AppDidFinishLoading"), object: nil)
    }
}

class AppStateObserver: ObservableObject {
    @Published var isAppReady = false
    init() {
        NotificationCenter.default.addObserver(forName: NSApplication.didFinishLaunchingNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isAppReady = true
        }
    }
}
#endif
