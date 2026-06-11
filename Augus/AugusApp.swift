// Created by Augus on 5/30/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

@main
struct AugusApp: App {
#if os(macOS)
    @StateObject private var menuBarViewModel = MenuBarViewModel()
#endif

    var body: some Scene {
#if os(macOS)
        MenuBarExtra {
            MenuBarWidgetView(viewModel: menuBarViewModel)
        } label: {
            Image(nsImage: generateMenuIcon(codexUsage: menuBarViewModel.codexEntry.usage))
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
import SwiftUI
import Combine

#if os(macOS)
@MainActor
func generateMenuIcon(codexUsage: CodexUsageData?) -> NSImage {
    let view = ZStack {
        if let usage = codexUsage {
            let primaryRemaining = 1.0 - usage.primaryUsedPercent
            let secondaryRemaining = 1.0 - usage.secondaryUsedPercent
            
            // Outer ring: 5h remaining
            Circle()
                .stroke(Color.black.opacity(0.3), lineWidth: 1.5)
            Circle()
                .trim(from: 0.0, to: CGFloat(primaryRemaining))
                .stroke(Color.black, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // Inner ring: 7d remaining
            Circle()
                .stroke(Color.black.opacity(0.3), lineWidth: 1.5)
                .padding(3.5)
            Circle()
                .trim(from: 0.0, to: CGFloat(secondaryRemaining))
                .stroke(Color.black, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(3.5)
        } else {
            Image(systemName: "cpu")
                .resizable()
                .scaledToFit()
        }
    }
    .frame(width: 16, height: 16)
    .padding(3) // Extra padding to fit within a 22x22 menu bar icon perfectly
    
    let renderer = ImageRenderer(content: view)
    renderer.scale = 2.0 // @2x scale for crispness
    if let image = renderer.nsImage {
        image.isTemplate = true // Crucial: adapts to dark/light menu bar automatically
        return image
    }
    return NSImage(systemSymbolName: "cpu", accessibilityDescription: nil) ?? NSImage()
}
#endif
