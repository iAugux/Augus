// Created by Augus on 5/30/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

@main
struct AugusApp: App {
    var body: some Scene {
#if os(macOS)
        Window("Augus", id: "main") {
            ContentView()
                .frame(minWidth: 393, idealWidth: 393, minHeight: 700, idealHeight: 700)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
#else
        WindowGroup {
            ContentView()
        }
#endif
    }
}
