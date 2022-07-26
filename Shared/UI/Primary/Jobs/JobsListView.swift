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
        let jobs = server.jobs.values
            .sorted(keyPath: \.name)
            .sorted { lhs, rhs in
                let order = server.sorting.order
                switch server.sorting.value {
                case let .presetField(field):
                    switch field {
                    case .name:
                        return order.comparator()(lhs.name, rhs.name)
                    case .status:
                        return order.comparator()(lhs.status.rawValue, rhs.status.rawValue)
                    case .id:
                        return order.comparator()(lhs.id, rhs.id)
                    case .uploadSpeed:
                        return order.comparator()(lhs.uploadSpeed, rhs.uploadSpeed)
                    case .downloadSpeed:
                        return order.comparator()(lhs.downloadSpeed, rhs.downloadSpeed)
                    case .uploaded:
                        return order.comparator()(lhs.uploaded, rhs.uploaded)
                    case .downloaded:
                        return order.comparator()(lhs.downloaded, rhs.downloaded)
                    case .size:
                        return order.comparator()(lhs.size, rhs.size)
                    case .eta:
                        return order.comparator()(lhs.eta, rhs.eta)
                    }
                case let .adHocField(field):
                    return Optional.zip(
                        lhs.additionalDictionary[field.name],
                        rhs.additionalDictionary[field.name]
                    )
                    .map {
                        if $0.value != $1.value {
                            return order.comparator()($0.value, $1.value)
                        } else {
                            return lhs.name < rhs.name
                        }
                    }
                    ?? (lhs.name < rhs.name)
                case let .status(status):
                    switch (lhs.status, rhs.status) {
                    case (status, status):
                        return lhs.name < rhs.name
                    case (status, _):
                        return true
                    default:
                        return lhs.name < rhs.name
                    }
                }

            }
        return searchText.isEmpty.if(
            true: jobs,
            false: jobs.filter {
                let search = searchText.lowercased()
                return $0.name.lowercased().contains(search)
                || $0.id.lowercased().contains(search)
                || $0.status.description.lowercased().contains(search)
            }
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
                        Label("Stop", icon: .stopFill)
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
    func body(content: Content) -> some View {
        #if os(iOS)
        return OptionalStoreView(\.selectedServer) { server, _ in
            content
                .navigationBarItems(
                    leading: TransferTotals(jobs: server.jobs),
                    trailing: EmptyView()
                )
                .navigationBarTitle("🟢 \(server.name)")
        }
        #else
        return content
        #endif
    }
}
