//
//  JobsListTopBar.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 8/9/2022.
//

import SwiftUI

struct JobsListTopBar: ViewModifier {
    func buttons(
        for servers: [Server],
        selected: Server,
        dispatch: @escaping (Server) -> Void
    ) -> some View {
        ForEach(servers.sorted(keyPath: \.name), id: \.self) { server in
            Button {
                dispatch(server)
            } label: {
                HStack {
                    Text(server.name.rawValue)
                    Spacer()
                    if server.name == selected.name {
                        SystemImage.checkmark
                    }
                }
            }
            .disabled(server.name == selected.name)
        }
    }

    var title: some View {
        OptionalStoreView(\.persistent.selectedServer) { selectedServer in
            Menu {
                StoreView(\.persistent.servers) { servers, dispatch in
                    buttons(
                        for: servers,
                        selected: selectedServer,
                        dispatch: {
                            dispatch(sync: .set(.selectedServer($0)), .delete(.errors))
                        }
                    )
                }
            } label: {
                VStack {
                    Text(selectedServer.name.rawValue)
                        .font(.headline)
                    Text("Online")
                        .font(.subheadline)
                }
            }
        }
    }

    var filter: some View {
        OptionalStoreView(
            \.persistent.selectedServer?.filter,
             content: FilterMenu.init
        )
    }
    
    var sorting: some View {
        SortingMenu()
    }
    
    var commands: some View {
        StoreView(\.jobs.filtered.ids) { ids in
            CommandsMenu(ids: ids)
        }
    }
    
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .navigationBarItems(
                leading: HStack {
                    StoreView(\.jobs.totals) {
                        TransferTotalsView(
                            downloadSpeed: $0.downloadSpeed,
                            uploadSpeed: $0.uploadSpeed
                        )
                        .font(.footnote.bold())
                    }
                    ErrorView()
                },
                trailing: Menu {
                    sorting
                    commands
                    filter
                } label: {
                    SystemImage.ellipsisCircle
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .principal) {
                    title
                }
            }
        #else
        return content
        #endif
    }
}
