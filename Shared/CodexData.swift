// Created by Augus on 6/01/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import Foundation
import WidgetKit

public struct SerializableCookie: Codable, Sendable {
    public let name: String
    public let value: String
    public let domain: String
    public let path: String
    public let isSecure: Bool
    public let isHTTPOnly: Bool
    public let expiresDate: Date?
    
    public init(from cookie: HTTPCookie) {
        self.name = cookie.name
        self.value = cookie.value
        self.domain = cookie.domain
        self.path = cookie.path
        self.isSecure = cookie.isSecure
        self.isHTTPOnly = cookie.isHTTPOnly
        self.expiresDate = cookie.expiresDate
    }
    
    public func toHTTPCookie() -> HTTPCookie? {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: domain,
            .path: path
        ]
        if isSecure { properties[.secure] = "TRUE" }
        if isHTTPOnly { properties[HTTPCookiePropertyKey("HttpOnly")] = "TRUE" }
        if let expiresDate = expiresDate { properties[.expires] = expiresDate }
        return HTTPCookie(properties: properties)
    }
}

// MARK: - Codex Model and Storage (Physically Separated)

public struct CodexUsageData: Codable, Sendable {
    public let primaryUsedPercent: Double      // 5h window usage percent, e.g. 0.45
    public let primaryResetAt: Int64           // Unix timestamp for primary reset
    public let secondaryUsedPercent: Double    // 7d window usage percent, e.g. 0.20
    public let secondaryResetAt: Int64         // Unix timestamp for secondary reset
    public let planType: String                 // e.g. "plus", "team", "free"
    public let lastUpdated: Date
    public let isLoggedIn: Bool
    public let email: String
    
    public init(primaryUsedPercent: Double, primaryResetAt: Int64, secondaryUsedPercent: Double, secondaryResetAt: Int64, planType: String, lastUpdated: Date, isLoggedIn: Bool, email: String) {
        self.primaryUsedPercent = primaryUsedPercent
        self.primaryResetAt = primaryResetAt
        self.secondaryUsedPercent = secondaryUsedPercent
        self.secondaryResetAt = secondaryResetAt
        self.planType = planType
        self.lastUpdated = lastUpdated
        self.isLoggedIn = isLoggedIn
        self.email = email
    }
    
    public var primaryResetCountdownText: String {
        let diff = Double(primaryResetAt) - Date().timeIntervalSince1970
        guard diff > 0 else { return "Resetting..." }
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)m left"
        }
    }
    
    public var secondaryResetCountdownText: String {
        let diff = Double(secondaryResetAt) - Date().timeIntervalSince1970
        guard diff > 0 else { return "Resetting..." }
        let days = Int(diff) / (3600 * 24)
        let hours = (Int(diff) % (3600 * 24)) / 3600
        if days > 0 {
            return "\(days)d \(hours)h left"
        } else {
            return "\(hours)h left"
        }
    }
}

public class CodexStore {
    private static let appGroupIdentifier = "group.com.iAugus.Augus"
    
    public static var defaults: UserDefaults {
        if let groupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            return groupDefaults
        }
        return UserDefaults.standard
    }
    
    public static func saveUsageData(_ data: CodexUsageData) {
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: "codex_usage_data")
            defaults.synchronize()
            print("CodexStore: Saved usage data successfully.")
        }
    }
    
    public static func loadUsageData() -> CodexUsageData? {
        guard let data = defaults.data(forKey: "codex_usage_data") else { return nil }
        return try? JSONDecoder().decode(CodexUsageData.self, from: data)
    }
    
    public static func saveCookies(_ cookies: [HTTPCookie]) {
        let serializable = cookies.map { SerializableCookie(from: $0) }
        if let encoded = try? JSONEncoder().encode(serializable) {
            defaults.set(encoded, forKey: "codex_cookies")
            defaults.synchronize()
            print("CodexStore: Saved \(cookies.count) cookies.")
        }
    }
    
    public static func saveCookieHeader(_ headerString: String) {
        let pairs = headerString.components(separatedBy: ";")
        var cookies: [HTTPCookie] = []
        
        for pair in pairs {
            let parts = pair.components(separatedBy: "=")
            guard parts.count >= 2 else { continue }
            let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = parts.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
            
            let properties: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: value,
                .domain: ".chatgpt.com",
                .path: "/",
                .secure: "TRUE"
            ]
            if let cookie = HTTPCookie(properties: properties) {
                cookies.append(cookie)
            }
        }
        
        if !cookies.isEmpty {
            saveCookies(cookies)
            print("CodexStore: Manually parsed and saved \(cookies.count) cookies.")
        }
    }
    
    public static func loadCookies() -> [HTTPCookie]? {
        guard let data = defaults.data(forKey: "codex_cookies") else { return nil }
        guard let serializable = try? JSONDecoder().decode([SerializableCookie].self, from: data) else { return nil }
        return serializable.compactMap { $0.toHTTPCookie() }
    }
    
    public static func saveLocalStorage(_ dict: [String: String]) {
        defaults.set(dict, forKey: "codex_localStorage")
        defaults.synchronize()
    }
    
    public static func loadLocalStorage() -> [String: String]? {
        return defaults.dictionary(forKey: "codex_localStorage") as? [String: String]
    }
    
    public static func saveLastScrapeResult(_ result: String) {
        defaults.set(result, forKey: "codex_last_scrape_result")
        defaults.synchronize()
    }
    
    public static func loadLastScrapeResult() -> String {
        return defaults.string(forKey: "codex_last_scrape_result") ?? "No Codex logs recorded yet."
    }
    
    public static func clear() {
        defaults.removeObject(forKey: "codex_usage_data")
        defaults.removeObject(forKey: "codex_cookies")
        defaults.removeObject(forKey: "codex_localStorage")
        defaults.removeObject(forKey: "codex_last_scrape_result")
        defaults.synchronize()
        print("CodexStore: Cleared all stored data.")
        WidgetCenter.shared.reloadAllTimelines()
    }
}

public final class CodexNetworkManager: Sendable {
    public static let shared = CodexNetworkManager()
    
    private init() {}
    
    private var userAgent: String {
        #if os(macOS)
        return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
        #else
        return "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
        #endif
    }
    
    public func fetchUsage(completion: @escaping @Sendable (Result<CodexUsageData, Error>) -> Void) {
        fetchSessionToken { result in
            switch result {
            case .success(let session):
                self.fetchWhamUsage(token: session.token, email: session.email) { usageResult in
                    switch usageResult {
                    case .success(let usage):
                        CodexStore.saveUsageData(usage)
                        WidgetCenter.shared.reloadAllTimelines()
                        completion(.success(usage))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchSessionToken(completion: @escaping @Sendable (Result<(token: String, email: String), Error>) -> Void) {
        let sessionURL = "https://chatgpt.com/api/auth/session"
        guard let url = URL(string: sessionURL) else {
            completion(.failure(NSError(domain: "CodexNetworkManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Session URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15.0
        request.httpShouldHandleCookies = false
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        if let cookies = CodexStore.loadCookies() {
            let filtered = cookies.filter { cookie in
                let dom = cookie.domain.lowercased()
                return dom == "chatgpt.com" || dom == ".chatgpt.com" || dom.hasSuffix(".chatgpt.com")
            }
            let headerFields = HTTPCookie.requestHeaderFields(with: filtered)
            for (key, value) in headerFields {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                let logMsg = "Session request failed: \(error.localizedDescription)"
                CodexStore.saveLastScrapeResult(logMsg)
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let logMsg = "No session data received"
                CodexStore.saveLastScrapeResult(logMsg)
                completion(.failure(NSError(domain: "CodexNetworkManager", code: -2, userInfo: [NSLocalizedDescriptionKey: logMsg])))
                return
            }
            
            var statusCode = 0
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    var email = "user@chatgpt.com"
                    if let user = json["user"] as? [String: Any], let userEmail = user["email"] as? String {
                        email = userEmail
                    }
                    
                    if let token = json["accessToken"] as? String, !token.isEmpty {
                        completion(.success((token: token, email: email)))
                    } else {
                        let logMsg = "Session request succeeded but no accessToken found. HTTP Code: \(statusCode)"
                        CodexStore.saveLastScrapeResult(logMsg)
                        completion(.failure(NSError(domain: "CodexNetworkManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unauthorized: Codex Session Expired"])))
                    }
                } else {
                    let logMsg = "Session JSON format invalid (not a dictionary). HTTP Code: \(statusCode)"
                    CodexStore.saveLastScrapeResult(logMsg)
                    completion(.failure(NSError(domain: "CodexNetworkManager", code: -4, userInfo: [NSLocalizedDescriptionKey: logMsg])))
                }
            } catch {
                let bodyString = String(data: data, encoding: .utf8) ?? "Unable to decode UTF8"
                let truncatedBody = String(bodyString.prefix(300))
                let logMsg = "Failed to parse session JSON. HTTP Status: \(statusCode). Response: \(truncatedBody)"
                CodexStore.saveLastScrapeResult(logMsg)
                completion(.failure(NSError(domain: "CodexNetworkManager", code: -5, userInfo: [NSLocalizedDescriptionKey: "Unauthorized: Session Expired (Code \(statusCode))"])))
            }
        }
        task.resume()
    }
    
    private func fetchWhamUsage(token: String, email: String, completion: @escaping @Sendable (Result<CodexUsageData, Error>) -> Void) {
        let usageURL = "https://chatgpt.com/backend-api/wham/usage"
        guard let url = URL(string: usageURL) else {
            completion(.failure(NSError(domain: "CodexNetworkManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Usage URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15.0
        request.httpShouldHandleCookies = false
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        if let cookies = CodexStore.loadCookies() {
            let filtered = cookies.filter { cookie in
                let dom = cookie.domain.lowercased()
                return dom == "chatgpt.com" || dom == ".chatgpt.com" || dom.hasSuffix(".chatgpt.com")
            }
            let headerFields = HTTPCookie.requestHeaderFields(with: filtered)
            for (key, value) in headerFields {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                let logMsg = "Wham/Usage request failed: \(error.localizedDescription)"
                CodexStore.saveLastScrapeResult(logMsg)
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let logMsg = "No usage limit data received"
                CodexStore.saveLastScrapeResult(logMsg)
                completion(.failure(NSError(domain: "CodexNetworkManager", code: -2, userInfo: [NSLocalizedDescriptionKey: logMsg])))
                return
            }
            
            var statusCode = 0
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let rateLimit = json["rate_limit"] as? [String: Any]
                    let planType = json["plan_type"] as? String ?? "free"
                    
                    var primaryUsed = 0.0
                    var primaryReset: Int64 = 0
                    var secondaryUsed = 0.0
                    var secondaryReset: Int64 = 0
                    
                    if let rateLimit = rateLimit {
                        if let primary = rateLimit["primary_window"] as? [String: Any] {
                            let rawUsed = (primary["used_percent"] as? NSNumber)?.doubleValue ?? 0.0
                            primaryUsed = rawUsed > 1.0 ? rawUsed / 100.0 : rawUsed
                            primaryReset = (primary["reset_at"] as? NSNumber)?.int64Value ?? 0
                        }
                        if let secondary = rateLimit["secondary_window"] as? [String: Any] {
                            let rawUsed = (secondary["used_percent"] as? NSNumber)?.doubleValue ?? 0.0
                            secondaryUsed = rawUsed > 1.0 ? rawUsed / 100.0 : rawUsed
                            secondaryReset = (secondary["reset_at"] as? NSNumber)?.int64Value ?? 0
                        }
                    }
                    
                    let usageData = CodexUsageData(
                        primaryUsedPercent: primaryUsed,
                        primaryResetAt: primaryReset,
                        secondaryUsedPercent: secondaryUsed,
                        secondaryResetAt: secondaryReset,
                        planType: planType,
                        lastUpdated: Date(),
                        isLoggedIn: true,
                        email: email
                    )
                    
                    let logMsg = "Success fetching Codex usage: \(planType), 5h used: \(String(format: "%.1f%%", primaryUsed * 100.0)), 7d used: \(String(format: "%.1f%%", secondaryUsed * 100.0))"
                    CodexStore.saveLastScrapeResult(logMsg)
                    completion(.success(usageData))
                } else {
                    let logMsg = "Wham/Usage JSON format invalid. HTTP Code: \(statusCode)"
                    CodexStore.saveLastScrapeResult(logMsg)
                    completion(.failure(NSError(domain: "CodexNetworkManager", code: -3, userInfo: [NSLocalizedDescriptionKey: logMsg])))
                }
            } catch {
                let bodyString = String(data: data, encoding: .utf8) ?? "Unable to decode UTF8"
                let truncatedBody = String(bodyString.prefix(300))
                let logMsg = "Failed to parse Wham/Usage JSON. HTTP Status: \(statusCode). Response: \(truncatedBody)"
                CodexStore.saveLastScrapeResult(logMsg)
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

