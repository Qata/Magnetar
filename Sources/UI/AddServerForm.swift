//
//  AddServerForm.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 19/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import SwiftUI

enum ServerType: String, CaseIterable, Hashable, Identifiable {
    case transmission
    case µTorrent
    case vuze
    
    var name: String {
        switch self {
        case .µTorrent:
            return "µTorrent"
        default:
            return rawValue.capitalized
        }
    }
    
    var id: String {
        return rawValue
    }
}

struct AddServerForm: View {
    @State var server: AnyServer? = nil
    @State var type: ServerType = .transmission
    @State var name: String = ""
    @State var address: String = ""
    @State var port: String = ""
    @State var username: String = ""
    @State var password: String = ""
    
    var body: some View {
        Form {
            Section {
                Picker(selection: $type, label: Text("Software")) {
                    ForEach(ServerType.allCases) {
                        Text($0.name).tag($0)
                    }
                }
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
                    SecureField("Ex4mpleP@ssw0rd", text: $password)
                        .textContentType(.password)
                }
            }
            Section {
                Button("Save", action: save).disabled(
                    name.isEmpty ||
                    username.isEmpty ||
                    password.isEmpty ||
                    URL(string: address) == nil ||
                    port.first == "0" ||
                    port.unicodeScalars.contains(where: CharacterSet.decimalDigits.inverted.contains) ||
                    (UInt(port).map((!) <<< (1...UInt16.max).contains <<< numericCast) ?? true)
                )
            }
        }
        .navigationBarTitle("Settings")
    }
    
    var validUserInput: Bool {
        return false
    }
    
    func save() {
        switch type {
        case .transmission:
            break
        case .vuze:
            break
        case .µTorrent:
            break
        }
    }
}
