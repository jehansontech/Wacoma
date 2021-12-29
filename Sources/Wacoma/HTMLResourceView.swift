//
//  HTMLResourceView.swift
//  Wacoma
//
//  Created by Jim Hanson on 12/4/21.
//

import SwiftUI
import WebKit

#if os(iOS)

public struct HTMLResourceView: UIViewRepresentable {

    public typealias UIViewType = WKWebView

    public let resource: String

    public let anchor: String?

    public init(_ resource: String, _ anchor: String? = nil) {
        debug("HTMLResourceView", "init resource: \(resource), anchor: \(anchor ?? "nil")")
        self.resource = resource
        self.anchor = anchor
    }

    public func makeUIView(context: Context) -> WKWebView {
        let wkWebView = WKWebView()
        // wkWebView.navigationDelegate = context.coordinator

        // avoid the white flash
        wkWebView.isOpaque = false

        // Keep the quicklinks from scrolling
        wkWebView.scrollView.isScrollEnabled = false

        loadResource(wkWebView)
        return wkWebView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        // NOP
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    public class Coordinator: NSObject, WKNavigationDelegate {

        let parent: HTMLResourceView

        init(_ parent: HTMLResourceView) {
            self.parent = parent
        }
    }
}

#elseif os(macOS)

public struct HTMLResourceView: NSViewRepresentable {

    public typealias NSViewType = WKWebView

    public let resource: String

    public let anchor: String?

    public init(_ resource: String, _ anchor: String? = nil) {
        debug("HTMLResourceView", "init resource: \(resource), anchor: \(anchor ?? "nil")")
        self.resource = resource
        self.anchor = anchor
    }

    public func makeNSView(context: Context) -> WKWebView {
        let wkWebView = WKWebView()
        // wkWebView.navigationDelegate = context.coordinator

        // avoid the white flash
        // wkWebView.isOpaque = false

        // Keep the quicklinks from scrolling
        // wkWebView.scrollView.isScrollEnabled = false

        loadResource(wkWebView)
        return wkWebView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        // NOP
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    public class Coordinator: NSObject, WKNavigationDelegate {

        let parent: HTMLResourceView

        init(_ parent: HTMLResourceView) {
            self.parent = parent
        }
    }
}

#endif

extension HTMLResourceView {

    public func loadResource(_ webView: WKWebView) {
        do {
            guard let resourcePath = Bundle.main.path(forResource: self.resource, ofType: "html")
            else {
                NSLog("Unable to find resource \(resource).html")
                return
            }

            let contents =  try String(contentsOfFile: resourcePath, encoding: .utf8)
            var baseUrl = URL(fileURLWithPath: resourcePath)
            if let fragment = self.anchor {
                var urlComponents = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true)
                urlComponents!.fragment = fragment
                baseUrl = urlComponents!.url!
            }
            debug("HTMLResourceView", "loadResource baseUrl = \(baseUrl)")

            webView.loadHTMLString(contents as String, baseURL: baseUrl)
        }
        catch {
            NSLog("Error loading resource \(resource).html: \(error)")
        }
    }
}

