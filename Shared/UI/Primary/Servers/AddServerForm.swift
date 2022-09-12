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
    
    var body: some View {
        Form {
            Section {
                HLabelled("Name") {
                    TextField("Example", text: $name)
                        .textContentType(.name)
                }
                HLabelled("URL") {
                    TextField("https://api.example.com", text: $address)
                        .textContentType(.URL)
                }
                HLabelled("Port") {
                    TextField("8080", text: $port)
                }
                HLabelled("Username") {
                    TextField("example_user", text: $username)
                        .textContentType(.username)
                }
                HLabelled("Password") {
                    SecureField(String(repeating: "*", count: 16), text: $password)
                        .textContentType(.password)
                }
                HLabelled("API") {
                    Spacer()
                    StoreView(\.persistent.apis) { apis, _ in
                        Picker("Select an API", selection: $api) {
                            Text("None")
                                .tag(Optional<APIDescriptor>.none)
                            ForEach(apis.sorted(keyPath: \.name), id: \.self) {
                                Text($0.name)
                                    .tag(Optional($0))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            Section {
                Button("Save", action: save)
                    .disabled(saveDisabled)
            }
        }
        .navigationBarTitle("Settings")
    }
    
    var saveDisabled: Bool {
        name.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        URL(string: address) == nil ||
        !isPortValid
    }

    var isPortValid: Bool {
        port.first != "0" && UInt16(port) != nil
    }

    var validUserInput: Bool {
        return false
    }
    
    func save() {
    }
}
