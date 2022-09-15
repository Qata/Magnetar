//
//  WebView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 17/2/22.
//

import SwiftUI
import WebKit

@dynamicMemberLookup
public class WebViewStore: ObservableObject {
    @Published public var webView: WKWebView {
        didSet {
            setupObservers()
        }
    }

    public init(webView: WKWebView = WKWebView()) {
        self.webView = webView
        setupObservers()
    }

    private func setupObservers() {
        func subscriber<Value>(for keyPath: KeyPath<WKWebView, Value>) -> NSKeyValueObservation {
            return webView.observe(keyPath, options: [.prior]) { _, change in
                if change.isPrior {
                    self.objectWillChange.send()
                }
            }
        }
        // Setup observers for all KVO compliant properties
        observers = [
            subscriber(for: \.title),
            subscriber(for: \.url),
            subscriber(for: \.isLoading),
            subscriber(for: \.estimatedProgress),
            subscriber(for: \.hasOnlySecureContent),
            subscriber(for: \.serverTrust),
            subscriber(for: \.canGoBack),
            subscriber(for: \.canGoForward)
        ]
        if #available(iOS 15.0, macOS 12.0, *) {
            observers += [
                subscriber(for: \.themeColor),
                subscriber(for: \.underPageBackgroundColor),
                subscriber(for: \.microphoneCaptureState),
                subscriber(for: \.cameraCaptureState)
            ]
        }
#if swift(>=5.7)
        if #available(iOS 16.0, macOS 13.0, *) {
            observers.append(subscriber(for: \.fullscreenState))
        }
#else
        if #available(iOS 15.0, macOS 12.0, *) {
            observers.append(subscriber(for: \.fullscreenState))
        }
#endif
    }

    private var observers: [NSKeyValueObservation] = []

    public subscript<T>(dynamicMember keyPath: KeyPath<WKWebView, T>) -> T {
        webView[keyPath: keyPath]
    }
}

public class WebViewCoordinator: NSObject, WKNavigationDelegate {
    public let urlDidChange: (URL?) -> Void
    public let addURI: (URL) -> Void
    public let addFile: (URL) -> Void

    public init(
        urlDidChange: @escaping (URL?) -> Void,
        addURI: @escaping (URL) -> Void,
        addFile: @escaping (URL) -> Void
    ) {
        self.urlDidChange = urlDidChange
        self.addURI = addURI
        self.addFile = addFile
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        urlDidChange(webView.url)
    }

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        var action: WKNavigationActionPolicy?
        defer {
            decisionHandler(action ?? .allow)
        }
        guard let url = navigationAction.request.url,
              let api = Global.store.state.persistent.selectedServer?.api
        else { return }

        for uri in api.supportedURIs {
            switch uri {
            case .scheme(url.scheme), .pathExtension(url.pathExtension):
                action = .cancel
                return addURI(url)
            default:
                break
            }
        }
        
        if api.supportedPathExtensions.contains(url.pathExtension) {
            action = .cancel
            return addFile(url)
        }
    }
}

#if os(iOS)
/// A container for using a WKWebView in SwiftUI
public struct WebView: View, UIViewRepresentable {
    /// The WKWebView to display
    public let webView: WKWebView
    public let urlDidChange: (URL?) -> Void
    public let addURI: (URL) -> Void
    public let addFile: (URL) -> Void
    
    public init(
        webView: WKWebView,
        urlDidChange: @escaping (URL?) -> Void,
        addURI: @escaping (URL) -> Void,
        addFile: @escaping (URL) -> Void
    ) {
        self.webView = webView
        self.urlDidChange = urlDidChange
        self.addURI = addURI
        self.addFile = addFile
    }
    
    public func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(
            urlDidChange: urlDidChange,
            addURI: addURI,
            addFile: addFile
        )
    }
    
    public func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<WebView>) {
    }
}
#endif

#if os(macOS)
/// A container for using a WKWebView in SwiftUI
public struct WebView: View, NSViewRepresentable {
    /// The WKWebView to display
    public let webView: WKWebView
    
    public init(webView: WKWebView) {
        self.webView = webView
    }
    
    public func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator()
    }
    
    public func makeNSView(context: NSViewRepresentableContext<WebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    public func updateNSView(_ uiView: WKWebView, context: NSViewRepresentableContext<WebView>) {
    }
}
#endif

extension WebViewStore {
    func tryLoad(string: String) {
        guard let url = URL(string: string) else { return }
        webView.load(.init(url: url))
    }
    
    func tryLoad(url: URL?) {
        guard let url = url else { return }
        webView.load(.init(url: url))
    }
}

//struct WebViewRepresentable: UIViewRepresentable {
//    typealias UIViewType = WKWebView
//    
//    let webView: WKWebView
//    
//    func makeUIView(context: Context) -> WKWebView {
//        return webView
//    }
//    
//    func updateUIView(_ uiView: WKWebView, context: Context) { }
//}
//
//class WebViewModel: ObservableObject {
//    let webView: WKWebView
//    
//    @Published var urlString: String = ""
//    @Published var canGoBack: Bool = false
//    @Published var canGoForward: Bool = false
//    @Published var isLoading: Bool = false
//    
//    init(url: String) {
//        webView = WKWebView(frame: .zero)
//        urlString = url
//        webView.publisher(for: \.canGoBack)
//            .assign(to: &$canGoBack)
//        webView.publisher(for: \.canGoForward)
//            .assign(to: &$canGoForward)
//        webView.publisher(for: \.isLoading)
//            .assign(to: &$isLoading)
//        loadUrl()
//    }
//
//    func loadUrl() {
//        guard let url = URL(string: urlString) else {
//            return
//        }
//        
//        webView.load(URLRequest(url: url))
//    }
//    
//    func goForward() {
//        webView.goForward()
//    }
//    
//    func goBack() {
//        webView.goBack()
//    }
//    
//    func reload() {
//        webView.reload()
//    }
//    
//    func stopLoading() {
//        webView.stopLoading()
//        isLoading = false
//    }
//}
