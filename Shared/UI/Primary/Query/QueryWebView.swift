//
//  QueryWebView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 13/9/2022.
//

import SwiftUI
import Recombine
import Overture

enum PendingJob: Hashable, Codable {
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

struct QueryWebView: View {
    let dispatch = Global.store.writeOnly(async: { $0 })
    @StateObject var webViewStore = WebViewStore()
    @Environment(\.dismiss) var dismiss
    let initialUrl: URL?
    @State var showAddQuery = false

    @State var viewWidth = CGFloat.zero
    @State var urlString = ""
    @State var pendingJob: PendingJob?
    @State private var isShareSheetViewPresented = false
    @State private var isOutboxPresented = false
    @FocusState private var urlFocused: Bool

    init(url: URL?) {
        initialUrl = url
    }

    init(url: String) {
        self.init(url: URL(string: url))
    }

    func sanitiseURL() {
        if !urlString.starts(with: /https?:\/\//) {
            urlString = "https://" + urlString
        }
    }

    func submit() {
        sanitiseURL()
        webViewStore.tryLoad(string: urlString)
    }
    
    @ViewBuilder
    var toolbarItems: some View {
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
                ShareLink(item: url)
            }
        }
    }
    
    var toolbar: some View {
        HStack {
            toolbarItems
        }
        .font(.title)
        .padding(.horizontal, 24)
        .backgroundStyle(.secondary)
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
    
    var progressBar: some View {
        ProgressBar(
            value: .init(
                0...1,
                initialValue: modf(webViewStore.estimatedProgress).1
            )
        )
        .foregroundColor(.accentColor)
    }
    
    @ViewBuilder
    func alertActions(directories: [String]) -> some View {
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

    func addJob(directories: [String], type: WebView.AddJobType, url: URL) {
        let pending: PendingJob
        switch type {
        case .uri:
            pending = .uri(url)
        case .file:
            pending = .file(url)
        }
        if directories.count > 1 {
            pendingJob = pending
        } else {
            dispatch(async: pending.action(location: directories.first))
        }
    }

    func webView(
        for directories: [String],
        dispatch: ActionLens<AsyncAction, SyncAction>
    ) -> some View {
        WebView(
            webView: webViewStore.webView,
            urlDidChange: {
                urlString ?= $0?.absoluteString
            },
            addJob: uncurry(curry(addJob)(directories))
        )
        .alert(
            "Select Location",
            isPresented: $pendingJob.isPresent()
        ) {
           alertActions(directories: directories)
        }
    }

    var body: some View {
        VStack(spacing: .zero) {
            StoreView {
                $0.persistent.selectedServer?.destinations ?? []
            } content: {
                webView(for: Array($0), dispatch: $1)
            }
            VStack {
                urlView
                progressBar
                toolbar
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
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                OutboxButton(count: 0, binding: $isOutboxPresented)
            }
        }
    }
}

struct OutboxButton: View {
    let count: Int
    @Binding var binding: Bool

    var badgeSystemName: String {
        (count <= 50).if(
            true: "\(count).circle.fill",
            false: "exclamationmark.circle.fill"
        )
    }

    var body: some View {
        Button(image: .outbox, binding: $binding)
            .padding(.trailing, 10)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: badgeSystemName)
                    .foregroundStyle(.white, .clear, .red)
                    .font(.footnote)
            }
    }
}
