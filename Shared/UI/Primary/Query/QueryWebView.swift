//
//  QueryWebView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 13/9/2022.
//

import SwiftUI
import ShareSheetView

struct QueryWebView: View {
    enum PendingJob {
        case file(URL)
        case uri(URL)

        func action(location: String?) -> AsyncAction {
            switch self {
            case let .uri(url):
                return .command(.addURI(url.absoluteString, location: location))
            case let .file(url):
                return .reuploadFile(url, location: location)
            }
        }
    }
    
    let dispatch = Global.store.writeOnly(async: { $0 })
    @StateObject var webViewStore = WebViewStore()
    @Environment(\.dismiss) var dismiss
    let initialUrl: URL?
    @State var showAddQuery = false
    @State var viewWidth = CGFloat.zero
    @State var urlString = ""
    @State var pendingJob: PendingJob?
    @State private var isShareSheetViewPresented = false
    @FocusState private var urlFocused: Bool
    
    init(url: URL?) {
        initialUrl = url
    }

    init(url: String) {
        self.init(url: URL(string: url))
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
            showAddQuery = true
        } label: {
            SystemImage.plusMagnifyingglass
        }
        .opacity(
            (URL(string: urlString) != nil).if(
                true: 1,
                false: 0
            )
        )
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
    
    func onAppear() {
        if urlString.isEmpty {
            urlFocused = true
        }
    }

    func onLoad() {
        urlString ?= initialUrl?.absoluteString
        webViewStore.tryLoad(url: initialUrl)
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
            .onLoad(perform: onLoad)
            .onAppear(perform: onAppear)
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
                    Button(
                        image: webViewStore.isLoading.if(
                            true: .xmark,
                            false: .arrowClockwise
                        )
                    ) {
                        if webViewStore.isLoading {
                            webViewStore.webView.stopLoading()
                        } else {
                            webViewStore.webView.reload()
                        }
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.secondary)
                .background(.regularMaterial)
        )
        .padding(.horizontal, 10)
        .sheet(isPresented: $showAddQuery) {
            if let url = URL(string: urlString) {
                NavigationStack {
                    ExplodedUrlView(url: url, showModal: $showAddQuery)
                }
            }
        }
    }
    
    func addURI(_ url: URL, location: String?) {
        dispatch(
            async: .command(.addURI(url.absoluteString, location: location))
        )
    }
    
    func addFile(_ url: URL, location: String?) {
        dispatch(
            async: .reuploadFile(url, location: location)
        )
    }

    var body: some View {
        VStack(spacing: .zero) {
            StoreView({
                $0.persistent.selectedServer?.downloadDirectories ?? []
            }) { directories, dispatch in
                WebView(webView: webViewStore.webView) {
                    urlString ?= $0?.absoluteString
                } addURI: {
                    let pending = PendingJob.uri($0)
                    if directories.count > 1 {
                        pendingJob = pending
                    } else {
                        dispatch(async: pending.action(location: directories.first))
                    }
                } addFile: {
                    let pending = PendingJob.file($0)
                    if directories.count > 1 {
                        pendingJob = pending
                    } else {
                        dispatch(async: pending.action(location: directories.first))
                    }
                }
                .alert(
                    "Select Location",
                    isPresented: $pendingJob.isPresent()
                ) {
                    if let pending = pendingJob {
                        ForEach(directories.sorted(), id: \.self) { directory in
                            Button(
                                directory.split(
                                    separator: "/",
                                    omittingEmptySubsequences: false
                                )
                                .last!
                            ) {
                                dispatch(async: pending.action(location: directory))
                            }
                        }
                        Button("Default") {
                            dispatch(async: pending.action(location: nil))
                        }
                        Button("Cancel", role: .cancel) {
                        }
                    }
                }
            }

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
                HStack {
                    toolbar
                }
                .font(.title)
                .padding(.horizontal, 24)
                .backgroundStyle(.secondary)
                Divider()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                Text(webViewStore.title ?? "")
                    .bold()
                    .lineLimit(1)
            }
        }
    }
}
