#if os(macOS)
// Created by Augus on 6/01/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import WidgetKit
import SwiftUI

// MARK: - Antigravity Widget Implementation

struct AntigravityProvider: TimelineProvider {
    func placeholder(in context: Context) -> AntigravityEntry {
        AntigravityEntry(date: Date(), usage: mockUsage, error: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (AntigravityEntry) -> ()) {
        let entry = AntigravityEntry(date: Date(), usage: AntigravityStore.loadUsageData() ?? mockUsage, error: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AntigravityEntry>) -> ()) {
        let latestData = AntigravityStore.loadUsageData()
        
        AntigravityNetworkManager.shared.fetchUsage { result in
            let entry: AntigravityEntry
            switch result {
            case .success(let data):
                entry = AntigravityEntry(date: Date(), usage: data, error: nil)
            case .failure(let error):
                entry = AntigravityEntry(date: Date(), usage: latestData, error: error.localizedDescription)
            }
            
            let fifteenMinutesFromNow = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            var nextUpdate = fifteenMinutesFromNow
            if let models = entry.usage?.models {
                for model in models {
                    if let resetTime = model.resetTime, resetTime > Date() && resetTime < fifteenMinutesFromNow {
                        nextUpdate = min(nextUpdate, resetTime.addingTimeInterval(15))
                    }
                }
            }
            
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private var mockUsage: AntigravityUsageData {
        AntigravityUsageData(
            models: [
                AntigravityModelQuota(name: "antigravity-2.5-pro", remainingFraction: 0.85, resetTime: Date().addingTimeInterval(3600 * 2.5)),
                AntigravityModelQuota(name: "antigravity-2.5-flash", remainingFraction: 0.95, resetTime: nil),
                AntigravityModelQuota(name: "antigravity-3.1-pro-preview", remainingFraction: 0.50, resetTime: Date().addingTimeInterval(3600 * 4.2))
            ],
            lastUpdated: Date(),
            email: "demo@google.com"
        )
    }
}

struct AntigravityWidget: Widget {
    let kind: String = "AntigravityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AntigravityProvider()) { entry in
            AntigravityEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackgroundView()
                }
                .widgetURL(URL(string: "augus://antigravity"))
        }
        .configurationDisplayName("Antigravity Limits")
        .description("Tracks Google Antigravity request quotas.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#endif
