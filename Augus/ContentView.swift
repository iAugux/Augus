// Created by Augus on 5/30/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI
import UserNotifications

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var usageData: BlackSSLUsageData? = BlackSSLStore.loadUsageData()
    @State private var codexData: CodexUsageData? = CodexStore.loadUsageData()
    @State private var geminiData: GeminiUsageData? = GeminiStore.loadUsageData()
#if os(macOS)
    @State private var antigravityData: AntigravityUsageData? = AntigravityStore.loadUsageData()
#endif
    @State private var selectedTab: ServiceTab = .blackssl
    @State private var isShowingBlackSSLLogin = false
    @State private var isShowingCodexLogin = false
    @State private var isRefreshing = false
    @State private var errorMessage: String? = nil
    @State private var isShowingDebugAlert = false
    @State private var debugText = ""
    @State private var manualCookieInput = ""
    @State private var manualPortInput = ""
    @State private var manualTokenInput = ""
    @State private var notificationDelegate = NotificationDelegate()
    
    enum ServiceTab: String, CaseIterable, Identifiable {
        case blackssl = "BlackSSL"
        case codex = "Codex"
        case gemini = "Gemini"
#if os(macOS)
        case antigravity = "Antigravity"
#endif
        
        var id: String { rawValue }
        
        var tintColor: Color {
            switch self {
            case .blackssl:
                return .blue
            case .codex:
                return Color(red: 0x8C / 255.0, green: 0xA0 / 255.0, blue: 1.0)
            case .gemini:
                return Color(red: 0x3D / 255.0, green: 0x8D / 255.0, blue: 0xF6 / 255.0)
#if os(macOS)
            case .antigravity:
                return Color(red: 0x3D / 255.0, green: 0x8D / 255.0, blue: 0xF6 / 255.0)
#endif
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            blacksslTabContent
                .tabItem {
                    Label("BlackSSL", systemImage: "globe.asia.australia.fill")
                }
                .tag(ServiceTab.blackssl)
            
            codexTabContent
                .tabItem {
                    Label("Codex", image: .codex)
                }
                .tag(ServiceTab.codex)

#if os(macOS)
            antigravityTabContent
                .tabItem {
                    Label("Antigravity", image: .antigravity)
                }
                .tag(ServiceTab.antigravity)
#endif

            geminiTabContent
                .tabItem {
                    Label("Gemini", image: .gemini)
                }
                .tag(ServiceTab.gemini)
        }
        .tint(selectedTab.tintColor)
        .onChange(of: selectedTab) {
            errorMessage = nil
        }
        .onOpenURL { url in
            handleOpenURL(url)
        }
        .sheet(isPresented: $isShowingBlackSSLLogin) {
            blacksslWebViewSheet
        }
        .sheet(isPresented: $isShowingCodexLogin) {
            codexWebViewSheet
        }
        .alert("Scrape Diagnostics", isPresented: $isShowingDebugAlert) {
            Button("Copy Log") {
                copyToPasteboard(debugText)
            }
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text(debugText)
        }
        .onAppear {
            UNUserNotificationCenter.current().delegate = notificationDelegate
            
            // Auto refresh on open
            if usageData != nil {
                refreshData()
            }
            if codexData != nil {
                refreshCodexData()
            }
            if geminiData != nil {
                refreshGeminiData()
            }
#if os(macOS)
            if antigravityData != nil {
                refreshAntigravityData()
            }
#endif
            
            // Request local notification permissions
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                } else {
                    print("Notification permission granted: \(granted)")
                }
            }
        }
    }
    
    // MARK: - Tab Contents
    private var blacksslTabContent: some View {
        ZStack {
            if colorScheme == .dark {
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
            } else {
                Color(red: 0.94, green: 0.94, blue: 0.98)
                    .ignoresSafeArea()
            }
            
            // Glowing neon blobs
            glowingBlobs
            
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    
                    if let data = usageData {
                        dashboardView(data: data)
                    } else {
                        loginWelcomeView
                    }
                }
                .padding()
            }
        }
    }
    
    private var codexTabContent: some View {
        ZStack {
            if colorScheme == .dark {
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
            } else {
                Color(red: 0.94, green: 0.94, blue: 0.98)
                    .ignoresSafeArea()
            }
            
            // Glowing neon blobs
            glowingBlobs
            
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    
                    if let data = codexData {
                        codexDashboardView(data: data)
                    } else {
                        codexWelcomeView
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Background Blobs
    private var glowingBlobs: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(colorScheme == .dark ? 0.15 : 0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -120, y: -200)
            
            Circle()
                .fill(Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.08))
                .frame(width: 350, height: 350)
                .blur(radius: 90)
                .offset(x: 120, y: 150)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedTab == .blackssl ? "BlackSSL" : (selectedTab == .codex ? "Codex" : (selectedTab == .gemini ? "Gemini" : "Antigravity")))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                switch selectedTab {
                case .blackssl:
                    if let data = usageData {
                        Text(data.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Dashboard Widget Monitor")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                case .codex:
                    if let data = codexData {
                        Text(data.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Codex Rate Limit Monitor")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                case .gemini:
                    if let data = geminiData {
                        Text(data.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Google Gemini Quota Monitor")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
#if os(macOS)
                case .antigravity:
                    if let data = antigravityData {
                        Text(data.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Antigravity Monitor")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
#endif
                }
            }
            
            Spacer()
            
            // Status Dot Indicator
            let isConnected: Bool = {
                switch selectedTab {
                case .blackssl: return usageData != nil
                case .codex: return codexData != nil
                case .gemini: return geminiData != nil
#if os(macOS)
                case .antigravity: return antigravityData != nil
#endif
                }
            }()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(isConnected ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                
                Text(isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isConnected ? .green : .orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isConnected ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
            )
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Welcome View
    private var loginWelcomeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "globe.asia.australia.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .purple.opacity(0.5), radius: 15, x: 0, y: 5)
                .padding(.top, 40)
                .onTapGesture(count: 2) {
                    debugText = BlackSSLStore.loadLastScrapeResult()
                    isShowingDebugAlert = true
                }
            
            VStack(spacing: 8) {
                Text("Monitor Your Traffic")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Log in to BlackSSL via web. We will safely capture your session to update the Widget dynamically.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button {
                isShowingBlackSSLLogin = true
            } label: {
                HStack {
                    Text("Sign In via Web")
                        .fontWeight(.semibold)
                    Image(systemName: "safari.fill")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, errorMessage == nil ? 20 : 0)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
        .padding()
        .background(
            VisualEffectView()
                .clipShape(RoundedRectangle(cornerRadius: 24))
        )
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color(white: 0.1).opacity(0.4) : Color(white: 0.9).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(.top, 30)
    }
    
    // MARK: - Codex Welcome View
    private var codexWelcomeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green, Color.teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .green.opacity(0.5), radius: 15, x: 0, y: 5)
                .padding(.top, 40)
                .onTapGesture(count: 2) {
                    debugText = CodexStore.loadLastScrapeResult()
                    isShowingDebugAlert = true
                }
            
            VStack(spacing: 8) {
                Text("Monitor Codex")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Log in to Codex via web. We will safely capture your session to update the Widget dynamically.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button {
                isShowingCodexLogin = true
            } label: {
                HStack {
                    Text("Sign In to Codex")
                        .fontWeight(.semibold)
                    Image(systemName: "safari.fill")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.green, .teal],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 4)
            }
            .padding(.horizontal, 16)
            
            // OR Separator
            HStack {
                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 1)
                Text("OR")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fontWeight(.bold)
                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 1)
            }
            .padding(.horizontal, 16)
            
            // Manual Cookie Input Area
            VStack(alignment: .leading, spacing: 8) {
                Text("Developer Fallback (Manual)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                TextField("Paste Codex Cookie string here...", text: $manualCookieInput)
                    .padding(10)
                    .background(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95))
                    .cornerRadius(8)
                    .font(.system(size: 11, design: .monospaced))
                    .autocorrectionDisabled(true)
                    .disableAutocapitalizationIfNeeded()
                
                Button {
                    if !manualCookieInput.isEmpty {
                        CodexStore.saveCookieHeader(manualCookieInput)
                        manualCookieInput = ""
                        refreshCodexData()
                    }
                } label: {
                    Text("Save & Connect")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, errorMessage == nil ? 20 : 0)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
        .padding()
        .background(
            VisualEffectView()
                .clipShape(RoundedRectangle(cornerRadius: 24))
        )
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color(white: 0.1).opacity(0.4) : Color(white: 0.9).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(.top, 30)
    }
    
    // MARK: - Codex Dashboard View
    @ViewBuilder
    private func codexDashboardView(data: CodexUsageData) -> some View {
        VStack(spacing: 24) {
            // Circular Progress Card
            VStack {
                ZStack {
                    // Outer Ring Track
                    Circle()
                        .stroke(Color.primary.opacity(0.06), lineWidth: 14)
                        .frame(width: 130, height: 130)
                    
                    // Usage Progress Ring
                    let primaryRemaining = 1.0 - data.primaryUsedPercent
                    Circle()
                        .trim(from: 0.0, to: CGFloat(primaryRemaining))
                        .stroke(
                            codexProgressGradient(for: primaryRemaining),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.8), value: primaryRemaining)
                        .shadow(color: codexProgressShadowColor(for: primaryRemaining).opacity(0.25), radius: 8, x: 0, y: 4)
                    
                    // Inside Circle Texts
                    VStack(spacing: 2) {
                        Text(formatCodexPercent(primaryRemaining))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("5h Remaining")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 14)
                
                // Texts Below Progress Ring
                HStack(spacing: 40) {
                    VStack(alignment: .center) {
                        let primaryRemaining = 1.0 - data.primaryUsedPercent
                        Text(formatCodexPercent(primaryRemaining))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("5h Remaining")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .center) {
                        let secondaryRemaining = 1.0 - data.secondaryUsedPercent
                        Text(formatCodexPercent(secondaryRemaining))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("7d Remaining")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                VisualEffectView()
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            )
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color(white: 0.1).opacity(0.4) : Color(white: 0.9).opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            
            // Detailed Breakdown Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Codex Limits")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                    .onTapGesture(count: 2) {
                        debugText = CodexStore.loadLastScrapeResult()
                        isShowingDebugAlert = true
                    }
                
                detailRow(title: "5h Reset Count", value: data.primaryResetCountdownText, icon: "hourglass.badge.plus", color: .green)
                detailRow(title: "7d Reset Count", value: data.secondaryResetCountdownText, icon: "calendar.badge.clock", color: .blue)
                detailRow(title: "Plan Type", value: data.planType.uppercased(), icon: "star.circle.fill", color: .purple)
                
                Divider()
                    .background(Color.primary.opacity(0.08))
                
                detailRow(
                    title: "Last Scraped",
                    value: formatLastScrapedDate(data.lastUpdated),
                    icon: "arrow.clockwise.circle.fill",
                    color: .orange
                )
            }
            .padding()
            .background(
                VisualEffectView()
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            )
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color(white: 0.1).opacity(0.4) : Color(white: 0.9).opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            
            // Action Buttons
            HStack(spacing: 16) {
                Button {
                    refreshCodexData()
                } label: {
                    HStack {
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh")
                    }
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(14)
                }
                .disabled(isRefreshing)
                
                Button {
                    CodexStore.clear()
                    codexData = nil
                } label: {
                    Text("Disconnect")
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(14)
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 5)
            }
        }
    }
    
    // MARK: - Dashboard View
    @ViewBuilder
    private func dashboardView(data: BlackSSLUsageData) -> some View {
        VStack(spacing: 24) {
            // Circular Progress Card
            VStack {
                ZStack {
                    // Outer Ring Track
                    Circle()
                        .stroke(Color.primary.opacity(0.06), lineWidth: 14)
                        .frame(width: 130, height: 130)
                    
                    // Usage Progress Ring
                    Circle()
                        .trim(from: 0.0, to: CGFloat(data.usagePercentage))
                        .stroke(
                            progressGradient(for: data.usagePercentage),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.8), value: data.usagePercentage)
                        .shadow(color: progressShadowColor(for: data.usagePercentage).opacity(0.25), radius: 8, x: 0, y: 4)
                    
                    // Inside Circle Texts
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f%%", data.usagePercentage * 100))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Used")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 14)
                
                // Texts Below Progress Ring
                HStack(spacing: 40) {
                    VStack(alignment: .center) {
                        Text(BlackSSLNetworkManager.formatBytes(data.used))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Used Total")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .center) {
                        Text(BlackSSLNetworkManager.formatBytes(data.total))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Total Quota")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                VisualEffectView()
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            )
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color(white: 0.1).opacity(0.4) : Color(white: 0.9).opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            
            // Detailed Breakdown Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Usage Statistics")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                    .onTapGesture(count: 2) {
                        debugText = BlackSSLStore.loadLastScrapeResult()
                        isShowingDebugAlert = true
                    }
                
                if let today = data.todayUsed {
                    detailRow(title: "Today's Usage", value: BlackSSLNetworkManager.formatBytes(today), icon: "chart.bar.fill", color: .orange)
                }
                if let resetText = data.nextResetText {
                    detailRow(title: "Next Reset", value: resetText, icon: "arrow.clockwise.circle.fill", color: .purple)
                }
                
                detailRow(title: "Upload Data", value: BlackSSLNetworkManager.formatBytes(data.upload), icon: "arrow.up.circle.fill", color: .blue)
                detailRow(title: "Download Data", value: BlackSSLNetworkManager.formatBytes(data.download), icon: "arrow.down.circle.fill", color: .purple)
                detailRow(title: "Remaining Quota", value: BlackSSLNetworkManager.formatBytes(data.remaining), icon: "bolt.circle.fill", color: .green)
                
                Divider()
                    .background(Color.primary.opacity(0.08))
                
                detailRow(
                    title: "Expiration",
                    value: formatExpirationDate(data.expiredAt),
                    icon: "calendar.badge.clock",
                    color: .orange
                )
                
                detailRow(
                    title: "Status",
                    value: expirationDaysLeftText(data.expiredAt),
                    icon: "info.circle.fill",
                    color: .secondary
                )
            }
            .padding()
            .background(
                VisualEffectView()
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            )
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color(white: 0.1).opacity(0.4) : Color(white: 0.9).opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            
            // Action Buttons
            HStack(spacing: 16) {
                Button {
                    refreshData()
                } label: {
                    HStack {
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh")
                    }
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(14)
                }
                .disabled(isRefreshing)
                
                Button {
                    BlackSSLStore.clear()
                    usageData = nil
                } label: {
                    Text("Disconnect")
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(14)
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 5)
            }
        }
    }
    
    private func detailRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.primary)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Login WebView Sheets
    private var blacksslWebViewSheet: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Button("Cancel") {
                    isShowingBlackSSLLogin = false
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Text("Sign In BlackSSL")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Done") {
                    isShowingBlackSSLLogin = false
                    refreshData()
                }
                .foregroundColor(.blue)
                .fontWeight(.bold)
            }
            .padding()
            .background(colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.15) : Color(red: 0.95, green: 0.95, blue: 0.97))
            
            WebView(url: URL(string: "https://blackssl.com/dashboard")!) { cookies, localStorage, host in
                if !cookies.isEmpty {
                    BlackSSLStore.saveCookies(cookies)
                }
                if !localStorage.isEmpty {
                    BlackSSLStore.saveLocalStorage(localStorage)
                }
                BlackSSLStore.saveBaseHost(host)
                print("BlackSSL Cookies captured: \(cookies.count)")
            }
        }
#if os(macOS)
        .frame(minWidth: 500, minHeight: 600)
#endif
    }
    
    private var codexWebViewSheet: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Button("Cancel") {
                    isShowingCodexLogin = false
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Text("Sign In Codex")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Done") {
                    isShowingCodexLogin = false
                    refreshCodexData()
                }
                .foregroundColor(.blue)
                .fontWeight(.bold)
            }
            .padding()
            .background(colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.15) : Color(red: 0.95, green: 0.95, blue: 0.97))
            
            WebView(url: URL(string: "https://chatgpt.com/")!) { cookies, localStorage, host in
                if !cookies.isEmpty {
                    CodexStore.saveCookies(cookies)
                }
                if !localStorage.isEmpty {
                    CodexStore.saveLocalStorage(localStorage)
                }
                print("Codex Cookies captured: \(cookies.count)")
            }
        }
#if os(macOS)
        .frame(minWidth: 500, minHeight: 600)
#endif
    }
    
    // MARK: - Actions & Helpers
    private func handleOpenURL(_ url: URL) {
        guard url.scheme == "augus" else { return }
        switch url.host {
        case "blackssl":
            isShowingBlackSSLLogin = false
            isShowingCodexLogin = false
            selectedTab = .blackssl
        case "codex":
            isShowingBlackSSLLogin = false
            isShowingCodexLogin = false
            selectedTab = .codex
        case "gemini":
            isShowingBlackSSLLogin = false
            isShowingCodexLogin = false
            selectedTab = .gemini
        default:
            break
        }
    }
    
    private func copyToPasteboard(_ text: String) {
#if os(iOS)
        UIPasteboard.general.string = text
#endif
    }
    
    private func refreshData() {
        isRefreshing = true
        errorMessage = nil
        BlackSSLNetworkManager.shared.fetchUsage { result in
            DispatchQueue.main.async {
                isRefreshing = false
                switch result {
                case .success(let data):
                    self.usageData = data
                case .failure(let error):
                    self.errorMessage = "Failed to update BlackSSL: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func refreshCodexData() {
        isRefreshing = true
        errorMessage = nil
        CodexNetworkManager.shared.fetchUsage { result in
            DispatchQueue.main.async {
                isRefreshing = false
                switch result {
                case .success(let data):
                    self.codexData = data
                case .failure(let error):
                    self.errorMessage = "Failed to update Codex: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func formatExpirationDate(_ timestamp: Int64?) -> String {
        guard let ts = timestamp, ts > 0 else { return "Unlimited" }
        let date = Date(timeIntervalSince1970: TimeInterval(ts))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatLastScrapedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func expirationDaysLeftText(_ timestamp: Int64?) -> String {
        guard let ts = timestamp, ts > 0 else { return "Lifetime Plan" }
        let expirationDate = Date(timeIntervalSince1970: TimeInterval(ts))
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate)
        if let day = diff.day {
            if day < 0 {
                return "Expired \(abs(day)) days ago"
            } else if day == 0 {
                return "Expires today"
            } else {
                return "\(day) days remaining"
            }
        }
        return "Unknown"
    }
    
    private func progressGradient(for percentage: Double) -> LinearGradient {
        let colors: [Color]
        if percentage < 0.6 {
            colors = [Color(red: 0.18, green: 0.49, blue: 0.96), Color(red: 0.17, green: 0.79, blue: 0.88)]
        } else if percentage < 0.85 {
            colors = [Color(red: 0.44, green: 0.32, blue: 0.94), Color(red: 0.84, green: 0.35, blue: 0.62)]
        } else {
            colors = [Color(red: 0.88, green: 0.12, blue: 0.35), Color(red: 0.98, green: 0.36, blue: 0.23)]
        }
        return LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func progressShadowColor(for percentage: Double) -> Color {
        if percentage < 0.6 {
            return Color(red: 0.18, green: 0.49, blue: 0.96)
        } else if percentage < 0.85 {
            return Color(red: 0.44, green: 0.32, blue: 0.94)
        } else {
            return Color(red: 0.88, green: 0.12, blue: 0.35)
        }
    }
    
    private func codexProgressGradient(for remaining: Double) -> LinearGradient {
        let colors: [Color]
        if remaining > 0.4 {
            // Cool Green to Teal (Safe)
            colors = [Color(red: 0.17, green: 0.78, blue: 0.44), Color(red: 0.18, green: 0.77, blue: 0.71)]
        } else if remaining > 0.15 {
            // Yellow to Orange (Warning)
            colors = [Color(red: 0.95, green: 0.61, blue: 0.07), Color(red: 0.90, green: 0.49, blue: 0.13)]
        } else {
            // Orange to Red (Critical)
            colors = [Color(red: 0.90, green: 0.30, blue: 0.26), Color(red: 0.75, green: 0.22, blue: 0.17)]
        }
        return LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func codexProgressShadowColor(for remaining: Double) -> Color {
        if remaining > 0.4 {
            return Color(red: 0.17, green: 0.78, blue: 0.44)
        } else if remaining > 0.15 {
            return Color(red: 0.95, green: 0.61, blue: 0.07)
        } else {
            return Color(red: 0.90, green: 0.30, blue: 0.26)
        }
    }
    
    private func formatCodexPercent(_ fraction: Double) -> String {
        let percentage = fraction * 100
        if percentage.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f%%", percentage)
        } else {
            return String(format: "%.1f%%", percentage)
        }
    }
    
    // MARK: - Gemini Views & Helpers
    private var geminiTabContent: some View {
        ZStack {
            if colorScheme == .dark {
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
            } else {
                Color(red: 0.94, green: 0.94, blue: 0.98)
                    .ignoresSafeArea()
            }
            
            glowingBlobs
            
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    
                    if let data = geminiData {
                        geminiDashboardView(data: data)
                    } else {
                        geminiWelcomeView
                    }
                }
                .padding()
            }
        }
    }
    
    private var geminiWelcomeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.5), radius: 15, x: 0, y: 5)
                .padding(.top, 40)
                .onTapGesture(count: 2) {
                    debugText = GeminiStore.loadLastLog()
                    isShowingDebugAlert = true
                }
            
            VStack(spacing: 8) {
                Text("Monitor Gemini Quota")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
#if os(macOS)
                Text("Connect to Gemini using ~/.gemini/oauth_creds.json on your Mac.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
#else
                Text("Copy the raw JSON contents of ~/.gemini/oauth_creds.json on your Mac and paste it below.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
#endif
            }
            
            VStack(alignment: .leading, spacing: 12) {
#if !os(macOS)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Token JSON Credentials")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .topLeading) {
                        if manualTokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Paste raw oauth_creds.json here...")
                                .foregroundColor(.secondary.opacity(0.4))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .font(.system(size: 11, design: .monospaced))
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: $manualTokenInput)
                            .frame(height: 120)
                            .font(.system(size: 11, design: .monospaced))
                            .autocorrectionDisabled(true)
                            .disableAutocapitalizationIfNeeded()
                            .padding(6)
                            .background(Color.clear)
                    }
                    .background(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
#endif
                
                Button {
#if os(macOS)
                    let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".gemini/oauth_creds.json")
                    do {
                        let rawData = try Data(contentsOf: fileURL)
                        let creds = try JSONDecoder().decode(GeminiOAuthCreds.self, from: rawData)
                        GeminiStore.saveOAuthCreds(creds)
                        errorMessage = nil
                        refreshGeminiData()
                    } catch {
                        errorMessage = "Error reading ~/.gemini/oauth_creds.json: \(error.localizedDescription)"
                    }
#else
                    guard !manualTokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        errorMessage = "Please paste your JSON credentials first."
                        return
                    }
                    
                    if let rawData = manualTokenInput.data(using: .utf8) {
                        do {
                            let creds = try JSONDecoder().decode(GeminiOAuthCreds.self, from: rawData)
                            GeminiStore.saveOAuthCreds(creds)
                            errorMessage = nil
                            manualTokenInput = ""
                            refreshGeminiData()
                        } catch {
                            errorMessage = "Invalid JSON schema. Make sure you copy/paste the entire oauth_creds.json file."
                        }
                    }
#endif
                } label: {
                    Text("Save & Connect")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, errorMessage == nil ? 20 : 0)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
        .padding()
        .background(
            VisualEffectView()
                .clipShape(RoundedRectangle(cornerRadius: 24))
        )
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color(white: 0.1).opacity(0.4) : Color(white: 0.9).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(.top, 10)
    }
    
    private func geminiDashboardView(data: GeminiUsageData) -> some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Model Quota Limits")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                    .onTapGesture(count: 2) {
                        debugText = GeminiStore.loadLastLog()
                        isShowingDebugAlert = true
                    }
                
                if data.models.isEmpty {
                    Text("No registered active model quotas found.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(data.models) { mdl in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(mdl.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(String(format: "%.0f%% remaining", mdl.remainingFraction * 100))
                                    .font(.caption)
                                    .foregroundColor(mdl.remainingFraction < 0.25 ? .red : (mdl.remainingFraction < 0.6 ? .orange : .blue))
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.primary.opacity(0.06))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(
                                            LinearGradient(
                                                colors: mdl.remainingFraction < 0.25 ? [.red, .orange] : (mdl.remainingFraction < 0.6 ? [.orange, .yellow] : [.blue, .cyan]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * CGFloat(mdl.remainingFraction), height: 6)
                                }
                            }
                            .frame(height: 6)
                            
                            if let reset = mdl.resetTime {
                                Text("Resets: \(formatResetDate(reset)) (\(formatCountdown(reset)))")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Divider()
                    .background(Color.primary.opacity(0.08))
                
                detailRow(title: "Google Account", value: data.email, icon: "person.crop.circle.fill", color: .blue)
                detailRow(title: "Last Synced", value: formatLastScrapedDate(data.lastUpdated), icon: "arrow.clockwise.circle.fill", color: .orange)
            }
            .padding()
            .background(
                VisualEffectView()
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            )
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color(white: 0.1).opacity(0.4) : Color(white: 0.9).opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            
            HStack(spacing: 16) {
                Button {
                    refreshGeminiData()
                } label: {
                    HStack {
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh")
                    }
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(14)
                }
                .disabled(isRefreshing)
                
                Button {
                    GeminiStore.clear()
                    geminiData = nil
                } label: {
                    Text("Disconnect")
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(14)
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 5)
            }
        }
    }
    
    private func refreshGeminiData() {
        isRefreshing = true
        errorMessage = nil
        GeminiNetworkManager.shared.fetchUsage { result in
            DispatchQueue.main.async {
                self.isRefreshing = false
                switch result {
                case .success(let data):
                    self.geminiData = data
                case .failure(let error):
                    self.errorMessage = "Failed to update Gemini: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func formatResetDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatCountdown(_ date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        guard diff > 0 else { return "Resetting..." }
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)m left"
        }
    }

    // MARK: - Antigravity Views & Helpers
#if os(macOS)
    private var antigravityTabContent: some View {
        ZStack {
            if colorScheme == .dark {
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
            } else {
                Color(red: 0.94, green: 0.94, blue: 0.98)
                    .ignoresSafeArea()
            }
            
            glowingBlobs
            
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    
                    if let data = antigravityData {
                        antigravityDashboardView(data: data)
                    } else {
                        antigravityWelcomeView
                    }
                }
                .padding()
            }
        }
    }
    
    private var antigravityWelcomeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.5), radius: 15, x: 0, y: 5)
                .padding(.top, 40)
                .onTapGesture(count: 2) {
                    debugText = AntigravityStore.loadLastLog()
                    isShowingDebugAlert = true
                }
            
            VStack(spacing: 8) {
                Text("Monitor Antigravity Quota")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
#if os(macOS)
                Text("Connect to Antigravity using ~/.codexbar/antigravity/oauth_creds.json on your Mac.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
#else
                Text("Copy the raw JSON contents of ~/.codexbar/antigravity/oauth_creds.json on your Mac and paste it below.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
#endif
            }
            
            VStack(alignment: .leading, spacing: 12) {
#if !os(macOS)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Token JSON Credentials")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .topLeading) {
                        if manualTokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Paste raw oauth_creds.json here...")
                                .foregroundColor(.secondary.opacity(0.4))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .font(.system(size: 11, design: .monospaced))
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: $manualTokenInput)
                            .frame(height: 120)
                            .font(.system(size: 11, design: .monospaced))
                            .autocorrectionDisabled(true)
                            .disableAutocapitalizationIfNeeded()
                            .padding(6)
                            .background(Color.clear)
                    }
                    .background(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
#endif
                
                Button {
#if os(macOS)
                    let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codexbar/antigravity/oauth_creds.json")
                    do {
                        let rawData = try Data(contentsOf: fileURL)
                        let creds = try JSONDecoder().decode(AntigravityOAuthCreds.self, from: rawData)
                        AntigravityStore.saveOAuthCreds(creds)
                        errorMessage = nil
                        refreshAntigravityData()
                    } catch {
                        errorMessage = "Error reading ~/.codexbar/antigravity/oauth_creds.json: \(error.localizedDescription)"
                    }
#else
                    guard !manualTokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        errorMessage = "Please paste your JSON credentials first."
                        return
                    }
                    
                    if let rawData = manualTokenInput.data(using: .utf8) {
                        do {
                            let creds = try JSONDecoder().decode(AntigravityOAuthCreds.self, from: rawData)
                            AntigravityStore.saveOAuthCreds(creds)
                            errorMessage = nil
                            manualTokenInput = ""
                            refreshAntigravityData()
                        } catch {
                            errorMessage = "Invalid JSON schema. Make sure you copy/paste the entire oauth_creds.json file."
                        }
                    }
#endif
                } label: {
                    Text("Save & Connect")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, errorMessage == nil ? 20 : 0)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
        .padding()
        .background(
            VisualEffectView()
                .clipShape(RoundedRectangle(cornerRadius: 24))
        )
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color(white: 0.1).opacity(0.4) : Color(white: 0.9).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(.top, 10)
    }
    
    private func antigravityDashboardView(data: AntigravityUsageData) -> some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Model Quota Limits")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                    .onTapGesture(count: 2) {
                        debugText = AntigravityStore.loadLastLog()
                        isShowingDebugAlert = true
                    }
                
                if data.models.isEmpty {
                    Text("No registered active model quotas found.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(data.models) { mdl in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(mdl.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(String(format: "%.0f%% remaining", mdl.remainingFraction * 100))
                                    .font(.caption)
                                    .foregroundColor(mdl.remainingFraction < 0.25 ? .red : (mdl.remainingFraction < 0.6 ? .orange : .blue))
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.primary.opacity(0.06))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(
                                            LinearGradient(
                                                colors: mdl.remainingFraction < 0.25 ? [.red, .orange] : (mdl.remainingFraction < 0.6 ? [.orange, .yellow] : [.blue, .cyan]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * CGFloat(mdl.remainingFraction), height: 6)
                                }
                            }
                            .frame(height: 6)
                            
                            if let reset = mdl.resetTime {
                                Text("Resets: \(formatResetDate(reset)) (\(formatCountdown(reset)))")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Divider()
                    .background(Color.primary.opacity(0.08))
                
                detailRow(title: "Google Account", value: data.email, icon: "person.crop.circle.fill", color: .blue)
                detailRow(title: "Last Synced", value: formatLastScrapedDate(data.lastUpdated), icon: "arrow.clockwise.circle.fill", color: .orange)
            }
            .padding()
            .background(
                VisualEffectView()
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            )
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color(white: 0.1).opacity(0.4) : Color(white: 0.9).opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            
            HStack(spacing: 16) {
                Button {
                    refreshAntigravityData()
                } label: {
                    HStack {
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh")
                    }
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(14)
                }
                .disabled(isRefreshing)
                
                Button {
                    AntigravityStore.clear()
                    antigravityData = nil
                } label: {
                    Text("Disconnect")
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(14)
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 5)
            }
        }
    }
    
    private func refreshAntigravityData() {
        isRefreshing = true
        errorMessage = nil
        AntigravityNetworkManager.shared.fetchUsage { result in
            DispatchQueue.main.async {
                self.isRefreshing = false
                switch result {
                case .success(let data):
                    self.antigravityData = data
                case .failure(let error):
                    self.errorMessage = "Failed to update Antigravity: \(error.localizedDescription)"
                }
            }
        }
    }
    

#endif
}

// MARK: - Visual Effect View Wrapper for Glassmorphism
#if os(macOS)
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .withinWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
#else
struct VisualEffectView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
#endif

// MARK: - Notification Delegate for Foreground Presentation
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
