// Created by Augus on 5/30/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import WidgetKit
import SwiftUI
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), usage: mockUsage, error: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), usage: BlackSSLStore.loadUsageData() ?? mockUsage, error: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Fetch new usage details in the background when requested
        BlackSSLNetworkManager.shared.fetchUsage { result in
            let latestData = BlackSSLStore.loadUsageData()
            let entry: SimpleEntry
            
            switch result {
            case .success(let data):
                entry = SimpleEntry(date: Date(), usage: data, error: nil)
            case .failure(let error):
                // If it fails, reuse last successful data, but flag the error if wanted
                entry = SimpleEntry(date: Date(), usage: latestData, error: error.localizedDescription)
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

struct SimpleEntry: TimelineEntry {
    let date: Date
    let usage: BlackSSLUsageData?
    let error: String?
}

struct BlackSSLEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            if let usage = entry.usage {
                switch family {
                case .systemSmall:
                    smallWidgetView(usage)
                case .systemMedium:
                    mediumWidgetView(usage)
                default:
                    smallWidgetView(usage)
                }
            } else {
                notConnectedView
            }
        }
    }
    
    // MARK: - Small Widget View
    private func smallWidgetView(_ usage: BlackSSLUsageData) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("BlackSSL")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                Spacer()
                
                // Expiration short warning
                Text(daysRemainingShortText(usage.expiredAt))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 0)
            
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.05), lineWidth: 5)
                Circle()
                    .trim(from: 0.0, to: CGFloat(usage.usagePercentage))
                    .stroke(
                        progressGradient(for: usage.usagePercentage),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text(String(format: "%.1f%%", usage.usagePercentage * 100))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("Used")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 65, height: 65)
            
            Spacer(minLength: 0)
            
            // Remaining Traffic text
            Text("Rem: \(BlackSSLNetworkManager.formatBytes(usage.remaining))")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Medium Widget View
    private func mediumWidgetView(_ usage: BlackSSLUsageData) -> some View {
        HStack(spacing: 32) {
            // Left Progress Block
            Button(intent: RefreshBlackSSLIntent()) {
                leftProgressBlock(usage: usage)
            }
            .buttonStyle(.plain)

            
            // Right Information Block
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("BlackSSL")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    Text("Live")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(3)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if let today = usage.todayUsed {
                        metricRow(icon: "chart.bar.fill", iconColor: .orange, label: "Today", value: BlackSSLNetworkManager.formatBytes(today))
                    }
                    if let resetText = usage.nextResetText {
                        metricRow(icon: "arrow.clockwise.circle.fill", iconColor: .purple, label: "Reset In", value: resetText)
                    }
                    metricRow(icon: "arrow.down.circle.fill", iconColor: .purple, label: "Used", value: BlackSSLNetworkManager.formatBytes(usage.used))
                    metricRow(icon: "globe.fill", iconColor: .green, label: "Total", value: BlackSSLNetworkManager.formatBytes(usage.total))
                    metricRow(icon: "calendar.badge.clock", iconColor: .orange, label: "Expires", value: formatExpirationDate(usage.expiredAt))
                    metricRow(icon: "info.circle.fill", iconColor: .secondary, label: "Status", value: expirationDaysLeftText(usage.expiredAt))
                }
            }
        }
    }
    
    // MARK: - Not Connected View
    private var notConnectedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            Text("BlackSSL")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
            Text("Open App to Connect")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Row Helper
    private func metricRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(iconColor)
                .frame(width: 14, alignment: .center)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
    
    // MARK: - Formatter Helpers
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatExpirationDate(_ timestamp: Int64?) -> String {
        guard let ts = timestamp, ts > 0 else { return "Unlimited" }
        let date = Date(timeIntervalSince1970: TimeInterval(ts))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func daysRemainingShortText(_ timestamp: Int64?) -> String {
        guard let ts = timestamp, ts > 0 else { return "Life" }
        let expirationDate = Date(timeIntervalSince1970: TimeInterval(ts))
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate)
        if let day = diff.day {
            if day < 0 {
                return "Exp"
            } else {
                return "\(day)d"
            }
        }
        return "Life"
    }
    
    private func expirationDaysLeftText(_ timestamp: Int64?) -> String {
        guard let ts = timestamp, ts > 0 else { return "Lifetime" }
        let expirationDate = Date(timeIntervalSince1970: TimeInterval(ts))
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate)
        if let day = diff.day {
            if day < 0 {
                return "Expired \(abs(day))d ago"
            } else if day == 0 {
                return "Expires today"
            } else {
                return "\(day) days left"
            }
        }
        return "Unknown"
    }

    private func leftProgressBlock(usage: BlackSSLUsageData) -> some View {
        VStack(spacing: 12) {
            Text("Updated: \(formatTime(entry.date))")
                .font(.system(size: 8))
                .foregroundColor(.secondary.opacity(0.4))

            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.05), lineWidth: 7)
                    .frame(width: 70, height: 70)
                Circle()
                    .trim(from: 0.0, to: CGFloat(usage.usagePercentage))
                    .stroke(
                        progressGradient(for: usage.usagePercentage),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text(String(format: "%.1f%%", usage.usagePercentage * 100))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("Used")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
            
            Text("\(BlackSSLNetworkManager.formatBytes(usage.remaining)) left")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.green)
        }
    }
    
    private func progressGradient(for percentage: Double) -> LinearGradient {
        let colors: [Color]
        if percentage < 0.6 {
            // Cool Blue to Teal (Safe)
            colors = [Color(red: 0.18, green: 0.49, blue: 0.96), Color(red: 0.17, green: 0.79, blue: 0.88)]
        } else if percentage < 0.85 {
            // Indigo to Pink (Warning)
            colors = [Color(red: 0.44, green: 0.32, blue: 0.94), Color(red: 0.84, green: 0.35, blue: 0.62)]
        } else {
            // Crimson to Orange (Critical)
            colors = [Color(red: 0.88, green: 0.12, blue: 0.35), Color(red: 0.98, green: 0.36, blue: 0.23)]
        }
        return LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottom
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
    SimpleEntry(date: .now, usage: nil, error: nil)
    SimpleEntry(date: .now, usage: BlackSSLUsageData(
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


