// Created by Augus on 5/30/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

@main
struct AugusApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
#if os(macOS)
                .frame(minWidth: 393, idealWidth: 393, minHeight: 852, idealHeight: 852)
#endif
        }
    }
}
