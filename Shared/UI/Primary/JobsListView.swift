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
        guard let jobs = store.state.selectedServer?.jobs.values.sorted(keyPath: \.name) else {
            return []
        }
        return searchText.isEmpty.if(
            true: jobs,
            false: jobs.filter { $0.name.contains(searchText) }
        )
    }
    
    @ViewBuilder
    func leadingSwipeActions(job: JobViewModel) -> some View {
        switch job.status {
        case .stopped, .paused:
            Button {
                store.dispatch(async: .command(.start([job.id])))
            } label: {
                Label {
                    Text("Play")
                } icon: {
                    SystemImage.playFill
                }
            }
            .tint(.green)
        default:
            if store.state.selectedServer?.api.commandAvailable(.pause) == true {
                Button {
                    store.dispatch(async: .command(.pause([job.id])))
                } label: {
                    Label {
                        Text("Pause")
                    } icon: {
                        SystemImage.pauseFill
                    }
                }
                .tint(.gray)
            } else {
                Button {
                    store.dispatch(async: .command(.stop([job.id])))
                } label: {
                    Label {
                        Text("Stop")
                    } icon: {
                        SystemImage.stopFill
                    }
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
                        .swipeActions(edge: .leading) {
                            leadingSwipeActions(job: job)
                        }
                        .opacity(0)
                        JobRowView(viewModel: job)
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .refreshable(action: { store.dispatch(async: .command(.fetch(.all))) })
        .listStyle(PlainListStyle())
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
                trailing: Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
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
