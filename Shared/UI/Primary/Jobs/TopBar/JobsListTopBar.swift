//
//  JobsListTopBar.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 8/9/2022.
//

import SwiftUI

struct JobsListTopBar: ViewModifier {
    let jobs: [JobViewModel]

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
                    Text(server.name)
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
        OptionalStoreView(\.persistent.selectedServer) { selectedServer, _ in
            Menu {
                StoreView(\.persistent.servers) { servers, dispatch in
                    buttons(
                        for: servers,
                        selected: selectedServer,
                        dispatch: {
                            dispatch(sync: .set(.selectedServer($0)))
                            dispatch(async: .command(.fetch(.all)))
                        }
                    )
                }
            } label: {
                VStack {
                    Text(selectedServer.name)
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
        CommandsMenu(jobs: jobs)
    }
    
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .navigationBarItems(
                leading: HStack {
                    TransferTotalsView(jobs: jobs)
                        .font(.footnote.bold())
                    ErrorView()
                },
                trailing: HStack {
                    sorting
                    commands
                    filter
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
