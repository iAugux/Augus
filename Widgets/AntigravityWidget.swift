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

struct AntigravityEntry: TimelineEntry {
    let date: Date
    let usage: AntigravityUsageData?
    let error: String?
}

struct AntigravityEntryView: View {
    var entry: AntigravityProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            if let usage = entry.usage {
                switch family {
                case .systemLarge:
                    largeWidgetView(usage)
                default:
                    largeWidgetView(usage)
                }
            } else {
                notConnectedView
            }
        }
    }
    
    // MARK: - Small Widget View
    private func smallWidgetView(_ usage: AntigravityUsageData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if usage.models.isEmpty {
                Text("No quotas")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                ForEach(usage.models.prefix(5)) { model in
                    let shortName = model.name
                        .replacingOccurrences(of: "antigravity-", with: "")
                        .replacingOccurrences(of: "preview", with: "pv")
                    
                    VStack(alignment: .leading, spacing: 1) {
                        HStack {
                            Text(shortName)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Spacer()
                            Text(String(format: "%.0f%%", model.remainingFraction * 100))
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .foregroundColor(model.remainingFraction < 0.25 ? .red : (model.remainingFraction < 0.6 ? .orange : .blue))
                        }
                        
                        GeometryReader { geo in
                          ZStack(alignment: .leading) {
                              RoundedRectangle(cornerRadius: 1.5)
                                  .fill(Color.primary.opacity(0.05))
                                  .frame(height: 3)
                              RoundedRectangle(cornerRadius: 1.5)
                                  .fill(model.remainingFraction < 0.25 ? Color.red : (model.remainingFraction < 0.6 ? Color.orange : Color.blue))
                                  .frame(width: geo.size.width * CGFloat(model.remainingFraction), height: 3)
                          }
                        }
                        .frame(height: 3)
                    }
                    .padding(.vertical, 1)
                }
            }
            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Medium Widget View
    private func mediumWidgetView(_ usage: AntigravityUsageData) -> some View {
        HStack(spacing: 16) {
            // Left progress ring for the primary model (e.g. antigravity-2.5-pro or first available)
            let primary = usage.models.first(where: { $0.name.contains("pro") }) ?? usage.models.first
            
            if let primary = primary {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.05), lineWidth: 6)
                            .frame(width: 60, height: 60)
                        Circle()
                            .trim(from: 0.0, to: CGFloat(primary.remainingFraction))
                            .stroke(
                                primary.remainingFraction < 0.25 ? Color.red : (primary.remainingFraction < 0.6 ? Color.orange : Color.blue),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 1) {
                            Text(String(format: "%.0f%%", primary.remainingFraction * 100))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            let shortLabel: String = {
                                if primary.name.contains("pro") { return "Pro" }
                                if primary.name.contains("flash") { return "Flash" }
                                return "Model"
                            }()
                            Text(shortLabel)
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let reset = primary.resetTime {
                        Text(formatCountdown(reset))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(.blue)
                    } else {
                        Text("Active")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 70)
            }
            
            // Right detailed list of models
            VStack(alignment: .leading, spacing: 4) {
                if usage.models.isEmpty {
                    Text("No models registered.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(usage.models.prefix(5)) { model in
                        let nameLabel = model.name.replacingOccurrences(of: "antigravity-", with: "")
                        VStack(spacing: 2) {
                            HStack(spacing: 2) {
                                Text(nameLabel)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                if let reset = model.resetTime {
                                    Text(formatTime(reset))
                                        .font(.system(size: 8))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(String(format: "%.0f%%", model.remainingFraction * 100))
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(model.remainingFraction < 0.25 ? .red : (model.remainingFraction < 0.6 ? .orange : .blue))
                                    .frame(width: 30, alignment: .trailing)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(Color.primary.opacity(0.05))
                                        .frame(height: 3)
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(model.remainingFraction < 0.25 ? Color.red : (model.remainingFraction < 0.6 ? Color.orange : Color.blue))
                                        .frame(width: geo.size.width * CGFloat(model.remainingFraction), height: 3)
                                }
                            }
                            .frame(height: 3)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Large Widget View
    private func largeWidgetView(_ usage: AntigravityUsageData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if usage.models.isEmpty {
                Text("No models registered.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(usage.models.prefix(12)) { model in
                    let nameLabel = model.name.replacingOccurrences(of: "antigravity-", with: "")
                    VStack(spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(nameLabel)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if let reset = model.resetTime {
                                Text(formatTime(reset))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(String(format: "%.0f%%", model.remainingFraction * 100))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(model.remainingFraction < 0.25 ? .red : (model.remainingFraction < 0.6 ? .orange : .blue))
                                .frame(width: 40, alignment: .trailing)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color.primary.opacity(0.05))
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(model.remainingFraction < 0.25 ? Color.red : (model.remainingFraction < 0.6 ? Color.orange : Color.blue))
                                    .frame(width: geo.size.width * CGFloat(model.remainingFraction), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(8)
    }
    
    // MARK: - Not Connected View
    private var notConnectedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.blue)
            Text("Antigravity")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
            Text("Paste Token in App")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Helpers
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatCountdown(_ date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        guard diff > 0 else { return "Resetting" }
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m left"
        }
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
