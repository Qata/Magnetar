//
//  AddServerForm.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 19/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import SwiftUI

#if os(macOS)
extension Optional where Wrapped == NSTextContentType {
    static var name: Self {
        nil
    }
    
    static var URL: Self {
        nil
    }
}
#endif

struct AddServerForm: View {
    @State var name: String = ""
    @State var address: String = ""
    @State var port: String = ""
    @State var username: String = ""
    @State var password: String = ""
    @State var api: APIDescriptor?
    
    @State var refreshInterval = Server.Defaults.refreshInterval
    @State var timeoutInterval = Server.Defaults.timeoutInterval

    @State var apis: [APIDescriptor]?
    @State var usedNames: Set<Server.Name> = []

    @State var editingServer: Server?

    @Environment(\.dismiss) var dismiss

    func picker(apis: [APIDescriptor]) -> some View {
        Picker("API", selection: $api) {
            ForEach(apis.sorted(keyPath: \.name), id: \.self) {
                Text($0.name)
                    .tag(Optional($0))
            }
        }
        .pickerStyle(.menu)
    }
    
    var body: some View {
        Form {
            Section {
                HLabelled("Name") {
                    TextField("Example", text: $name)
                        .textContentType(.name)
                }
                HLabelled("URL") {
                    TextField("api.example.com", text: $address)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }
                HLabelled("Port") {
                    TextField("8080", text: $port)
                        .keyboardType(.numberPad)
                }
                HLabelled("Username") {
                    TextField("example_user", text: $username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                }
                HLabelled("Password") {
                    SecureField(String(repeating: "*", count: 16), text: $password)
                        .textContentType(.password)
                }
                VStack(alignment: .leading) {
                    Text("Refresh every \(String(format: "%.1f", refreshInterval))s")
                        .monospacedDigit()
                    Slider(value: $refreshInterval, in: 2...60, step: 0.5)
                }
                VStack(alignment: .leading) {
                    Text("Timeout after \(String(format: "%.1f", timeoutInterval))s")
                        .monospacedDigit()
                    Slider(value: $timeoutInterval, in: 2...60, step: 0.5)
                }
                if let apis = apis, !apis.isEmpty {
                    picker(apis: apis)
                }
            }
            if !issues.isEmpty {
                Section {
                    ForEach(issues, id: \.self) { issue in
                        Text(issue)
                            .foregroundColor(.red)
                    }
                }
            }
            StoreView(\.persistent.apis) { apis in
                StoreView(\.persistent.servers) { servers in
                    Section {
                        Button("Save", action: save)
                            .disabled(saveDisabled)
                    }
                    .onAppear {
                        usedNames = .init(
                            servers.map(\.name)
                        ).subtracting(
                            editingServer
                                .map { [$0.name] }
                            ?? []
                        )
                        self.apis = apis
                        api = editingServer?.api ?? apis.first
                    }
                }
            }
        }
        .navigationBarTitle("Add Server")
    }

    var issues: [String] {
        [
            (name.isEmpty || !usedNames.contains(.init(rawValue: name))).if(
                false: "Name must be unique"
            ),
            (address.isEmpty || URL(string: address) != nil).if(
                false: "URL is invalid"
            ),
            (address.isEmpty || address.starts(with: /https?:\/\//)).if(
                false: "URL needs either http or https as its scheme"
            ),
            (port.isEmpty || isPortValid).if(
                false: "Port is invalid"
            ),
            apis?.isEmpty.if(
                true: "No available APIs"
            )
        ].compactMap(\.self)
    }

    var saveDisabled: Bool {
        name.isEmpty
        || usedNames.contains(.init(rawValue: name))
        || username.isEmpty
        || password.isEmpty
        || URL(string: address) == nil
        || !address.starts(with: /https?:\/\//)
        || !isPortValid
        || api == nil
    }

    var isPortValid: Bool {
        port.first != "0" && UInt16(port) != nil
    }

    func save() {
        dismiss()
        Global.store.dispatch(
            sync: .create(
                .server(
                    .init(
                        url: URL(string: address)!,
                        user: username,
                        password: password,
                        port: UInt16(port)!,
                        name: .init(rawValue: name),
                        api: api!,
                        refreshInterval: refreshInterval,
                        timeoutInterval: timeoutInterval
                    )
                )
            )
        )
    }
}
