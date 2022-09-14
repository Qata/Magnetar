//
//  WebViewSheet.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 13/9/2022.
//

import SwiftUI
import ShareSheetView

struct WebViewSheet: View {
    @StateObject var webViewStore = WebViewStore()
    
    @Environment(\.dismiss) var dismiss
    let initialUrl: URL?
    @State var showAddQuery = false
    @State var viewWidth = CGFloat.zero
    @State var urlString = ""
    @State private var isShareSheetViewPresented = false
    @FocusState private var urlFocused: Bool
    
    init(url: String) {
        initialUrl = URL(string: url)
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
        webViewStore.tryLoad(string: urlString)
    }
    
    @ViewBuilder
    var toolbar: some View {
        Button {
            webViewStore.webView.goBack()
        } label: {
            SystemImage.chevronLeft
        }
        .disabled(!webViewStore.canGoBack)
        Spacer()
        Button {
            webViewStore.webView.goForward()
        } label: {
            SystemImage.chevronRight
        }
        .disabled(!webViewStore.canGoForward)
        Spacer()
        Spacer()
        Spacer()
        Button {
            if webViewStore.isLoading {
                webViewStore.webView.stopLoading()
            } else {
                webViewStore.webView.reload()
            }
        } label: {
            if webViewStore.isLoading {
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
            if let url = webViewStore.url {
                ShareSheetView(activityItems: [url])
            }
        }
    }
    
    var urlTextField: some View {
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
            .onAppear {
                if initialUrl != nil {
                    webViewStore.tryLoad(url: initialUrl)
                } else {
                    urlFocused = true
                }
            }
    }
    
    var urlView: some View {
        HStack {
            urlTextField
            if !urlString.isEmpty {
                Spacer()
                if urlFocused {
                    Button {
                        urlString.removeAll()
                    } label: {
                        SystemImage.xmarkCircleFill
                    }
                    .tint(.secondary)
                } else {
                    if URL(string: urlString) != nil {
                        Button {
                            showAddQuery = true
                        } label: {
                            SystemImage.plusCircle
                        }
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.secondary)
        )
        .padding(.horizontal, 10)
        .sheet(isPresented: $showAddQuery) {
            if let url = URL(string: urlString) {
                NavigationView {
                    ExplodedUrlView(url: url, showModal: $showAddQuery)
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            urlView
            ZStack {
                Divider()
                    .readSize {
                        viewWidth = $0.width
                    }
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(
                        width: modf(webViewStore.estimatedProgress).1 * viewWidth,
                        height: 2
                    )
            }
            
            WebView(webView: webViewStore.webView) {
                urlString = $0?.absoluteString ?? ""
            }
        }
        .navigationTitle(webViewStore.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                toolbar
            }
        }
    }
}
