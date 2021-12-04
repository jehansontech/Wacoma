//
//  WebBrowserView.swift
//  Wacoma
//
//  Created by Jim Hanson on 12/4/21.
//

import Foundation
import SwiftUI
import WebKit

#if os(iOS)

public struct WKWebViewWrapper: UIViewRepresentable {

    public typealias UIViewType = WKWebView

    public let pageName: String

    public let location: String?

    public init(_ pageName: String, _ location: String? = nil) {
        debug("WKWebViewWrapper", "init pageName=\(pageName), location=\(location ?? "nil")")

        self.pageName = pageName
        self.location = location
    }

    public func makeUIView(context: Context) -> WKWebView {
        let wkWebView = WKWebView()
        // wkWebView.navigationDelegate = context.coordinator

        // avoid the white flash
        wkWebView.isOpaque = false

        // Keep the quicklinks from scrolling
        wkWebView.scrollView.isScrollEnabled = false

        loadPage(wkWebView)
        return wkWebView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        // print("updateUIView uiView=\(uiView)")
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    public class Coordinator: NSObject, WKNavigationDelegate {

        let parent: WKWebViewWrapper

        init(_ parent: WKWebViewWrapper) {
            debug("WKWebViewWrapper", "Coordinator init")
            self.parent = parent
        }

        deinit {
            debug("WKWebViewWrapper", "Coordinator deinit")
        }
    }
}

#elseif os(macOS)

public struct WKWebViewWrapper: NSViewRepresentable {

    public typealias NSViewType = WKWebView

    public let pageName: String

    public let location: String?

    public init(_ pageName: String, _ location: String? = nil) {
        debug("WKWebViewWrapper", "init pageName=\(pageName), location=\(location ?? "nil")")

        self.pageName = pageName
        self.location = location
    }

    public func makeNSView(context: Context) -> WKWebView {
        let wkWebView = WKWebView()
        // wkWebView.navigationDelegate = context.coordinator

        // avoid the white flash
        // wkWebView.isOpaque = false

        // Keep the quicklinks from scrolling
        // wkWebView.scrollView.isScrollEnabled = false

        loadPage(wkWebView)
        return wkWebView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        // TODO
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    public class Coordinator: NSObject, WKNavigationDelegate {

        let parent: WKWebViewWrapper

        init(_ parent: WKWebViewWrapper) {
            debug("WKWebViewWrapper", "Coordinator init")
            self.parent = parent
        }

        deinit {
            debug("WKWebViewWrapper", "Coordinator deinit")
        }
    }
}

#endif

///
///
///
extension WKWebViewWrapper {

    public func loadPage(_ webView: WKWebView) {
        do {
            guard let filePath = Bundle.main.path(forResource: pageName, ofType: "html")
            else {
                NSLog("File reading error for page \(pageName)")
                return
            }

            let contents =  try String(contentsOfFile: filePath, encoding: .utf8)
            var baseUrl = URL(fileURLWithPath: filePath)
            if let location = location {
                var urlComponents = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true)
                urlComponents!.fragment = location
                baseUrl = urlComponents!.url!
            }
            debug("WKWebViewWrapper", "loadPage baseUrl = \(baseUrl)")

            webView.loadHTMLString(contents as String, baseURL: baseUrl)
        }
        catch {
            NSLog("File HTML error")
        }
    }
}

