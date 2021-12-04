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

struct WKWebViewWrapper: UIViewRepresentable {

    typealias UIViewType = WKWebView

    private let pageName: String

    private let location: String?

    init(_ pageName: String, _ location: String? = nil) {
        debug("WKWebViewWrapper", "init pageName=\(pageName), location=\(location ?? "nil")")

        self.pageName = pageName
        self.location = location
    }

    func makeUIView(context: Context) -> WKWebView {
        let wkWebView = WKWebView()
        // wkWebView.navigationDelegate = context.coordinator

        // avoid the white flash
        wkWebView.isOpaque = false

        // Keep the quicklinks from scrolling
        wkWebView.scrollView.isScrollEnabled = false

        loadPage(wkWebView)
        return wkWebView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // print("updateUIView uiView=\(uiView)")
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {

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

struct WKWebViewWrapper: NSViewRepresentable {

    public typealias NSViewType = WKWebView

    private let pageName: String

    private let location: String?

    init(_ pageName: String, _ location: String? = nil) {
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

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // TODO
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {

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

    func loadPage(_ webView: WKWebView) {
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

