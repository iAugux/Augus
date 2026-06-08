// Created by Augus on 5/30/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import WidgetKit
import SwiftUI
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BlackSSLEntry {
        BlackSSLEntry(date: Date(), usage: mockUsage, error: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (BlackSSLEntry) -> ()) {
        let entry = BlackSSLEntry(date: Date(), usage: BlackSSLStore.loadUsageData() ?? mockUsage, error: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BlackSSLEntry>) -> ()) {
        // Fetch new usage details in the background when requested
        BlackSSLNetworkManager.shared.fetchUsage { result in
            let latestData = BlackSSLStore.loadUsageData()
            let entry: BlackSSLEntry
            
            switch result {
            case .success(let data):
                entry = BlackSSLEntry(date: Date(), usage: data, error: nil)
            case .failure(let error):
                // If it fails, reuse last successful data, but flag the error if wanted
                entry = BlackSSLEntry(date: Date(), usage: latestData, error: error.localizedDescription)
            }
            
            // Re-fetch every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private var mockUsage: BlackSSLUsageData {
        BlackSSLUsageData(
            upload: 12_400_000_000,
            download: 38_600_000_000,
            total: 100_000_000_000,
            expiredAt: Int64(Date().addingTimeInterval(3600 * 24 * 12).timeIntervalSince1970),
            email: "user@blackssl.com",
            lastUpdated: Date(),
            isLoggedIn: true,
            todayUsed: 653_850_000
        )
    }
}

struct BlackSSL: Widget {
    let kind: String = "BlackSSL"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BlackSSLEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackgroundView()
                }
                .widgetURL(URL(string: "augus://blackssl"))

        }
        .configurationDisplayName("BlackSSL Status")
        .description("Shows traffic usage and subscription expiration of your BlackSSL account.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WidgetBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.08, green: 0.08, blue: 0.15), Color(red: 0.03, green: 0.03, blue: 0.06)]
                : [Color(red: 0.94, green: 0.94, blue: 0.98), Color(red: 0.88, green: 0.89, blue: 0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview(as: .systemSmall) {
    BlackSSL()
} timeline: {
    BlackSSLEntry(date: .now, usage: nil, error: nil)
    BlackSSLEntry(date: .now, usage: BlackSSLUsageData(
        upload: 15_000_000_000,
        download: 35_000_000_000,
        total: 100_000_000_000,
        expiredAt: Int64(Date().addingTimeInterval(3600 * 24 * 10).timeIntervalSince1970),
        email: "demo@blackssl.com",
        lastUpdated: Date(),
        isLoggedIn: true,
        todayUsed: 824_100_000
    ), error: nil)
}


