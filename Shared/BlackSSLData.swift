// Created by Augus on 5/30/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import Foundation
import WidgetKit
import UserNotifications

public struct BlackSSLUsageData: Codable, Sendable {
    public let upload: Int64
    public let download: Int64
    public let total: Int64
    public let expiredAt: Int64?
    public let email: String
    public let lastUpdated: Date
    public let isLoggedIn: Bool
    public let todayUsed: Int64?
    public let nextResetText: String?
    
    public init(upload: Int64, download: Int64, total: Int64, expiredAt: Int64?, email: String, lastUpdated: Date, isLoggedIn: Bool, todayUsed: Int64? = nil, nextResetText: String? = nil) {
        self.upload = upload
        self.download = download
        self.total = total
        self.expiredAt = expiredAt
        self.email = email
        self.lastUpdated = lastUpdated
        self.isLoggedIn = isLoggedIn
        self.todayUsed = todayUsed
        self.nextResetText = nextResetText
    }
    
    public var used: Int64 {
        return upload + download
    }
    
    public var remaining: Int64 {
        return max(0, total - used)
    }
    
    public var usagePercentage: Double {
        guard total > 0 else { return 0.0 }
        return min(1.0, Double(used) / Double(total))
    }
}


public class BlackSSLStore {
    private static let appGroupIdentifier = "group.com.iAugus.Augus"
    
    public static var defaults: UserDefaults {
        if let groupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            groupDefaults.set("test_write", forKey: "__group_write_test__")
            if groupDefaults.string(forKey: "__group_write_test__") == "test_write" {
                return groupDefaults
            }
        }
        print("WARNING: App Group '\(appGroupIdentifier)' is unavailable or un-entitled. Falling back to UserDefaults.standard.")
        return UserDefaults.standard
    }
    
    public static func saveUsageData(_ data: BlackSSLUsageData) {
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: "usage_data")
            defaults.synchronize()
            print("BlackSSLStore: Saved usage data successfully. Total: \(data.total)")
            
            if let todayUsed = data.todayUsed {
                checkAndSendTodayUsageNotification(todayUsed: todayUsed)
            }
        }
    }
    
    public static func loadUsageData() -> BlackSSLUsageData? {
        guard let data = defaults.data(forKey: "usage_data") else { return nil }
        return try? JSONDecoder().decode(BlackSSLUsageData.self, from: data)
    }
    
    public static func saveCookies(_ cookies: [HTTPCookie]) {
        let serializable = cookies.map { SerializableCookie(from: $0) }
        if let encoded = try? JSONEncoder().encode(serializable) {
            defaults.set(encoded, forKey: "cookies")
            defaults.synchronize()
            print("BlackSSLStore: Saved \(cookies.count) cookies to defaults: \(cookies.map { "\($0.name)=\($0.value)" })")
        }
    }
    
    public static func loadCookies() -> [HTTPCookie]? {
        guard let data = defaults.data(forKey: "cookies") else {
            print("BlackSSLStore: No cookies found in defaults.")
            return nil
        }
        guard let serializable = try? JSONDecoder().decode([SerializableCookie].self, from: data) else {
            print("BlackSSLStore: Failed to decode cookies.")
            return nil
        }
        let cookies = serializable.compactMap { $0.toHTTPCookie() }
        print("BlackSSLStore: Loaded \(cookies.count) cookies from defaults: \(cookies.map { "\($0.name)=\($0.value)" })")
        return cookies
    }
    
    public static func saveLocalStorage(_ dict: [String: String]) {
        defaults.set(dict, forKey: "localStorage")
        defaults.synchronize()
    }
    
    public static func loadLocalStorage() -> [String: String]? {
        return defaults.dictionary(forKey: "localStorage") as? [String: String]
    }
    
    public static func saveBaseHost(_ host: String) {
        defaults.set(host, forKey: "base_host")
        defaults.synchronize()
    }
    
    public static func loadBaseHost() -> String {
        return defaults.string(forKey: "base_host") ?? "blackssl.com"
    }
    
    public static func saveSubscriptionToken(_ token: String) {
        defaults.set(token, forKey: "subscription_token")
        defaults.synchronize()
        print("BlackSSLStore: Saved subscription token: \(token)")
    }
    
    public static func loadSubscriptionToken() -> String? {
        return defaults.string(forKey: "subscription_token")
    }

    public static func saveSubscriptionURL(_ url: String) {
        defaults.set(url, forKey: "subscription_url")
        defaults.synchronize()
        print("BlackSSLStore: Saved subscription URL: \(url)")
    }
    
    public static func loadSubscriptionURL() -> String? {
        return defaults.string(forKey: "subscription_url")
    }
    
    public static func saveIsV2Board(_ isV2: Bool) {
        defaults.set(isV2, forKey: "is_v2board")
        defaults.synchronize()
    }
    
    public static func loadIsV2Board() -> Bool {
        return defaults.bool(forKey: "is_v2board")
    }
    
    public static func saveEmail(_ email: String) {
        defaults.set(email, forKey: "email")
        defaults.synchronize()
        print("BlackSSLStore: Saved email: \(email)")
    }
    
    public static func loadEmail() -> String {
        return defaults.string(forKey: "email") ?? "user@blackssl.com"
    }
    
    public static func saveLastScrapeResult(_ result: String) {
        defaults.set(result, forKey: "last_scrape_result")
        defaults.synchronize()
    }
    
    public static func loadLastScrapeResult() -> String {
        return defaults.string(forKey: "last_scrape_result") ?? "No scrape attempt recorded yet."
    }
    
    public static func saveLast1GNotificationDate(_ date: String) {
        defaults.set(date, forKey: "last_1g_notification_date")
        defaults.synchronize()
    }
    
    public static func loadLast1GNotificationDate() -> String? {
        return defaults.string(forKey: "last_1g_notification_date")
    }
    
    public static func clear() {
        defaults.removeObject(forKey: "usage_data")
        defaults.removeObject(forKey: "cookies")
        defaults.removeObject(forKey: "localStorage")
        defaults.removeObject(forKey: "base_host")
        defaults.removeObject(forKey: "subscription_token")
        defaults.removeObject(forKey: "subscription_url")
        defaults.removeObject(forKey: "is_v2board")
        defaults.removeObject(forKey: "email")
        defaults.removeObject(forKey: "last_scrape_result")
        defaults.removeObject(forKey: "last_1g_notification_date")
        defaults.synchronize()
        print("BlackSSLStore: Cleared all stored data.")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    public static func checkAndSendTodayUsageNotification(todayUsed: Int64) {
        let limit: Int64 = 1 * 1024 * 1024 * 1024 // 1 GB in bytes (1024^3)
        guard todayUsed >= limit else {
            print("BlackSSLStore: todayUsed (\(todayUsed)) is below limit (\(limit))")
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        
        if let lastAlertDate = loadLast1GNotificationDate(), lastAlertDate == todayStr {
            let logMsg = "Notification skipped: already sent today (\(todayStr))"
            print("BlackSSLStore: \(logMsg)")
            saveLastScrapeResult(logMsg)
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "BlackSSL: Traffic Alert"
        content.body = "Today's usage has exceeded 1G."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "TodayUsageLimitAlert", content: content, trigger: trigger)
        
        print("BlackSSLStore: Attempting to send 1G alert notification...")
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                let logMsg = "Failed to send 1G alert notification: \(error.localizedDescription)"
                print("BlackSSLStore: \(logMsg)")
                saveLastScrapeResult(logMsg)
            } else {
                let logMsg = "Sent 1G alert notification successfully on \(todayStr)"
                print("BlackSSLStore: \(logMsg)")
                saveLastScrapeResult(logMsg)
                saveLast1GNotificationDate(todayStr)
            }
        }
    }
}

public final class BlackSSLNetworkManager: Sendable {
    public static let shared = BlackSSLNetworkManager()
    
    private init() {}
    
    public func fetchUsage(completion: @escaping @Sendable (Result<BlackSSLUsageData, Error>) -> Void) {
        let baseHost = BlackSSLStore.loadBaseHost()
        let cookies = BlackSSLStore.loadCookies()
        
        // If we have cookies, try to scrape the dashboard first to get the most detailed info (including today's traffic)
        if let cookies = cookies, !cookies.isEmpty {
            print("BlackSSLNetworkManager: Cookies found. Attempting dashboard scrape first.")
            let dashboardURL = "https://\(baseHost)/dashboard"
            guard let url = URL(string: dashboardURL) else {
                let errorMsg = "Invalid Dashboard URL"
                BlackSSLStore.saveLastScrapeResult("Error: \(errorMsg)")
                completion(.failure(NSError(domain: "BlackSSLNetworkManager", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 10.0
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
            
            let headerFields = HTTPCookie.requestHeaderFields(with: cookies)
            for (key, value) in headerFields {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    let logMsg = "Dashboard scrape error: \(error.localizedDescription)"
                    print("BlackSSLNetworkManager: \(logMsg). Falling back to subscription URL.")
                    BlackSSLStore.saveLastScrapeResult(logMsg)
                    self.fetchViaSubscriptionURL(completion: completion)
                    return
                }
                
                guard let data = data, let html = String(data: data, encoding: .utf8) else {
                    let logMsg = "Failed to convert scrape data to UTF8 string"
                    print("BlackSSLNetworkManager: \(logMsg). Falling back to subscription URL.")
                    BlackSSLStore.saveLastScrapeResult(logMsg)
                    self.fetchViaSubscriptionURL(completion: completion)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    let logMsg = "Response is not HTTPURLResponse"
                    print("BlackSSLNetworkManager: \(logMsg). Falling back to subscription URL.")
                    BlackSSLStore.saveLastScrapeResult(logMsg)
                    self.fetchViaSubscriptionURL(completion: completion)
                    return
                }
                
                print("BlackSSLNetworkManager: Scrape Response Code: \(httpResponse.statusCode), HTML Length: \(html.count)")
                if httpResponse.statusCode != 200 {
                    let logMsg = "Scrape non-200 (Code: \(httpResponse.statusCode)). HTML: \(String(html.prefix(120)))"
                    print("BlackSSLNetworkManager: \(logMsg). Falling back to subscription URL.")
                    BlackSSLStore.saveLastScrapeResult(logMsg)
                    self.fetchViaSubscriptionURL(completion: completion)
                    return
                }
                
                let hasKeywords = html.contains("首页") || html.contains("退出") || html.contains("dashboard") || html.contains("Dashboard")
                if hasKeywords {
                    if let usage = self.parseDashboardHTML(html) {
                        let logMsg = "Success! Today: \(usage.todayUsed != nil ? BlackSSLNetworkManager.formatBytes(usage.todayUsed!) : "nil"), Reset: \(usage.nextResetText ?? "nil")"
                        print("BlackSSLNetworkManager: \(logMsg)")
                        BlackSSLStore.saveLastScrapeResult(logMsg)
                        BlackSSLStore.saveUsageData(usage)
                        
                        if BlackSSLStore.loadSubscriptionURL() == nil {
                            self.bootstrapSubscriptionURL()
                        }
                        
                        WidgetCenter.shared.reloadAllTimelines()
                        completion(.success(usage))
                        return
                    } else {
                        let logMsg = "Keywords found but parsing failed. HTML: \(String(html.prefix(150)))"
                        print("BlackSSLNetworkManager: \(logMsg)")
                        BlackSSLStore.saveLastScrapeResult(logMsg)
                    }
                } else {
                    let logMsg = "Keywords not found (unauthorized/SPA). HTML: \(String(html.prefix(150)))"
                    print("BlackSSLNetworkManager: \(logMsg)")
                    BlackSSLStore.saveLastScrapeResult(logMsg)
                }
                
                self.fetchViaSubscriptionURL(completion: completion)
            }
            task.resume()
        } else {
            // No cookies, go straight to subscription URL
            BlackSSLStore.saveLastScrapeResult("No cookies found. Directly fetching via subscription URL.")
            self.fetchViaSubscriptionURL(completion: completion)
        }
    }
    
    private func bootstrapSubscriptionURL() {
        let baseHost = BlackSSLStore.loadBaseHost()
        let manualsURL = "https://\(baseHost)/manuals/ssl/shadowrocket"
        guard let url = URL(string: manualsURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15.0
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        if let cookies = BlackSSLStore.loadCookies() {
            let headerFields = HTTPCookie.requestHeaderFields(with: cookies)
            for (key, value) in headerFields {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data, let html = String(data: data, encoding: .utf8) else { return }
            if let subURL = self.extractSubscriptionURLFromManuals(html) {
                print("BlackSSLNetworkManager: Background bootstrap: Subscription URL successfully extracted: \(subURL)")
                BlackSSLStore.saveSubscriptionURL(subURL)
                if let email = self.extractEmail(from: html) {
                    BlackSSLStore.saveEmail(email)
                }
            }
        }
        task.resume()
    }
    
    private func fetchViaSubscriptionURL(completion: @escaping (Result<BlackSSLUsageData, Error>) -> Void) {
        let baseHost = BlackSSLStore.loadBaseHost()
        if let subscriptionURL = BlackSSLStore.loadSubscriptionURL() {
            print("BlackSSLNetworkManager: Fetching via subscription traffic URL: \(subscriptionURL)")
            guard let url = URL(string: subscriptionURL) else {
                completion(.failure(NSError(domain: "BlackSSLNetworkManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Subscription URL"])))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 15.0
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
            
            let task = URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("BlackSSLNetworkManager: Subscription fetch network error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NSError(domain: "BlackSSLNetworkManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "No HTTP Response"])))
                    return
                }
                
                print("BlackSSLNetworkManager: Subscription response status code: \(httpResponse.statusCode)")
                
                var userInfoHeader: String? = nil
                for (key, value) in httpResponse.allHeaderFields {
                    if let keyStr = key as? String, keyStr.lowercased() == "subscription-userinfo" {
                        userInfoHeader = value as? String
                        break
                    }
                }
                
                guard let headerValue = userInfoHeader,
                      let parsed = self.parseSubscriptionUserInfo(headerValue) else {
                    BlackSSLStore.defaults.removeObject(forKey: "subscription_url")
                    BlackSSLStore.defaults.removeObject(forKey: "subscription_token")
                    completion(.failure(NSError(domain: "BlackSSLNetworkManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Subscription header not found or invalid"])))
                    return
                }
                
                let usage = BlackSSLUsageData(
                    upload: parsed.upload,
                    download: parsed.download,
                    total: parsed.total,
                    expiredAt: parsed.expire,
                    email: BlackSSLStore.loadEmail(),
                    lastUpdated: Date(),
                    isLoggedIn: true,
                    todayUsed: BlackSSLStore.loadUsageData()?.todayUsed,
                    nextResetText: BlackSSLStore.loadUsageData()?.nextResetText
                )
                
                BlackSSLStore.saveUsageData(usage)
                WidgetCenter.shared.reloadAllTimelines()
                completion(.success(usage))
            }
            task.resume()
        } else {
            // If no subscription URL, bootstrapping is needed - we try manuals page using cookies
            let manualsURL = "https://\(baseHost)/manuals/ssl/shadowrocket"
            print("BlackSSLNetworkManager: No subscription URL saved. Requesting manuals page. URL: \(manualsURL)")
            guard let url = URL(string: manualsURL) else {
                completion(.failure(NSError(domain: "BlackSSLNetworkManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Manuals URL"])))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 15.0
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
            
            if let cookies = BlackSSLStore.loadCookies() {
                let headerFields = HTTPCookie.requestHeaderFields(with: cookies)
                for (key, value) in headerFields {
                    request.setValue(value, forHTTPHeaderField: key)
                }
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    print("BlackSSLNetworkManager: Manuals fetch failed: \(error.localizedDescription). Trying dashboard fallback.")
                    self.fallbackToDashboardScrape(completion: completion)
                    return
                }
                
                guard let data = data, let html = String(data: data, encoding: .utf8) else {
                    self.fallbackToDashboardScrape(completion: completion)
                    return
                }
                
                if let subURL = self.extractSubscriptionURLFromManuals(html) {
                    print("BlackSSLNetworkManager: Scraped subscription URL from manuals: \(subURL)")
                    BlackSSLStore.saveSubscriptionURL(subURL)
                    if let email = self.extractEmail(from: html) {
                        BlackSSLStore.saveEmail(email)
                    }
                    self.fetchViaSubscriptionURL(completion: completion)
                } else {
                    print("BlackSSLNetworkManager: No sub URL in manuals. Falling back to dashboard scrape.")
                    self.fallbackToDashboardScrape(completion: completion)
                }
            }
            task.resume()
        }
    }
    
    private func fallbackToDashboardScrape(completion: @escaping (Result<BlackSSLUsageData, Error>) -> Void) {
        let baseHost = BlackSSLStore.loadBaseHost()
        let dashboardURL = "https://\(baseHost)/dashboard"
        print("BlackSSLNetworkManager: Falling back to scraping dashboard directly. URL: \(dashboardURL)")
        guard let url = URL(string: dashboardURL) else {
            completion(.failure(NSError(domain: "BlackSSLNetworkManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Dashboard URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15.0
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        // Inject Cookies
        if let cookies = BlackSSLStore.loadCookies() {
            let headerFields = HTTPCookie.requestHeaderFields(with: cookies)
            for (key, value) in headerFields {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("BlackSSLNetworkManager: Dashboard scrape network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "BlackSSLNetworkManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to read dashboard HTML"])))
                return
            }
            
            if let usage = self.parseDashboardHTML(html) {
                print("BlackSSLNetworkManager: Successfully scraped usage from dashboard! Total: \(usage.total), Used: \(usage.used)")
                BlackSSLStore.saveUsageData(usage)
                WidgetCenter.shared.reloadAllTimelines()
                completion(.success(usage))
            } else {
                print("BlackSSLNetworkManager: Error - Failed to parse dashboard HTML.")
                completion(.failure(NSError(domain: "BlackSSLNetworkManager", code: -4, userInfo: [NSLocalizedDescriptionKey: "Could not parse traffic data from dashboard"])))
            }
        }
        task.resume()
    }
    
    private func parseSubscriptionUserInfo(_ headerValue: String) -> (upload: Int64, download: Int64, total: Int64, expire: Int64?)? {
        let pairs = headerValue.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }
        var upload: Int64 = 0
        var download: Int64 = 0
        var total: Int64 = 0
        var expire: Int64? = nil
        
        for pair in pairs {
            let parts = pair.split(separator: "=", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                let key = parts[0].lowercased()
                let valStr = parts[1]
                if let val = Int64(valStr) {
                    switch key {
                    case "upload": upload = val
                    case "download": download = val
                    case "total", "totl": total = val
                    case "expire":
                        if val > 0 {
                            expire = val
                        }
                    default: break
                    }
                }
            }
        }
        return (upload, download, total, expire)
    }
    
    private func extractSubscriptionURLFromManuals(_ html: String) -> String? {
        // Look for sub://base64
        let pattern = "sub://([a-zA-Z0-9+/=]{16,128})"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                if match.numberOfRanges > 1 {
                    let base64String = nsString.substring(with: match.range(at: 1))
                    if let decodedData = Data(base64Encoded: base64String),
                       let urlString = String(data: decodedData, encoding: .utf8) {
                        return urlString
                    }
                }
            }
        }
        
        // Alternative: Look for crown://login?...token=XXXX
        let crownPattern = "crown://login\\?[^\"]*token=([a-zA-Z0-9]{10,64})"
        if let regex = try? NSRegularExpression(pattern: crownPattern, options: []) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                if match.numberOfRanges > 1 {
                    let token = nsString.substring(with: match.range(at: 1))
                    return "https://api.darkssl.com/v1/cfg/\(token)/sr/Crown.conf"
                }
            }
        }
        
        return nil
    }
    
    private func parseDashboardHTML(_ html: String) -> BlackSSLUsageData? {
        var usedBytes: Int64 = 0
        var totalBytes: Int64 = 0
        var expiredAt: Int64? = nil
        var email = BlackSSLStore.loadEmail()
        
        // 1. Parse Email: "email": "iAugux@gmail.com"
        let emailPattern = "\"email\"\\s*:\\s*\"([^\"]+)\""
        if let regex = try? NSRegularExpression(pattern: emailPattern, options: []),
           let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count)) {
            let nsString = html as NSString
            email = nsString.substring(with: match.range(at: 1))
            BlackSSLStore.saveEmail(email)
        }
        
        // 2. Parse Expiration Date: "到期时间" ... "2026-12-04"
        let datePattern = "到期时间.*?([0-9]{4}-[0-9]{2}-[0-9]{2})"
        if let regex = try? NSRegularExpression(pattern: datePattern, options: [.dotMatchesLineSeparators]),
           let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count)) {
            let nsString = html as NSString
            let dateString = nsString.substring(with: match.range(at: 1))
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = formatter.date(from: dateString) {
                expiredAt = Int64(date.timeIntervalSince1970)
            }
        }
        
        // 3. Parse Traffic Quota: 已用 29.09 GB / 30 GB (96.98%)
        let trafficPattern = "已用\\s*([0-9.]+)\\s*(KB|MB|GB|TB)\\s*/\\s*([0-9.]+)\\s*(KB|MB|GB|TB)"
        if let regex = try? NSRegularExpression(pattern: trafficPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count)) {
            let nsString = html as NSString
            let usedVal = Double(nsString.substring(with: match.range(at: 1))) ?? 0.0
            let usedUnit = nsString.substring(with: match.range(at: 2)).uppercased()
            let totalVal = Double(nsString.substring(with: match.range(at: 3))) ?? 0.0
            let totalUnit = nsString.substring(with: match.range(at: 4)).uppercased()
            
            usedBytes = convertToBytes(value: usedVal, unit: usedUnit)
            totalBytes = convertToBytes(value: totalVal, unit: totalUnit)
        } else {
            print("BlackSSLNetworkManager: Failed to parse traffic quota using standard pattern.")
            return nil
        }
        
        // 4. Parse Today's Traffic: 今日流量 ... 已用 653.85 MB (1 天后重置)
        var todayUsedBytes: Int64? = nil
        var nextResetText: String? = nil
        let todayPattern = "今日流量.*?已用\\s*([0-9.]+)\\s*(KB|MB|GB|TB)(?:\\s*[(（]([^)）]+)[)）])?"
        if let regex = try? NSRegularExpression(pattern: todayPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
           let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count)) {
            let nsString = html as NSString
            let val = Double(nsString.substring(with: match.range(at: 1))) ?? 0.0
            let unit = nsString.substring(with: match.range(at: 2)).uppercased()
            todayUsedBytes = convertToBytes(value: val, unit: unit)
            
            if match.numberOfRanges > 3 {
                let range = match.range(at: 3)
                if range.location != NSNotFound {
                    nextResetText = nsString.substring(with: range)
                }
            }
        }
        
        return BlackSSLUsageData(
            upload: 0,
            download: usedBytes,
            total: totalBytes,
            expiredAt: expiredAt,
            email: email,
            lastUpdated: Date(),
            isLoggedIn: true,
            todayUsed: todayUsedBytes,
            nextResetText: nextResetText
        )
    }
    
    private func convertToBytes(value: Double, unit: String) -> Int64 {
        let multiplier: Double
        switch unit {
        case "KB": multiplier = 1024
        case "MB": multiplier = 1024 * 1024
        case "GB": multiplier = 1024 * 1024 * 1024
        case "TB": multiplier = 1024 * 1024 * 1024 * 1024
        default: multiplier = 1
        }
        return Int64(value * multiplier)
    }
    
    private func extractEmail(from html: String) -> String? {
        let pattern = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,64}"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                let email = nsString.substring(with: match.range)
                if !email.contains("w3.org") && !email.contains("example.com") {
                    return email
                }
            }
        }
        return nil
    }
    
    public static func formatBytes(_ bytes: Int64) -> String {
        let gb = Double(bytes) / (1024.0 * 1024.0 * 1024.0)
        if gb >= 1.0 {
            return String(format: "%.2f GB", gb)
        }
        let mb = Double(bytes) / (1024.0 * 1024.0)
        return String(format: "%.2f MB", mb)
    }
}


