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
    @StateObject var store: MainStore = Global.store
    @State var searchText: String = ""
    
    var data: [JobViewModel] {
        store.state.selectedServer
            .map(\.jobs.values)
            .map { $0.sorted(keyPath: \.name) }
            .map {
                searchText.isEmpty.if(
                    true: $0,
                    false: $0.filter { $0.name.lowercased().contains(searchText.lowercased()) }
                )
            }
            .default([])
    }
    
    @ViewBuilder
    func leadingSwipeActions(job: JobViewModel) -> some View {
        switch job.status {
        case .stopped, .paused:
            Button {
                store.dispatch(async: .command(.start([job.id])))
            } label: {
                Label("Plus", icon: .playFill)
            }
            .tint(.green)
        default:
            if store.state.selectedServer?.api.commandAvailable(.pause) == true {
                Button {
                    store.dispatch(async: .command(.pause([job.id])))
                } label: {
                    Label("Pause", icon: .pauseFill)
                }
                .tint(.gray)
            } else {
                Button {
                    store.dispatch(async: .command(.stop([job.id])))
                } label: {
                    Label(("Stop"), icon: .stopFill)
                }
                .tint(.gray)
            }
        }
    }

    var body: some View {
        List {
            Section(header: ServerStatusHeader(status: .online)) {
                ForEach(data, id: \.id) { job in
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
        .refreshable(action: { store.dispatch(async: .command(.fetch(.all))) })
        .listStyle(.plain)
        .modifier(TopBar())
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
