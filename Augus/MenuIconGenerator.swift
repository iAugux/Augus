// Created by Augus
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

#if os(macOS)
fileprivate func colorForRemaining(_ remaining: Double) -> Color {
    if remaining > 0.5 {
        return .green
    } else if remaining > 0.2 {
        return .orange
    } else {
        return .red
    }
}

@MainActor
func generateMenuIcon(codexUsage: CodexUsageData?, isColored: Bool) -> NSImage {
    let view = ZStack {
        if let usage = codexUsage {
            let primaryRemaining = 1.0 - usage.primaryUsedPercent
            let secondaryRemaining = 1.0 - usage.secondaryUsedPercent
            
            let pColor = isColored ? colorForRemaining(primaryRemaining) : .black
            let sColor = isColored ? colorForRemaining(secondaryRemaining) : .black
            
            // Outer ring: 5h remaining
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
            Circle()
                .trim(from: 0.0, to: CGFloat(primaryRemaining))
                .stroke(pColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // Inner ring: 7d remaining
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                .padding(3.5)
            Circle()
                .trim(from: 0.0, to: CGFloat(secondaryRemaining))
                .stroke(sColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
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
        image.isTemplate = !isColored // Crucial: adapts to dark/light menu bar automatically if not colored
        return image
    }
    return NSImage(systemSymbolName: "cpu", accessibilityDescription: nil) ?? NSImage()
}
#endif
