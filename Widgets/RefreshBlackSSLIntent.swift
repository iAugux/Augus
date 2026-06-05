import AppIntents
import WidgetKit

struct RefreshBlackSSLIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh BlackSSL"
    static var description = IntentDescription("Refreshes the BlackSSL usage data.")

    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *)
    static var supportedModes: IntentModes {
        return .background
    }

    init() {}
    
    func perform() async throws -> some IntentResult {
        await withCheckedContinuation { continuation in
            BlackSSLNetworkManager.shared.fetchUsage { _ in
                continuation.resume()
            }
        }
        return .result()
    }
}
