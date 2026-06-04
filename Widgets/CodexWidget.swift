// Created by Augus on 6/01/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import WidgetKit
import SwiftUI

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
        let entry: CodexEntry
        if let data = latestData {
            entry = CodexEntry(date: Date(), usage: data, error: nil)
        } else {
            entry = CodexEntry(date: Date(), usage: nil, error: "Not logged in")
        }
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
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

struct CodexEntry: TimelineEntry {
    let date: Date
    let usage: CodexUsageData?
    let error: String?
}

struct CodexEntryView: View {
    var entry: CodexProvider.Entry
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
    private func smallWidgetView(_ usage: CodexUsageData) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Codex")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                Spacer()
                
                Text(usage.planType.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 0)
            
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.05), lineWidth: 5)
                let remaining = 1.0 - usage.primaryUsedPercent
                Circle()
                    .trim(from: 0.0, to: CGFloat(remaining))
                    .stroke(
                        progressGradient(for: remaining),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text(formatPercent(remaining))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("Remaining")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 65, height: 65)
            
            Spacer(minLength: 0)
            
            Text(usage.primaryResetCountdownText)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Medium Widget View
    private func mediumWidgetView(_ usage: CodexUsageData) -> some View {
        let primaryRemaining = 1.0 - usage.primaryUsedPercent
        let secondaryRemaining = 1.0 - usage.secondaryUsedPercent
        
        return HStack(spacing: 32) {
            // Left Progress Block
            VStack(spacing: 12) {
                Text("Updated: \(formatTime(entry.date))")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary.opacity(0.4))

                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.05), lineWidth: 7)
                        .frame(width: 70, height: 70)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(primaryRemaining))
                        .stroke(
                            progressGradient(for: primaryRemaining),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text(formatPercent(primaryRemaining))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("5h Left")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(usage.primaryResetCountdownText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green)
            }
            
            // Right Information Block
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Codex")
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
                    metricRow(icon: "hourglass.badge.plus", iconColor: .green, label: "5h Reset", value: usage.primaryResetCountdownText)
                    metricRow(icon: "calendar.badge.clock", iconColor: .blue, label: "7d Reset", value: usage.secondaryResetCountdownText)
                    metricRow(icon: "chart.bar.fill", iconColor: .teal, label: "7d Left", value: formatPercent(secondaryRemaining))
                    metricRow(icon: "star.fill", iconColor: .purple, label: "Plan", value: usage.planType.uppercased())
                    metricRow(icon: "envelope.fill", iconColor: .orange, label: "Account", value: usage.email)
                }
            }
        }
    }
    
    // MARK: - Not Connected View
    private var notConnectedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "cpu.fill")
                .font(.title2)
                .foregroundColor(.green)
            Text("Codex")
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
    
    // MARK: - Helpers
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatPercent(_ fraction: Double) -> String {
        let percentage = fraction * 100
        if percentage.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f%%", percentage)
        } else {
            return String(format: "%.1f%%", percentage)
        }
    }
    
    private func progressGradient(for remaining: Double) -> LinearGradient {
        let colors: [Color]
        if remaining > 0.4 {
            colors = [Color(red: 0.17, green: 0.78, blue: 0.44), Color(red: 0.18, green: 0.77, blue: 0.71)]
        } else if remaining > 0.15 {
            colors = [Color(red: 0.95, green: 0.61, blue: 0.07), Color(red: 0.90, green: 0.49, blue: 0.13)]
        } else {
            colors = [Color(red: 0.90, green: 0.30, blue: 0.26), Color(red: 0.75, green: 0.22, blue: 0.17)]
        }
        return LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottom
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
