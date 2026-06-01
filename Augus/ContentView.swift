// Created by Augus on 5/30/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI
import UserNotifications

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var usageData: BlackSSLUsageData? = BlackSSLStore.loadUsageData()
    @State private var codexData: CodexUsageData? = CodexStore.loadUsageData()
    @State private var selectedTab: ServiceTab = .blackssl
    @State private var isShowingBlackSSLLogin = false
    @State private var isShowingCodexLogin = false
    @State private var isRefreshing = false
    @State private var errorMessage: String? = nil
    @State private var isShowingDebugAlert = false
    @State private var debugText = ""
    @State private var manualCookieInput = ""
    @State private var notificationDelegate = NotificationDelegate()
    
    enum ServiceTab: String, CaseIterable, Identifiable {
        case blackssl = "BlackSSL"
        case codex = "Codex"
        
        var id: String { rawValue }
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
                    Label("Codex", systemImage: "cpu.fill")
                }
                .tag(ServiceTab.codex)
        }
        .tint(selectedTab == .blackssl ? .purple : .green)
        .onChange(of: selectedTab) { _ in
            errorMessage = nil
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
                Text(selectedTab == .blackssl ? "BlackSSL" : "Codex")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                if selectedTab == .blackssl {
                    if let data = usageData {
                        Text(data.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Dashboard Widget Monitor")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    if let data = codexData {
                        Text(data.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Codex Rate Limit Monitor")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Status Dot Indicator
            let isConnected = (selectedTab == .blackssl ? usageData != nil : codexData != nil)
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
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                
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
                    Circle()
                        .trim(from: 0.0, to: CGFloat(data.primaryUsedPercent))
                        .stroke(
                            codexProgressGradient(for: data.primaryUsedPercent),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.8), value: data.primaryUsedPercent)
                        .shadow(color: codexProgressShadowColor(for: data.primaryUsedPercent).opacity(0.25), radius: 8, x: 0, y: 4)
                    
                    // Inside Circle Texts
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f%%", data.primaryUsedPercent * 100))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("5h Limit")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 14)
                
                // Texts Below Progress Ring
                HStack(spacing: 40) {
                    VStack(alignment: .center) {
                        Text(String(format: "%.1f%%", data.primaryUsedPercent * 100))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("5h Window Used")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .center) {
                        Text(String(format: "%.1f%%", data.secondaryUsedPercent * 100))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("7d Window Used")
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
    }
    
    // MARK: - Actions & Helpers
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
    
    private func codexProgressGradient(for percentage: Double) -> LinearGradient {
        let colors: [Color]
        if percentage < 0.6 {
            // Cool Green to Teal (Safe)
            colors = [Color(red: 0.17, green: 0.78, blue: 0.44), Color(red: 0.18, green: 0.77, blue: 0.71)]
        } else if percentage < 0.85 {
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
    
    private func codexProgressShadowColor(for percentage: Double) -> Color {
        if percentage < 0.6 {
            return Color(red: 0.17, green: 0.78, blue: 0.44)
        } else if percentage < 0.85 {
            return Color(red: 0.95, green: 0.61, blue: 0.07)
        } else {
            return Color(red: 0.90, green: 0.30, blue: 0.26)
        }
    }
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
