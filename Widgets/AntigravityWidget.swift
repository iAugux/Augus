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
                case .systemSmall:
                    smallWidgetView(usage)
                case .systemMedium:
                    mediumWidgetView(usage)
                default:
                    largeWidgetView(usage)
                }
            } else {
                notConnectedView
            }
        }
    }
    // MARK: - Model Combiner (Widget Only)
    private func compactModels(_ originalModels: [AntigravityModelQuota]) -> [AntigravityModelQuota] {
        var groups: [String: [AntigravityModelQuota]] = [:]
        
        for model in originalModels {
            if model.name.localizedCaseInsensitiveContains("gpt") {
                continue
            }
            
            let key: String
            if model.name.localizedCaseInsensitiveContains("gemini") {
                if model.name.localizedCaseInsensitiveContains("pro") {
                    key = "Gemini Pro"
                } else if model.name.localizedCaseInsensitiveContains("flash") {
                    key = "Gemini Flash"
                } else {
                    key = "Gemini"
                }
            } else if model.name.localizedCaseInsensitiveContains("claude") {
                key = "Claude"
            } else {
                key = model.name
            }
            
            groups[key, default: []].append(model)
        }
        
        var combined: [AntigravityModelQuota] = []
        for (key, models) in groups {
            let avgFraction = models.map { $0.remainingFraction }.reduce(0, +) / Double(models.count)
            let earliestReset = models.compactMap { $0.resetTime }.min()
            
            combined.append(AntigravityModelQuota(name: key, remainingFraction: avgFraction, resetTime: earliestReset))
        }
        
        return combined.sorted { a, b in
            if a.remainingFraction != b.remainingFraction {
                return a.remainingFraction > b.remainingFraction
            }
            return a.name < b.name
        }
    }
    
    private func getCombinedFractions(_ models: [AntigravityModelQuota]) -> (gemini: Double, claude: Double) {
        let geminis = models.filter { $0.name.localizedCaseInsensitiveContains("Gemini") }
        let claudes = models.filter { $0.name.localizedCaseInsensitiveContains("Claude") }
        
        let geminiFrac = geminis.isEmpty ? 0 : geminis.map { $0.remainingFraction }.reduce(0, +) / Double(geminis.count)
        let claudeFrac = claudes.isEmpty ? 0 : claudes.map { $0.remainingFraction }.reduce(0, +) / Double(claudes.count)
        
        return (geminiFrac, claudeFrac)
    }

    // MARK: - Small Widget View
    private func smallWidgetView(_ usage: AntigravityUsageData) -> some View {
        VStack(spacing: 6) {
            let models = compactModels(usage.models)
            let fractions = getCombinedFractions(models)
            
            HStack(alignment: .firstTextBaseline) {
                Text("Antigravity")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Text(formatTime(entry.date))
                    .font(.system(size: 8))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            
            Spacer(minLength: 0)
            
            ZStack {
                // Outer Ring (Gemini)
                Circle()
                    .stroke(Color.primary.opacity(0.05), lineWidth: 6)
                    .frame(width: 70, height: 70)
                Circle()
                    .trim(from: 0.0, to: CGFloat(fractions.gemini))
                    .stroke(
                        antigravityGradient(for: fractions.gemini),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                
                // Inner Ring (Claude)
                Circle()
                    .stroke(Color.primary.opacity(0.05), lineWidth: 6)
                    .frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0.0, to: CGFloat(fractions.claude))
                    .stroke(
                        claudeGradient(for: fractions.claude),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 1) {
                    Text(String(format: "%.0f%%", fractions.gemini * 100))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text(String(format: "%.0f%%", fractions.claude * 100))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
            }
            
            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Medium Widget View
    private func mediumWidgetView(_ usage: AntigravityUsageData) -> some View {
        HStack(spacing: 24) {
            let models = compactModels(usage.models)
            let fractions = getCombinedFractions(models)
            
            // Left Progress Block
            VStack(spacing: 8) {
                Text("Updated: \(formatTime(entry.date))")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary.opacity(0.4))
                    
                concentricRingsView(fractions: fractions, outerSize: 76, innerSize: 56, lineWidth: 7, showText: true)
                
                Text("Gemini & Claude")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)
            
            // Right detailed list of models
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Antigravity")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                if models.isEmpty {
                    Text("No models registered.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(models.prefix(4)) { model in
                            modelRow(model: model, size: 11)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Large Widget View
    private func largeWidgetView(_ usage: AntigravityUsageData) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            let uncombinedModels = usage.models.filter { 
                $0.name.localizedCaseInsensitiveContains("gemini") || $0.name.localizedCaseInsensitiveContains("claude") 
            }.sorted { a, b in
                if a.remainingFraction != b.remainingFraction {
                    return a.remainingFraction > b.remainingFraction
                }
                return a.name < b.name
            }
            let fractions = getCombinedFractions(uncombinedModels)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Updated: \(formatTime(entry.date))")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary.opacity(0.4))
                
                HStack(alignment: .center, spacing: 16) {
                    concentricRingsView(fractions: fractions, outerSize: 48, innerSize: 34, lineWidth: 5, showText: true)
                    
                    Text("Antigravity")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
            }
            
            if uncombinedModels.isEmpty {
                Text("No models registered.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(uncombinedModels.prefix(12)) { model in
                        modelRow(model: model, size: 14)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
    
    // MARK: - UI Helpers
    
    @ViewBuilder
    private func concentricRingsView(fractions: (gemini: Double, claude: Double), outerSize: CGFloat, innerSize: CGFloat, lineWidth: CGFloat, showText: Bool) -> some View {
        ZStack {
            // Outer Ring (Gemini)
            Circle()
                .stroke(Color.primary.opacity(0.05), lineWidth: lineWidth)
                .frame(width: outerSize, height: outerSize)
            Circle()
                .trim(from: 0.0, to: CGFloat(fractions.gemini))
                .stroke(
                    antigravityGradient(for: fractions.gemini),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: outerSize, height: outerSize)
                .rotationEffect(.degrees(-90))
            
            // Inner Ring (Claude)
            Circle()
                .stroke(Color.primary.opacity(0.05), lineWidth: lineWidth)
                .frame(width: innerSize, height: innerSize)
            Circle()
                .trim(from: 0.0, to: CGFloat(fractions.claude))
                .stroke(
                    claudeGradient(for: fractions.claude),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: innerSize, height: innerSize)
                .rotationEffect(.degrees(-90))
            
            if showText {
                VStack(spacing: 1) {
                    Text(String(format: "%.0f%%", fractions.gemini * 100))
                        .font(.system(size: outerSize * 0.18, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text(String(format: "%.0f%%", fractions.claude * 100))
                        .font(.system(size: innerSize * 0.2, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 217/255.0, green: 119/255.0, blue: 87/255.0))
                }
            }
        }
    }
    
    private func modelRow(model: AntigravityModelQuota, size: CGFloat) -> some View {
        HStack(spacing: 8) {
            let isClaude = model.name.localizedCaseInsensitiveContains("claude")
            let isGemini = model.name.localizedCaseInsensitiveContains("gemini")
            let iconColor: Color = {
                if model.name.localizedCaseInsensitiveContains("pro") { return .blue }
                if model.name.localizedCaseInsensitiveContains("flash") { return .teal }
                if isClaude { return Color(red: 217/255.0, green: 119/255.0, blue: 87/255.0) }
                return .gray
            }()
            
            if isClaude || isGemini {
                Image(isClaude ? .claude : .gemini)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(iconColor)
                    .frame(width: size + 4, height: size + 4, alignment: .center)
            } else {
                Image(systemName: "cpu")
                    .font(.system(size: size))
                    .foregroundColor(iconColor)
                    .frame(width: size + 4, alignment: .center)
            }
            
            let cleanName = model.name
                .replacingOccurrences(of: "antigravity-", with: "")
            
            Text(cleanName)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(String(format: "%.0f%%", model.remainingFraction * 100))
                .font(.system(size: size, weight: .bold, design: .rounded))
                .foregroundColor(model.remainingFraction < 0.25 ? .red : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
    
    private func antigravityGradient(for fraction: Double) -> LinearGradient {
        let colors: [Color]
        if fraction > 0.4 {
            colors = [Color.blue, Color(red: 0.4, green: 0.7, blue: 1.0)]
        } else if fraction > 0.15 {
            colors = [Color.orange, Color.yellow]
        } else {
            colors = [Color.red, Color(red: 0.9, green: 0.4, blue: 0.4)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    private func claudeGradient(for fraction: Double) -> LinearGradient {
        let colors: [Color]
        if fraction > 0.4 {
            colors = [Color.orange, Color.yellow]
        } else if fraction > 0.15 {
            colors = [Color(red: 0.95, green: 0.5, blue: 0.1), Color(red: 0.8, green: 0.3, blue: 0.1)]
        } else {
            colors = [Color.red, Color(red: 0.8, green: 0.2, blue: 0.2)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
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
