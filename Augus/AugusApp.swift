// Created by Augus on 5/30/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import Combine
import SwiftUI


@main
struct AugusApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var menuBarViewModel = MenuBarViewModel()
    @StateObject private var appState = AppStateObserver()
    @AppStorage("isMenuBarIconColored") private var isMenuBarIconColored: Bool = false
    @AppStorage("isLaunchAtLogin") private var isLaunchAtLogin: Bool = true
#endif

    var body: some Scene {
#if os(macOS)
        MenuBarExtra {
            MenuBarWidgetView(viewModel: menuBarViewModel)
        } label: {
            if appState.isAppReady {
                Image(nsImage: generateMenuIcon(codexUsage: menuBarViewModel.codexEntry.usage, isColored: isMenuBarIconColored))
            } else {
                Image(systemName: "cpu")
            }
        }
        .menuBarExtraStyle(.window)

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
