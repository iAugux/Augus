// Created by Augus on 6/01/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import Foundation
import WidgetKit

// MARK: - Antigravity Models & Credentials

public struct AntigravityOAuthCreds: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiryDate: Double // Milliseconds since 1970
    public let tokenType: String?
    public let idToken: String?
    public let scope: String?
    public let clientId: String?
    public let clientSecret: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiryDate = "expiry_date"
        case tokenType = "token_type"
        case idToken = "id_token"
        case scope = "scope"
        case clientId = "client_id"
        case clientSecret = "client_secret"
    }
}

public struct AntigravityModelQuota: Codable, Sendable, Identifiable {
    public var id: String { name }
    public let name: String
    public let remainingFraction: Double
    public let resetTime: Date?
    
    public init(name: String, remainingFraction: Double, resetTime: Date?) {
        self.name = name
        self.remainingFraction = remainingFraction
        self.resetTime = resetTime
    }
}

public struct AntigravityUsageData: Codable, Sendable {
    public let models: [AntigravityModelQuota]
    public let lastUpdated: Date
    public let email: String
    
    public init(models: [AntigravityModelQuota], lastUpdated: Date, email: String) {
        self.models = models
        self.lastUpdated = lastUpdated
        self.email = email
    }
}

// MARK: - Antigravity Store

public class AntigravityStore {
    private static let appGroupIdentifier = "group.com.iAugus.Augus"
    
    public static var defaults: UserDefaults {
        if let groupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            return groupDefaults
        }
        return UserDefaults.standard
    }
    
    public static func saveOAuthCreds(_ creds: AntigravityOAuthCreds) {
        if let encoded = try? JSONEncoder().encode(creds) {
            defaults.set(encoded, forKey: "antigravity_oauth_creds")
            defaults.synchronize()
            print("AntigravityStore: Saved OAuth credentials.")
        }
    }
    
    public static func loadOAuthCreds() -> AntigravityOAuthCreds? {
        guard let data = defaults.data(forKey: "antigravity_oauth_creds") else { return nil }
        return try? JSONDecoder().decode(AntigravityOAuthCreds.self, from: data)
    }
    
    public static func saveUsageData(_ data: AntigravityUsageData) {
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: "antigravity_usage_data")
            defaults.synchronize()
            print("AntigravityStore: Saved usage data.")
        }
    }
    
    public static func loadUsageData() -> AntigravityUsageData? {
        guard let data = defaults.data(forKey: "antigravity_usage_data") else { return nil }
        return try? JSONDecoder().decode(AntigravityUsageData.self, from: data)
    }
    
    public static func saveLastLog(_ log: String) {
        defaults.set(log, forKey: "antigravity_last_log")
        defaults.synchronize()
    }
    
    public static func loadLastLog() -> String {
        return defaults.string(forKey: "antigravity_last_log") ?? "No Antigravity logs recorded yet."
    }
    
    public static func clear() {
        defaults.removeObject(forKey: "antigravity_oauth_creds")
        defaults.removeObject(forKey: "antigravity_usage_data")
        defaults.removeObject(forKey: "antigravity_last_log")
        defaults.synchronize()
        print("AntigravityStore: Cleared all stored data.")
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Antigravity Network Manager

public final class AntigravityNetworkManager: Sendable {
    public static let shared = AntigravityNetworkManager()
    
    private init() {}
    
    // Google Client ID and Client Secret extracted from Antigravity CLI (Code Assist)
    private let clientID = "681255809395-oo8ft2oprdrnp9e3aqf6av3hmdib135j.apps.googleusercontent.com"
    private let clientSecret = "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"
    
    private var userAgent: String {
        #if os(macOS)
        return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
        #else
        return "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
        #endif
    }
    
    public func fetchUsage(completion: @escaping @Sendable (Result<AntigravityUsageData, Error>) -> Void) {
        guard let creds = AntigravityStore.loadOAuthCreds() else {
            let error = NSError(domain: "AntigravityNetworkManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Antigravity OAuth credentials found. Please paste your token JSON in the App first."])
            completion(.failure(error))
            return
        }
        
        // Refresh token if expired or about to expire in 5 minutes
        let currentMs = Date().timeIntervalSince1970 * 1000
        let bufferMs: Double = 5 * 60 * 1000
        
        if currentMs + bufferMs >= creds.expiryDate {
            AntigravityStore.saveLastLog("Access token expired or expiring soon. Refreshing token...")
            refreshAccessToken(creds: creds) { [weak self] refreshResult in
                guard let self = self else { return }
                switch refreshResult {
                case .success(let updatedCreds):
                    self.fetchUsageWithToken(updatedCreds.accessToken, completion: completion)
                case .failure(let error):
                    let log = "Failed to refresh token: \(error.localizedDescription)"
                    AntigravityStore.saveLastLog(log)
                    completion(.failure(error))
                }
            }
        } else {
            fetchUsageWithToken(creds.accessToken, completion: completion)
        }
    }
    
    private func refreshAccessToken(creds: AntigravityOAuthCreds, completion: @escaping @Sendable (Result<AntigravityOAuthCreds, Error>) -> Void) {
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let parameters = [
            "client_id": creds.clientId ?? clientID,
            "client_secret": creds.clientSecret ?? clientSecret,
            "refresh_token": creds.refreshToken,
            "grant_type": "refresh_token"
        ]
        
        let formBody = parameters.map { key, value in
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }.joined(separator: "&")
        
        request.httpBody = formBody.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AntigravityNetworkManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received during token refresh."])))
                return
            }
            
            struct TokenResponse: Codable {
                let access_token: String
                let expires_in: Int
                let token_type: String?
                let id_token: String?
                let scope: String?
            }
            
            do {
                if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any], let err = dict["error"] {
                    let desc = dict["error_description"] as? String ?? "\(err)"
                    let errorMsg = "Google API Error: \(desc)"
                    AntigravityStore.saveLastLog(errorMsg)
                    completion(.failure(NSError(domain: "AntigravityNetworkManager", code: -3, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                    return
                }
                
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                let newExpiry = (Date().timeIntervalSince1970 * 1000) + Double(tokenResponse.expires_in * 1000)
                
                let updated = AntigravityOAuthCreds(
                    accessToken: tokenResponse.access_token,
                    refreshToken: creds.refreshToken, // Google refresh tokens are long-lived and reused unless revoked
                    expiryDate: newExpiry,
                    tokenType: tokenResponse.token_type ?? creds.tokenType,
                    idToken: tokenResponse.id_token ?? creds.idToken,
                    scope: tokenResponse.scope ?? creds.scope,
                    clientId: creds.clientId,
                    clientSecret: creds.clientSecret
                )
                
                AntigravityStore.saveOAuthCreds(updated)
                AntigravityStore.saveLastLog("Successfully refreshed Google OAuth token.")
                completion(.success(updated))
            } catch {
                let body = String(data: data, encoding: .utf8) ?? "Unable to decode UTF8"
                let logMsg = "Failed to parse token response JSON. Response: \(body.prefix(300))"
                AntigravityStore.saveLastLog(logMsg)
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    private struct CodeAssistInfo {
        let projectId: String?
        let email: String
    }
    
    private func loadCodeAssist(accessToken: String, completion: @escaping @Sendable (Result<CodeAssistInfo, Error>) -> Void) {
        let url = URL(string: "https://cloudcode-pa.googleapis.com/v1internal:loadCodeAssist")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let body: [String: Any] = [
            "metadata": [
                "ideType": "ANTIGRAVITY",
                "platform": "PLATFORM_UNSPECIFIED",
                "pluginType": "GEMINI"
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                AntigravityStore.saveLastLog("loadCodeAssist request failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let log = "No data returned from loadCodeAssist."
                AntigravityStore.saveLastLog(log)
                completion(.failure(NSError(domain: "AntigravityNetworkManager", code: -3, userInfo: [NSLocalizedDescriptionKey: log])))
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    AntigravityStore.saveLastLog("Invalid loadCodeAssist JSON payload.")
                    completion(.failure(NSError(domain: "AntigravityNetworkManager", code: -5, userInfo: [NSLocalizedDescriptionKey: "Invalid loadCodeAssist JSON payload."])))
                    return
                }
                
                let manageUri = json["manageSubscriptionUri"] as? String
                let email = self.extractEmail(from: manageUri)
                
                var projectId = self.extractProjectId(from: json)
                
                if projectId != nil {
                    completion(.success(CodeAssistInfo(projectId: projectId, email: email)))
                    return
                }
                
                // No project ID yet — try onboarding
                let tierId = self.pickOnboardTier(from: json)
                if let tierId = tierId {
                    AntigravityStore.saveLastLog("No project ID found. Attempting onboarding with tier: \(tierId)")
                    self.onboardUser(accessToken: accessToken, tierId: tierId) { [weak self] onboardResult in
                        guard let self = self else { return }
                        switch onboardResult {
                        case .success(let onboardProjectId):
                            if let pid = onboardProjectId {
                                completion(.success(CodeAssistInfo(projectId: pid, email: email)))
                            } else {
                                // Retry loadCodeAssist after onboard
                                self.retryLoadCodeAssist(accessToken: accessToken, email: email, retries: 3, completion: completion)
                            }
                        case .failure:
                            // Even if onboard fails, try without project ID
                            completion(.success(CodeAssistInfo(projectId: nil, email: email)))
                        }
                    }
                } else {
                    // No tier to onboard with, proceed without project ID
                    AntigravityStore.saveLastLog("loadCodeAssist: no project ID and no onboard tier available. Proceeding without project.")
                    completion(.success(CodeAssistInfo(projectId: nil, email: email)))
                }
            } catch {
                AntigravityStore.saveLastLog("Failed to parse loadCodeAssist: \(error.localizedDescription). Response: \(String(data: data, encoding: .utf8) ?? "")")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    private func extractProjectId(from json: [String: Any]) -> String? {
        if let str = json["cloudaicompanionProject"] as? String, !str.isEmpty {
            return str
        }
        if let dict = json["cloudaicompanionProject"] as? [String: Any] {
            if let id = dict["id"] as? String, !id.isEmpty { return id }
            if let pid = dict["projectId"] as? String, !pid.isEmpty { return pid }
        }
        return nil
    }
    
    private func pickOnboardTier(from json: [String: Any]) -> String? {
        if let tiers = json["allowedTiers"] as? [[String: Any]] {
            if let defaultTier = tiers.first(where: { ($0["isDefault"] as? Bool) == true }),
               let id = defaultTier["id"] as? String, !id.isEmpty {
                return id
            }
            if let first = tiers.first, let id = first["id"] as? String, !id.isEmpty {
                return id
            }
        }
        if let paidTier = json["paidTier"] as? [String: Any], let id = paidTier["id"] as? String, !id.isEmpty {
            return id
        }
        if let currentTier = json["currentTier"] as? [String: Any], let id = currentTier["id"] as? String, !id.isEmpty {
            return id
        }
        return nil
    }
    
    private func onboardUser(accessToken: String, tierId: String, completion: @escaping @Sendable (Result<String?, Error>) -> Void) {
        let url = URL(string: "https://cloudcode-pa.googleapis.com/v1internal:onboardUser")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let body: [String: Any] = [
            "tierId": tierId,
            "metadata": [
                "ideType": "ANTIGRAVITY",
                "platform": "PLATFORM_UNSPECIFIED",
                "pluginType": "GEMINI"
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            if let error = error {
                AntigravityStore.saveLastLog("onboardUser request failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.success(nil))
                return
            }
            let innerResponse = json["response"] as? [String: Any] ?? json
            let projectId = self?.extractProjectId(from: innerResponse)
            if let projectId = projectId {
                AntigravityStore.saveLastLog("onboardUser: got project ID \(projectId)")
            }
            completion(.success(projectId))
        }
        task.resume()
    }
    
    private func retryLoadCodeAssist(accessToken: String, email: String, retries: Int, completion: @escaping @Sendable (Result<CodeAssistInfo, Error>) -> Void) {
        guard retries > 0 else {
            completion(.success(CodeAssistInfo(projectId: nil, email: email)))
            return
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            let url = URL(string: "https://cloudcode-pa.googleapis.com/v1internal:loadCodeAssist")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")
            
            let body: [String: Any] = [
                "metadata": [
                    "ideType": "ANTIGRAVITY",
                    "platform": "PLATFORM_UNSPECIFIED",
                    "pluginType": "GEMINI"
                ]
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
                guard let self = self, let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self?.retryLoadCodeAssist(accessToken: accessToken, email: email, retries: retries - 1, completion: completion)
                    return
                }
                if let projectId = self.extractProjectId(from: json) {
                    completion(.success(CodeAssistInfo(projectId: projectId, email: email)))
                } else {
                    self.retryLoadCodeAssist(accessToken: accessToken, email: email, retries: retries - 1, completion: completion)
                }
            }
            task.resume()
        }
    }
    
    private func fetchUsageWithToken(_ accessToken: String, completion: @escaping @Sendable (Result<AntigravityUsageData, Error>) -> Void) {
        loadCodeAssist(accessToken: accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let codeAssistData):
                let projectId = codeAssistData.projectId
                let email = codeAssistData.email
                
                // Try fetchAvailableModels first (newer API), fall back to retrieveUserQuota
                self.fetchAvailableModels(accessToken: accessToken, projectId: projectId) { modelsResult in
                    switch modelsResult {
                    case .success(let models) where !models.isEmpty:
                        let usageData = AntigravityUsageData(models: models, lastUpdated: Date(), email: email)
                        AntigravityStore.saveUsageData(usageData)
                        AntigravityStore.saveLastLog("Successfully updated Antigravity quotas via fetchAvailableModels for \(email). Found \(models.count) models.")
                        WidgetCenter.shared.reloadAllTimelines()
                        completion(.success(usageData))
                    default:
                        // Fall back to retrieveUserQuota
                        guard let projectId = projectId else {
                            let log = "No project ID available and fetchAvailableModels returned no models."
                            AntigravityStore.saveLastLog(log)
                            completion(.failure(NSError(domain: "AntigravityNetworkManager", code: -4, userInfo: [NSLocalizedDescriptionKey: log])))
                            return
                        }
                        self.retrieveUserQuota(accessToken: accessToken, projectId: projectId) { quotaResult in
                            switch quotaResult {
                            case .success(let models):
                                let usageData = AntigravityUsageData(models: models, lastUpdated: Date(), email: email)
                                AntigravityStore.saveUsageData(usageData)
                                AntigravityStore.saveLastLog("Successfully updated Antigravity quotas via retrieveUserQuota for \(email). Found \(models.count) model buckets.")
                                WidgetCenter.shared.reloadAllTimelines()
                                completion(.success(usageData))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchAvailableModels(accessToken: String, projectId: String?, completion: @escaping @Sendable (Result<[AntigravityModelQuota], Error>) -> Void) {
        let url = URL(string: "https://cloudcode-pa.googleapis.com/v1internal:fetchAvailableModels")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        var body: [String: Any] = [:]
        if let projectId = projectId {
            body["project"] = projectId
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.success([]))
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let models = json["models"] as? [String: [String: Any]] else {
                    completion(.success([]))
                    return
                }
                
                let isoFormatter = ISO8601DateFormatter()
                var result: [AntigravityModelQuota] = []
                
                for (modelId, modelInfo) in models {
                    guard let quotaInfo = modelInfo["quotaInfo"] as? [String: Any],
                          let fraction = quotaInfo["remainingFraction"] as? Double else {
                        continue
                    }
                    let label = (modelInfo["displayName"] as? String) ?? (modelInfo["label"] as? String) ?? modelId
                    let resetDate = (quotaInfo["resetTime"] as? String).flatMap { isoFormatter.date(from: $0) }
                    result.append(AntigravityModelQuota(name: label, remainingFraction: fraction, resetTime: resetDate))
                }
                
                result.sort(by: { $0.name < $1.name })
                completion(.success(result))
            } catch {
                completion(.success([]))
            }
        }
        task.resume()
    }
    
    private func retrieveUserQuota(accessToken: String, projectId: String, completion: @escaping @Sendable (Result<[AntigravityModelQuota], Error>) -> Void) {
        let url = URL(string: "https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuota")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let body: [String: Any] = [
            "project": projectId
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                let log = "retrieveUserQuota request failed: \(error.localizedDescription)"
                AntigravityStore.saveLastLog(log)
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let log = "No data returned from retrieveUserQuota."
                AntigravityStore.saveLastLog(log)
                completion(.failure(NSError(domain: "AntigravityNetworkManager", code: -6, userInfo: [NSLocalizedDescriptionKey: log])))
                return
            }
            
            struct QuotaResponse: Codable {
                struct Bucket: Codable {
                    let resetTime: String?
                    let modelId: String?
                    let remainingFraction: Double?
                }
                let buckets: [Bucket]?
            }
            
            do {
                let responseObj = try JSONDecoder().decode(QuotaResponse.self, from: data)
                var models: [AntigravityModelQuota] = []
                
                let isoFormatter = ISO8601DateFormatter()
                
                if let buckets = responseObj.buckets {
                    for bucket in buckets {
                        guard let modelId = bucket.modelId, let fraction = bucket.remainingFraction else {
                            continue
                        }
                        
                        let resetDate = bucket.resetTime.flatMap { isoFormatter.date(from: $0) }
                        models.append(AntigravityModelQuota(name: modelId, remainingFraction: fraction, resetTime: resetDate))
                    }
                }
                
                models.sort(by: { $0.name < $1.name })
                completion(.success(models))
            } catch {
                let log = "Failed to parse retrieveUserQuota JSON: \(error.localizedDescription). Response: \(String(data: data, encoding: .utf8) ?? "")"
                AntigravityStore.saveLastLog(log)
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    private func extractEmail(from uri: String?) -> String {
        guard let uri = uri, let url = URL(string: uri),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return "user@google.com"
        }
        return components.queryItems?.first(where: { $0.name == "Email" })?.value ?? "user@google.com"
    }
}
