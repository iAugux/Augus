// Created by Augus on 6/01/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Codex Widget Implementation

struct CodexProvider: TimelineProvider {
    func placeholder(in context: Context) -> CodexEntry {
        CodexEntry(date: Date(), usage: mockUsage, error: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (CodexEntry) -> ()) {
        let entry = CodexEntry(date: Date(), usage: CodexStore.loadUsageData() ?? mockUsage, error: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CodexEntry>) -> ()) {
        let latestData = CodexStore.loadUsageData()
        
        CodexNetworkManager.shared.fetchUsage { result in
            let entry: CodexEntry
            switch result {
            case .success(let data):
                entry = CodexEntry(date: Date(), usage: data, error: nil)
            case .failure(let error):
                entry = CodexEntry(date: Date(), usage: latestData, error: error.localizedDescription)
            }
            
            let fifteenMinutesFromNow = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            var nextUpdate = fifteenMinutesFromNow
            if let data = entry.usage {
                let primaryResetDate = Date(timeIntervalSince1970: TimeInterval(data.primaryResetAt))
                if primaryResetDate > Date() && primaryResetDate < fifteenMinutesFromNow {
                    nextUpdate = primaryResetDate.addingTimeInterval(15)
                }
            }
            
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private var mockUsage: CodexUsageData {
        CodexUsageData(
            primaryUsedPercent: 0.45,
            primaryResetAt: Int64(Date().addingTimeInterval(3600 * 3.5).timeIntervalSince1970),
            secondaryUsedPercent: 0.20,
            secondaryResetAt: Int64(Date().addingTimeInterval(3600 * 24 * 5.2).timeIntervalSince1970),
            planType: "plus",
            lastUpdated: Date(),
            isLoggedIn: true,
            email: "demo@codex.com"
        )
    }
}

struct CodexWidget: Widget {
    let kind: String = "CodexWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CodexProvider()) { entry in
            CodexEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackgroundView()
                }
                .widgetURL(URL(string: "augus://codex"))
        }
        .configurationDisplayName("Codex Limits")
        .description("Shows Codex usage caps (5h and 7d rolling windows).")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
