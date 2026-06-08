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
        HStack(spacing: 32) {
            // Left progress ring for the primary model (e.g. gemini-2.5-pro or first available)
            let primary = usage.models.first(where: { $0.name.contains("pro") }) ?? usage.models.first
            
            if let primary = primary {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.05), lineWidth: 7)
                            .frame(width: 70, height: 70)
                        Circle()
                            .trim(from: 0.0, to: CGFloat(primary.remainingFraction))
                            .stroke(
                                primary.remainingFraction < 0.25 ? Color.red : (primary.remainingFraction < 0.6 ? Color.orange : Color.blue),
                                style: StrokeStyle(lineWidth: 7, lineCap: .round)
                            )
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text(String(format: "%.0f%%", primary.remainingFraction * 100))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
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
                    
                    if let reset = primary.resetTime, reset > Date() {
                        Text(formatCountdownTime(reset))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.blue)
                    } else {
                        Text("Active")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 70)
            }
            
            // Right detailed list of models and info
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Gemini")
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
                
                VStack(alignment: .leading, spacing: 4) {
                    if usage.models.isEmpty {
                        Text("No models registered.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(usage.models.prefix(4)) { model in
                            modelRow(model: model, size: 11)
                        }
                        accountRow(email: usage.email, size: 11)
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

