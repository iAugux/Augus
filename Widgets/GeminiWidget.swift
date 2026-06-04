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

struct GeminiEntry: TimelineEntry {
    let date: Date
    let usage: GeminiUsageData?
    let error: String?
}

struct GeminiEntryView: View {
    var entry: GeminiProvider.Entry
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
    private func smallWidgetView(_ usage: GeminiUsageData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Gemini")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                Spacer()
                
                let displayName: String = {
                    if let firstPart = usage.email.components(separatedBy: "@").first {
                        return firstPart
                    }
                    return "User"
                }()
                Text(displayName)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
            
            if usage.models.isEmpty {
                Text("No quotas")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                ForEach(usage.models.prefix(3)) { model in
                    let shortName = model.name
                        .replacingOccurrences(of: "gemini-", with: "")
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
    private func mediumWidgetView(_ usage: GeminiUsageData) -> some View {
        HStack(spacing: 16) {
            // Left progress ring for the primary model (e.g. gemini-2.5-pro or first available)
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
                HStack {
                    Text("Gemini Quota")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Spacer()
                    Text(usage.email)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Divider()
                    .background(Color.primary.opacity(0.06))
                
                if usage.models.isEmpty {
                    Text("No models registered.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(usage.models.prefix(4)) { model in
                        let nameLabel = model.name.replacingOccurrences(of: "gemini-", with: "")
                        HStack(spacing: 4) {
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
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Not Connected View
    private var notConnectedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.blue)
            Text("Gemini")
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
