// Created by Augus on 6/01/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import WidgetKit
import SwiftUI

// MARK: - Gemini Widget Implementation

struct GeminiProvider: TimelineProvider {
    func placeholder(in context: Context) -> GeminiEntry {
        GeminiEntry(date: Date(), usage: mockUsage, error: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (GeminiEntry) -> ()) {
        let entry = GeminiEntry(date: Date(), usage: GeminiStore.loadUsageData() ?? mockUsage, error: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GeminiEntry>) -> ()) {
        let latestData = GeminiStore.loadUsageData()
        
        GeminiNetworkManager.shared.fetchUsage { result in
            let entry: GeminiEntry
            switch result {
            case .success(let data):
                entry = GeminiEntry(date: Date(), usage: data, error: nil)
            case .failure(let error):
                entry = GeminiEntry(date: Date(), usage: latestData, error: error.localizedDescription)
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
    
    private var mockUsage: GeminiUsageData {
        GeminiUsageData(
            models: [
                GeminiModelQuota(name: "gemini-2.5-pro", remainingFraction: 0.85, resetTime: Date().addingTimeInterval(3600 * 2.5)),
                GeminiModelQuota(name: "gemini-2.5-flash", remainingFraction: 0.95, resetTime: nil),
                GeminiModelQuota(name: "gemini-3.1-pro-preview", remainingFraction: 0.50, resetTime: Date().addingTimeInterval(3600 * 4.2))
            ],
            lastUpdated: Date(),
            email: "demo@google.com"
        )
    }
}

struct GeminiWidget: Widget {
    let kind: String = "GeminiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GeminiProvider()) { entry in
            GeminiEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackgroundView()
                }
                .widgetURL(URL(string: "augus://gemini"))
        }
        .configurationDisplayName("Gemini Limits")
        .description("Tracks Google Gemini request quotas.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
