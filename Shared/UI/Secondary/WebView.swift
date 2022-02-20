//
//  WebView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 17/2/22.
//

import SwiftUI
import WebKit
import ShareSheetView

struct Query {
    enum Component: Codable, Hashable, CustomStringConvertible {
        case string(String)
        case query
        
        var description: String {
            switch self {
            case let .string(string):
                return string
            case .query:
                return "Query"
            }
        }
    }

    enum SpaceCharacter: Character, Hashable, CaseIterable {
        case space = " "
        case plus = "+"
    }
    
    struct QueryItem: Codable, CustomStringConvertible {
        var name: String
        var value: Component
        
        var description: String {
            "\(name) = \(value.description)"
        }
    }

    let space: SpaceCharacter
    let base: URL
    let path: [Component]
    let queryItems: [QueryItem]
    
    func url(for query: String) -> URL? {
        let query = query.replacingOccurrences(of: " ", with: String(space.rawValue))
        func string(for component: Component) -> String {
            switch component {
            case .string(let string):
                return string
            case .query:
                return query
            }
        }
        
        var url = URLComponents(url: base, resolvingAgainstBaseURL: true)
        url?.path = path
            .map(string(for:))
            .map("/"+)
            .joined()
        url?.queryItems = queryItems.map { item in
            .init(
                name: item.name,
                value: string(for: item.value)
            )
        }
        
        return base
    }
}

struct WebView: View {
    @State var urlString = ""
    @State private var isShareSheetViewPresented = false
    @FocusState private var urlFocused: Bool
    @StateObject private var model: WebViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    init(url: String) {
        _model = .init(wrappedValue: WebViewModel(url: url))
        urlString = url
    }
    
    func sanitiseURL() {
        let validSchemes = ["https", "http"].map({ "\($0)://"})
        if !validSchemes.contains(where: urlString.hasPrefix) {
            urlString = validSchemes[0] + urlString
        }
    }
    
    func submit() {
        sanitiseURL()
        model.urlString = urlString
        model.loadUrl()
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .trailing) {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Done").bold()
                    }
                }
                .padding(16)
                HStack {
                    TextField("Enter website URL", text: $urlString)
                        .focused($urlFocused)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .submitLabel(.go)
                        .onSubmit(submit)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Dismiss") {
                                    urlFocused = false
                                }
                            }
                        }
                    if !urlString.isEmpty, urlFocused {
                        Spacer()
                        Button {
                            urlString.removeAll()
                        } label: {
                            SystemImage.xmarkCircleFill
                        }
                        .tint(.secondary)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(.secondary)
                )
                .padding(10)
                
                Divider()
                
                WebViewRepresentable(webView: model.webView)
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        model.goBack()
                    } label: {
                        SystemImage.chevronLeft
                    }
                    .disabled(!model.canGoBack)
                    Spacer()
                    Button {
                        model.goForward()
                    } label: {
                        SystemImage.chevronRight
                    }
                    .disabled(!model.canGoForward)
                    Spacer()
                    Button {
                        if model.isLoading {
                            model.stopLoading()
                        } else {
                            model.reload()
                        }
                    } label: {
                        if model.isLoading {
                            SystemImage.xmark
                        } else {
                            SystemImage.arrowClockwise
                        }
                    }
                    Spacer()
                    Button {
                        isShareSheetViewPresented = true
                    } label: {
                        SystemImage.squareAndArrowUp
                    }
                    .sheet(isPresented: $isShareSheetViewPresented) {
                        if let url = model.webView.url {
                            ShareSheetView(activityItems: [url])
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .interactiveDismissDisabled()
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    typealias UIViewType = WKWebView
    
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) { }
}

class WebViewModel: ObservableObject {
    let webView: WKWebView
    
    // outputs
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var urlString: String = ""
    
    init(url: String) {
        webView = WKWebView(frame: .zero)
        urlString = url
        webView.publisher(for: \.canGoBack)
            .assign(to: &$canGoBack)
        webView.publisher(for: \.canGoForward)
            .assign(to: &$canGoForward)
        webView.publisher(for: \.isLoading)
            .assign(to: &$isLoading)
        loadUrl()
    }

    func loadUrl() {
        guard let url = URL(string: urlString) else {
            return
        }
        
        webView.load(URLRequest(url: url))
    }
    
    func goForward() {
        webView.goForward()
    }
    
    func goBack() {
        webView.goBack()
    }
    
    func reload() {
        webView.reload()
    }
    
    func stopLoading() {
        webView.stopLoading()
        isLoading = false
    }
}
