//
//  ServerList.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 31/8/2022.
//

import SwiftUI

struct ServerList: View {
    var body: some View {
        StoreView(\.persistent.servers) { servers, dispatch in
            List {
                ForEach(servers.sorted(keyPath: \.name), id: \.self) { server in
                    NavigationLink {
                        AddServerForm(
                            name: server.name.rawValue,
                            address: server.url.absoluteString,
                            port: server.port.description,
                            username: server.user ?? "",
                            password: server.password ?? "",
                            api: server.api,
                            refreshInterval: server.refreshInterval,
                            timeoutInterval: server.timeoutInterval,
                            editingServer: server
                        )
                    } label: {
                        Text(server.name.rawValue)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            dispatch(sync: .delete(.server(server.name)))
                        } label: {
                            Label("Delete", icon: .xmark)
                        }
                    }
                }
            }
            .navigationTitle("Servers")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    NavigationLink {
                        AddServerForm()
                    } label: {
                        SystemImage.plus
                    }
                }
            }
        }
    }
}
