import AppIntents
import WidgetKit

struct RefreshBlackSSLIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh BlackSSL"
    static var description = IntentDescription("Refreshes the BlackSSL usage data.")

    static var supportedModes: IntentModes {
        return .background
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        await withCheckedContinuation { continuation in
            BlackSSLNetworkManager.shared.fetchUsage { _ in
                continuation.resume()
            }
        }
        return .result()
    }
}
