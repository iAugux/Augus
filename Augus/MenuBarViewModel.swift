import SwiftUI
import Combine
import WidgetKit

class MenuBarViewModel: ObservableObject {
    @Published var blackSSLEntry: BlackSSLEntry
    @Published var codexEntry: CodexEntry
    @Published var antigravityEntry: AntigravityEntry
    @Published var geminiEntry: GeminiEntry
    
    private var timer: Timer?
    
    init() {
        // Load cached data initially
        self.blackSSLEntry = BlackSSLEntry(date: Date(), usage: BlackSSLStore.loadUsageData(), error: nil)
        self.codexEntry = CodexEntry(date: Date(), usage: CodexStore.loadUsageData(), error: nil)
        self.antigravityEntry = AntigravityEntry(date: Date(), usage: AntigravityStore.loadUsageData(), error: nil)
        self.geminiEntry = GeminiEntry(date: Date(), usage: GeminiStore.loadUsageData(), error: nil)
        
        setupTimer()
    }
    
    private func setupTimer() {
        // Refresh every 15 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            self?.refreshData()
        }
    }
    
    func refreshData() {
        // Fetch BlackSSL
        BlackSSLNetworkManager.shared.fetchUsage { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.blackSSLEntry = BlackSSLEntry(date: Date(), usage: data, error: nil)
                case .failure(let error):
                    self?.blackSSLEntry = BlackSSLEntry(date: Date(), usage: BlackSSLStore.loadUsageData(), error: error.localizedDescription)
                }
            }
        }
        
        // Fetch Codex
        CodexNetworkManager.shared.fetchUsage { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.codexEntry = CodexEntry(date: Date(), usage: data, error: nil)
                case .failure(let error):
                    self?.codexEntry = CodexEntry(date: Date(), usage: CodexStore.loadUsageData(), error: error.localizedDescription)
                }
            }
        }
        
        // Fetch Antigravity
        AntigravityNetworkManager.shared.fetchUsage { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.antigravityEntry = AntigravityEntry(date: Date(), usage: data, error: nil)
                case .failure(let error):
                    self?.antigravityEntry = AntigravityEntry(date: Date(), usage: AntigravityStore.loadUsageData(), error: error.localizedDescription)
                }
            }
        }
        
        // Fetch Gemini
        GeminiNetworkManager.shared.fetchUsage { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.geminiEntry = GeminiEntry(date: Date(), usage: data, error: nil)
                case .failure(let error):
                    self?.geminiEntry = GeminiEntry(date: Date(), usage: GeminiStore.loadUsageData(), error: error.localizedDescription)
                }
            }
        }
    }
}
import SwiftUI
import WidgetKit
