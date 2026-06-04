// Created by Augus on 6/4/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    @Binding var tabsConfig: TabConfigList
    @Binding var selectedTab: ContentView.ServiceTab
    
    private var validatedTabsConfig: [TabConfig] {
        let supported = ContentView.supportedTabs
        var filtered = tabsConfig.items.filter { supported.contains($0.tab) }
        
        // Append missing ones
        for tab in supported {
            if !filtered.contains(where: { $0.tab == tab }) {
                filtered.append(TabConfig(tab: tab, isVisible: true))
            }
        }
        return filtered
    }
    
    var body: some View {
        #if os(macOS)
        macOSContent
        #else
        iOSContent
        #endif
    }
    
    // MARK: - macOS Content Layout (Transparent custom header inside popover)
    private var macOSContent: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Customize Tabs")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    isPresented = false
                } label: {
                    Text("Done")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.primary.opacity(0.08))
            
            scrollViewContent
        }
        .background(
            ZStack {
                if colorScheme == .dark {
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                        .ignoresSafeArea()
                } else {
                    Color(red: 0.96, green: 0.96, blue: 0.98)
                        .ignoresSafeArea()
                }
                glowingBlobs
            }
        )
        .frame(width: 360, height: 380)
    }
    
    // MARK: - iOS Content Layout (NavigationStack with system transparent navigation bar)
    #if !os(macOS)
    private var iOSContent: some View {
        NavigationStack {
            scrollViewContent
                .navigationTitle("Customize Tabs")
                .navigationBarTitleDisplayMode(.inline)
                .hideNavigationBarBackgroundIfNeeded()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            isPresented = false
                        }
                        .font(.system(.body, design: .rounded).bold())
                    }
                }
                .background(
                    ZStack {
                        if colorScheme == .dark {
                            Color(red: 0.05, green: 0.05, blue: 0.08)
                                .ignoresSafeArea()
                        } else {
                            Color(red: 0.96, green: 0.96, blue: 0.98)
                                .ignoresSafeArea()
                        }
                        glowingBlobs
                    }
                )
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    #endif
    
    // MARK: - Shared ScrollView Content
    private var scrollViewContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                let list = validatedTabsConfig
                ForEach(0..<list.count, id: \.self) { index in
                    let config = list[index]
                    
                    HStack(spacing: 10) {
                        tabIcon(for: config.tab)
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(config.tab.rawValue)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(tabSubtitle(for: config.tab))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    moveTabUp(config.tab)
                                }
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(index == 0 ? .secondary.opacity(0.2) : .secondary)
                                    .padding(5)
                                    .background(Color.primary.opacity(index == 0 ? 0.02 : 0.06))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(index == 0)
                            
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    moveTabDown(config.tab)
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(index == list.count - 1 ? .secondary.opacity(0.2) : .secondary)
                                    .padding(5)
                                    .background(Color.primary.opacity(index == list.count - 1 ? 0.02 : 0.06))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(index == list.count - 1)
                        }
                        .padding(.trailing, 2)
                        
                        Toggle("", isOn: Binding(
                            get: { config.isVisible },
                            set: { _ in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    toggleVisibility(for: config.tab)
                                }
                            }
                        ))
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: config.tab.tintColor))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(white: 0.1).opacity(0.5) : Color(white: 0.95).opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
    }
    
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
    
    @ViewBuilder
    private func tabIcon(for tab: ContentView.ServiceTab) -> some View {
        switch tab {
        case .blackssl:
            ZStack {
                LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "globe.asia.australia.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.system(size: 14))
            }
        case .codex:
            ZStack {
                LinearGradient(colors: [Color.green.opacity(0.15), Color.teal.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "cpu.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.system(size: 14))
            }
        case .gemini:
            ZStack {
                LinearGradient(colors: [.blue.opacity(0.15), .cyan.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "sparkles")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.system(size: 14))
            }
        case .antigravity:
            ZStack {
                LinearGradient(colors: [.blue.opacity(0.15), .cyan.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "sparkles")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.system(size: 14))
            }
        }
    }
    
    private func tabSubtitle(for tab: ContentView.ServiceTab) -> String {
        switch tab {
        case .blackssl:
            return "Traffic Monitor"
        case .codex:
            return "GPT Rate Limits"
        case .gemini:
            return "Google Gemini Quota"
        case .antigravity:
            return "Antigravity Monitor"
        }
    }
    
    private func toggleVisibility(for tab: ContentView.ServiceTab) {
        var current = validatedTabsConfig
        guard let index = current.firstIndex(where: { $0.tab == tab }) else { return }
        
        let newVisibility = !current[index].isVisible
        
        let visibleCount = current.filter { $0.isVisible }.count
        if !newVisibility && visibleCount <= 1 {
            return
        }
        
        current[index].isVisible = newVisibility
        tabsConfig = TabConfigList(items: current)
        
        if !newVisibility && selectedTab == tab {
            let visible = current.filter { $0.isVisible }
            if let firstVisible = visible.first {
                selectedTab = firstVisible.tab
            }
        }
    }
    
    private func moveTabUp(_ tab: ContentView.ServiceTab) {
        var current = validatedTabsConfig
        guard let index = current.firstIndex(where: { $0.tab == tab }), index > 0 else { return }
        current.swapAt(index, index - 1)
        tabsConfig = TabConfigList(items: current)
    }
    
    private func moveTabDown(_ tab: ContentView.ServiceTab) {
        var current = validatedTabsConfig
        guard let index = current.firstIndex(where: { $0.tab == tab }), index < current.count - 1 else { return }
        current.swapAt(index, index + 1)
        tabsConfig = TabConfigList(items: current)
    }
}
