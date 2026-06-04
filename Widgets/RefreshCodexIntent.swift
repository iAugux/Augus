import AppIntents
import WidgetKit

struct RefreshCodexIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Codex"
    static var description = IntentDescription("Refreshes the Codex usage data.")

    init() {}
    
    func perform() async throws -> some IntentResult {
        await withCheckedContinuation { continuation in
            CodexNetworkManager.shared.fetchUsage { _ in
                continuation.resume()
            }
        }
        return .result()
    }
}
