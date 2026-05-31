// Created by Augus on 5/30/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI
import WebKit

#if os(macOS)
import AppKit
public typealias PlatformViewRepresentable = NSViewRepresentable
#else
import UIKit
public typealias PlatformViewRepresentable = UIViewRepresentable
#endif

public struct WebView: PlatformViewRepresentable {
    public let url: URL
    public let onCookieAndStorageCaptured: ([HTTPCookie], [String: String], String) -> Void
    
    public init(url: URL, onCookieAndStorageCaptured: @escaping ([HTTPCookie], [String: String], String) -> Void) {
        self.url = url
        self.onCookieAndStorageCaptured = onCookieAndStorageCaptured
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        nonisolated(unsafe) var timer: Timer?
        weak var webView: WKWebView?
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        deinit {
            let t = timer
            DispatchQueue.main.async {
                t?.invalidate()
            }
        }
        
        func startTracking(webView: WKWebView) {
            self.webView = webView
            // Perform cookie/storage extraction every 1.0 second to handle dynamic/AJAX logins smoothly
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.captureData()
                }
            }
        }
        
        func stopTracking() {
            let t = timer
            DispatchQueue.main.async {
                t?.invalidate()
            }
            timer = nil
        }
        
        func captureData() {
            guard let webView = webView, let currentURL = webView.url, let host = currentURL.host else { return }
            
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
                guard let self = self else { return }
                
                let allCookies = cookies
                
                // Extract localStorage
                webView.evaluateJavaScript("""
                (function() {
                    var keys = {};
                    for (var i = 0; i < localStorage.length; i++) {
                        var k = localStorage.key(i);
                        keys[k] = localStorage.getItem(k);
                    }
                    return keys;
                })()
                """) { [weak self] result, error in
                    guard let self = self else { return }
                    var storageDict = [String: String]()
                    if let dict = result as? [String: Any] {
                        for (k, v) in dict {
                            storageDict[k] = String(describing: v)
                        }
                    }
                    
                    self.parent.onCookieAndStorageCaptured(allCookies, storageDict, host)
                }
            }
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            captureData()
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    #if os(macOS)
    public func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.startTracking(webView: webView)
        
        // Clear previous website data to force user to login page
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) {
            webView.load(URLRequest(url: self.url))
        }
        return webView
    }
    
    public func updateNSView(_ nsView: WKWebView, context: Context) {}
    #else
    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.startTracking(webView: webView)
        
        // Clear previous website data to force user to login page
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) {
            webView.load(URLRequest(url: self.url))
        }
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {}
    #endif
}
