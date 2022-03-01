//
//  JobListView.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 19/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import SwiftUI
import Recombine

struct JobListView: View {
    @State var searchText: String = ""
    let dispatch = Global.store.writeOnly()
    
    func data(for server: Server) -> [JobViewModel] {
        let jobs = server.jobs.values.sorted(keyPath: \.name)
        return searchText.isEmpty.if(
            true: jobs,
            false: jobs.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        )
    }
    
    @ViewBuilder
    func leadingSwipeActions(job: JobViewModel) -> some View {
        OptionalStoreView(\.selectedServer) { server, dispatch in
            switch job.status {
            case .stopped, .paused:
                Button {
                    dispatch(async: .command(.start([job.id])))
                } label: {
                    Label("Plus", icon: .playFill)
                }
                .tint(.green)
            default:
                if server.api.available(command: .pause) {
                    Button {
                        dispatch(async: .command(.pause([job.id])))
                    } label: {
                        Label("Pause", icon: .pauseFill)
                    }
                    .tint(.gray)
                } else {
                    Button {
                        dispatch(async: .command(.stop([job.id])))
                    } label: {
                        Label(("Stop"), icon: .stopFill)
                    }
                    .tint(.gray)
                }
            }
        }
    }

    var body: some View {
        OptionalStoreView(\.selectedServer) { server, dispatch in
            List {
                Section(header: ServerStatusHeader(status: .online)) {
                    ForEach(data(for: server), id: \.id) { job in
                        ZStack(alignment: .leading) {
                            NavigationLink(destination: JobDetailView(viewModel: job)) {
                                EmptyView()
                            }
                            .opacity(0)
                            JobRowView(viewModel: job)
                        }
                        .swipeActions(edge: .leading) {
                            leadingSwipeActions(job: job)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .refreshable(action: { dispatch(async: .command(.fetch(.all))) })
            .listStyle(.plain)
            .modifier(TopBar())
        }
    }
}

private struct TopBar: ViewModifier {
    @StateObject var store: MainStore = Global.store

    func body(content: Content) -> some View {
        #if os(iOS)
        return content
            .navigationBarItems(
                leading: store.state.selectedServer.map(\.jobs).map(TransferTotals.init),
                trailing: NavigationLink(destination: SortingView()) {
                    SystemImage.listNumber
                }
            )
            .navigationBarTitle(store.state.selectedServer?.name ?? "")
        #else
        return content
        #endif
    }

    func refresh() {
        store.dispatch(async: .command(.fetch(.all)))
    }
}
