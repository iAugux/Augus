// Created by Augus on 5/30/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var usageData: UsageData? = SharedStore.loadUsageData()
    @State private var isShowingLogin = false
    @State private var isRefreshing = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            // Premium background: Deep dark space with glowing neon blobs
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
                    // Header Area
                    headerView
                    
                    if let data = usageData {
                        // Dashboard Content
                        dashboardView(data: data)
                    } else {
                        // Login Placeholder View
                        loginWelcomeView
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $isShowingLogin) {
            loginWebViewSheet
        }
        .onAppear {
            // Auto refresh on open
            if usageData != nil {
                refreshData()
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
                Text("BlackSSL")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                if let data = usageData {
                    Text(data.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Dashboard Widget Monitor")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Status Dot Indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(usageData != nil ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                
                Text(usageData != nil ? "Connected" : "Disconnected")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(usageData != nil ? .green : .orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(usageData != nil ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
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
                isShowingLogin = true
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
            .padding(.bottom, 20)
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
    
    // MARK: - Dashboard View
    @ViewBuilder
    private func dashboardView(data: UsageData) -> some View {
        VStack(spacing: 24) {
            // Circular Progress Card
            VStack {
                ZStack {
                    // Outer Ring Track
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 20)
                        .frame(width: 180, height: 180)
                    
                    // Usage Progress Ring
                    Circle()
                        .trim(from: 0.0, to: CGFloat(data.usagePercentage))
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.8), value: data.usagePercentage)
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    // Inside Circle Texts
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f%%", data.usagePercentage * 100))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 20)
                
                // Texts Below Progress Ring
                HStack(spacing: 40) {
                    VStack(alignment: .center) {
                        Text(NetworkManager.formatBytes(data.used))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Used Total")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .center) {
                        Text(NetworkManager.formatBytes(data.total))
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
                
                detailRow(title: "Upload Data", value: NetworkManager.formatBytes(data.upload), icon: "arrow.up.circle.fill", color: .blue)
                detailRow(title: "Download Data", value: NetworkManager.formatBytes(data.download), icon: "arrow.down.circle.fill", color: .purple)
                detailRow(title: "Remaining Quota", value: NetworkManager.formatBytes(data.remaining), icon: "bolt.circle.fill", color: .green)
                if let today = data.todayUsed {
                    detailRow(title: "Today's Usage", value: NetworkManager.formatBytes(today), icon: "chart.bar.fill", color: .orange)
                }
                
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
                    SharedStore.clear()
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
    
    // MARK: - Login WebView Sheet
    private var loginWebViewSheet: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Button("Cancel") {
                    isShowingLogin = false
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Text("Login to BlackSSL")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Done") {
                    isShowingLogin = false
                    refreshData()
                }
                .foregroundColor(.blue)
                .fontWeight(.bold)
            }
            .padding()
            .background(colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.15) : Color(red: 0.95, green: 0.95, blue: 0.97))
            
            WebView(url: URL(string: "https://blackssl.com/dashboard")!) { cookies, localStorage, host in
                // Save captured session base details
                if !cookies.isEmpty {
                    SharedStore.saveCookies(cookies)
                }
                if !localStorage.isEmpty {
                    SharedStore.saveLocalStorage(localStorage)
                }
                SharedStore.saveBaseHost(host)
                
                // Let's print out what is captured to see if we logged in
                print("Cookies captured: \(cookies.count)")
                print("LocalStorage captured keys: \(localStorage.keys)")
            }
        }
    }
    
    // MARK: - Actions & Helpers
    private func refreshData() {
        isRefreshing = true
        errorMessage = nil
        NetworkManager.shared.fetchUsage { result in
            DispatchQueue.main.async {
                isRefreshing = false
                switch result {
                case .success(let data):
                    self.usageData = data
                case .failure(let error):
                    self.errorMessage = "Failed to update: \(error.localizedDescription)"
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
