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

    func sorted(jobs: [String: JobViewModel], server: Server) -> [JobViewModel] {
        jobs.values
            .sorted(keyPath: \.name)
            .sorted { lhs, rhs in
                func fieldSort() -> Bool {
                    let order = server.sorting.order
                    switch server.sorting.value.field {
                    case let .preset(field):
                        switch field {
                        case .name:
                            return order.comparator()(lhs.name, rhs.name)
                        case .status:
                            return order.comparator()(lhs.status, rhs.status)
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
                    case let .adHoc(field):
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
                    }
                }
                let preferencedStatus = server.sorting.value.status
                switch (lhs.status, rhs.status) {
                case (preferencedStatus, preferencedStatus):
                    return fieldSort()
                case (preferencedStatus, _):
                    return true
                default:
                    return fieldSort()
                }
            }
    }
    
    func filtered(jobs: [JobViewModel], statuses filter: Set<Status>) -> [JobViewModel] {
        jobs.filter {
            filter.isEmpty || filter.contains($0.status)
        }
        .filter { job -> Bool in
            guard searchText.isEmpty.not else { return true }
            return [\JobViewModel.name, \.id]
                .map { job[keyPath: $0].lowercased() }
                .contains { $0.contains(searchText.lowercased()) }
        }
    }

    @ViewBuilder
    func leadingSwipeActions(job: JobViewModel) -> some View {
        OptionalStoreView(\.persistent.selectedServer) { server, dispatch in
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
        OptionalStoreView(\.persistent.selectedServer) { server, dispatch in
            List {
                StoreView(\.jobs) { jobs, _ in
                    StoreView(\.persistent.filter) { filter, _ in
                        let sortedJobs = sorted(jobs: jobs, server: server)
                        let filteredJobs = filtered(jobs: sortedJobs, statuses: filter)
                        Section(
                            header: ServerStatusHeader(
                                status: .online,
                                ids: filteredJobs.map(\.id)
                            )
                        ) {
                            if filteredJobs.isEmpty, !jobs.isEmpty, searchText.isEmpty {
                                HStack {
                                    Spacer()
                                    Group {
                                        Text(SystemImage.filterFilled.body)
                                        Text(SystemImage.arrowUp.body)
                                    }
                                }
                            }
                            ForEach(filteredJobs, id: \.id) { job in
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
                }
            }
            .searchable(text: $searchText)
            .disableAutocorrection(true)
            .refreshable(action: { dispatch(async: .command(.fetch(.all))) })
            .listStyle(.plain)
            .modifier(TopBar())
        }
    }
}

private struct TopBar: ViewModifier {
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
                        dispatch: { dispatch(sync: .set(.selectedServer($0))) }
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
        StoreView(\.persistent.filter) { filter, dispatch in
            Menu(content: {
                if !filter.isEmpty {
                    Button {
                        dispatch(sync: .delete(.filter))
                    } label: {
                        HStack {
                            Text("Clear Selection")
                            Spacer()
                            SystemImage.xmark
                        }
                    }
                }
                ForEach(Status.allCases, id: \.self) { status in
                    Button {
                        let transform = filter.contains(status).if(
                            true: SyncAction.Update.Status.remove,
                            false: SyncAction.Update.Status.add
                        )
                        dispatch(sync: .update(.filter(transform(status))))
                    } label: {
                        HStack {
                            Text(status.description)
                            Spacer()
                            if filter.contains(status) {
                                SystemImage.checkmark
                            }
                        }
                    }
                }
            }, label: {
                filter.isEmpty.if(
                    true: SystemImage.filter,
                    false: SystemImage.filterFilled
                )
            })
        }
    }
    
    func body(content: Content) -> some View {
        #if os(iOS)
        return StoreView(\.jobs) { jobs, _ in
            content
                .navigationBarItems(
                    leading: TransferTotals(jobs: jobs),
                    trailing: filter
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .principal) {
                        title
                    }
                }
        }
        #else
        return content
        #endif
    }
}

struct AddURIView: View {
    @State var text = ""
    
    var body: some View {
        VStack {
            TextField("URI", text: $text)
            Menu("Add") {
                OptionalStoreView(
                    \.persistent.selectedServer?.downloadDirectories
                ) { directories, dispatch in
                    ForEach(directories, id: \.self) { directory in
                        Button(directory) {
                            dispatch(async: .command(.addURI(text, location: directory)))
                        }
                    }
                }
            }
        }
    }
    
    func add() {
        
    }
}
