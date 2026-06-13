import SwiftUI
import WidgetKit
import AppIntents

struct GeminiEntry: TimelineEntry {
    let date: Date
    let usage: GeminiUsageData?
    let error: String?
}

struct GeminiEntryView: View {
    var entry: GeminiEntry
    var overrideFamily: WidgetFamily? = nil
    var isMenuBar: Bool = false
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            if let usage = entry.usage {
                switch overrideFamily ?? family {
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
    
    // MARK: - Model Combiner (Widget Only)
    private func compactModels(_ originalModels: [GeminiModelQuota]) -> [GeminiModelQuota] {
        var groups: [String: [GeminiModelQuota]] = [:]
        
        for model in originalModels {
            let key: String
            if model.name.localizedCaseInsensitiveContains("pro") {
                key = "Gemini Pro"
            } else if model.name.localizedCaseInsensitiveContains("flash") {
                key = "Gemini Flash"
            } else {
                key = model.name
            }
            
            groups[key, default: []].append(model)
        }
        
        var combined: [GeminiModelQuota] = []
        for (key, models) in groups {
            let avgFraction = models.map { $0.remainingFraction }.reduce(0, +) / Double(models.count)
            let earliestReset = models.compactMap { $0.resetTime }.min()
            
            combined.append(GeminiModelQuota(name: key, remainingFraction: avgFraction, resetTime: earliestReset))
        }
        
        return combined.sorted { a, b in
            if a.remainingFraction != b.remainingFraction {
                return a.remainingFraction > b.remainingFraction
            }
            return a.name < b.name
        }
    }
    
    private func getCombinedFractions(_ models: [GeminiModelQuota]) -> (pro: Double, flash: Double) {
        let pros = models.filter { $0.name.localizedCaseInsensitiveContains("pro") || $0.name == "Gemini Pro" }
        let flashes = models.filter { $0.name.localizedCaseInsensitiveContains("flash") || $0.name == "Gemini Flash" }
        
        let proFrac = pros.isEmpty ? 0 : pros.map { $0.remainingFraction }.reduce(0, +) / Double(pros.count)
        let flashFrac = flashes.isEmpty ? 0 : flashes.map { $0.remainingFraction }.reduce(0, +) / Double(flashes.count)
        
        return (proFrac, flashFrac)
    }

    // MARK: - Small Widget View
    private func smallWidgetView(_ usage: GeminiUsageData) -> some View {
        VStack(spacing: 6) {
            let models = compactModels(usage.models)
            let fractions = getCombinedFractions(models)
            
            HStack(alignment: .firstTextBaseline) {
                Text("Gemini")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Text(formatTime(entry.date))
                    .font(.system(size: 8))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            
            Spacer(minLength: 0)
            
            ZStack {
                // Outer Ring (Pro)
                Circle()
                    .stroke(Color.primary.opacity(0.05), lineWidth: 5)
                    .frame(width: 65, height: 65)
                Circle()
                    .trim(from: 0.0, to: CGFloat(fractions.pro))
                    .stroke(
                        proGradient(for: fractions.pro),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 65, height: 65)
                    .rotationEffect(.degrees(-90))
                
                // Inner Ring (Flash)
                Circle()
                    .stroke(Color.primary.opacity(0.05), lineWidth: 5)
                    .frame(width: 47, height: 47)
                Circle()
                    .trim(from: 0.0, to: CGFloat(fractions.flash))
                    .stroke(
                        flashGradient(for: fractions.flash),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 47, height: 47)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 1) {
                    Text(String(format: "%.0f%%", fractions.pro * 100))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text(String(format: "%.0f%%", fractions.flash * 100))
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.teal)
                }
            }
            
            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Medium Widget View
    private func mediumWidgetView(_ usage: GeminiUsageData) -> some View {
        HStack(spacing: 32) {
            let models = compactModels(usage.models)
            let fractions = getCombinedFractions(models)
            
            // Left Progress Block
            VStack(spacing: 8) {
                if !isMenuBar {
                    Text("Updated: \(formatTime(entry.date))")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                    
                concentricRingsView(fractions: fractions, outerSize: 70, innerSize: 50, lineWidth: 7, showText: true)
                
                let earliestResetModel = models
                    .filter { if let r = $0.resetTime { return r > Date() } else { return false } }
                    .min(by: { $0.resetTime! < $1.resetTime! })
                
                if let model = earliestResetModel, let reset = model.resetTime {
                    let isFlash = model.name.localizedCaseInsensitiveContains("flash")
                    let textColor: Color = isFlash ? .teal : .blue
                    Text(formatCountdown(reset))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(textColor)
                } else {
                    Text("Active")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 70)
            
            // Right detailed list of models
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Gemini")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
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

    @ViewBuilder
    private func concentricRingsView(fractions: (pro: Double, flash: Double), outerSize: CGFloat, innerSize: CGFloat, lineWidth: CGFloat, showText: Bool) -> some View {
        ZStack {
            // Outer Ring (Pro)
            Circle()
                .stroke(Color.primary.opacity(0.05), lineWidth: lineWidth)
                .frame(width: outerSize, height: outerSize)
            Circle()
                .trim(from: 0.0, to: CGFloat(fractions.pro))
                .stroke(
                    proGradient(for: fractions.pro),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: outerSize, height: outerSize)
                .rotationEffect(.degrees(-90))
            
            // Inner Ring (Flash)
            Circle()
                .stroke(Color.primary.opacity(0.05), lineWidth: lineWidth)
                .frame(width: innerSize, height: innerSize)
            Circle()
                .trim(from: 0.0, to: CGFloat(fractions.flash))
                .stroke(
                    flashGradient(for: fractions.flash),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: innerSize, height: innerSize)
                .rotationEffect(.degrees(-90))
            
            if showText {
                VStack(spacing: 1) {
                    Text(String(format: "%.0f%%", fractions.pro * 100))
                        .font(.system(size: outerSize * 0.18, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text(String(format: "%.0f%%", fractions.flash * 100))
                        .font(.system(size: innerSize * 0.2, weight: .bold, design: .rounded))
                        .foregroundColor(.teal)
                }
            }
        }
    }

    private func proGradient(for fraction: Double) -> LinearGradient {
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
    
    private func flashGradient(for fraction: Double) -> LinearGradient {
        let colors: [Color]
        if fraction > 0.4 {
            colors = [Color.teal, Color(red: 0.4, green: 0.9, blue: 0.9)]
        } else if fraction > 0.15 {
            colors = [Color.orange, Color.yellow]
        } else {
            colors = [Color.red, Color(red: 0.9, green: 0.4, blue: 0.4)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
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
    private func modelRow(model: GeminiModelQuota, size: CGFloat) -> some View {
        HStack(spacing: 8) {
            let isPro = model.name.localizedCaseInsensitiveContains("pro")
            let iconColor: Color = isPro ? .blue : .teal
            
            Image(systemName: isPro ? "sparkles" : "circle.hexagongrid.fill")
                .font(.system(size: size))
                .foregroundColor(iconColor)
                .frame(width: size + 4, alignment: .center)
            
            let cleanName = model.name
                .replacingOccurrences(of: "gemini-", with: "")
                .replacingOccurrences(of: "-preview", with: "-pv")
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(cleanName)
                    .font(.system(size: size, weight: .medium))
                    .foregroundColor(.secondary)
                
                if let resetTime = model.resetTime, resetTime > Date() {
                    Text("(\(formatCountdownTime(resetTime)))")
                        .font(.system(size: size - 1, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            
            Spacer()
            
            Text(String(format: "%.0f%%", model.remainingFraction * 100))
                .font(.system(size: size, weight: .bold, design: .rounded))
                .foregroundColor(model.remainingFraction < 0.25 ? .red : (model.remainingFraction < 0.6 ? .orange : .blue))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
    
    private func accountRow(email: String, size: CGFloat) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "envelope.fill")
                .font(.system(size: size))
                .foregroundColor(.orange)
                .frame(width: size + 4, alignment: .center)
            
            Text("Account")
                .font(.system(size: size))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(email)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatCountdownTime(_ date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        guard diff > 0 else { return "0m" }
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
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

