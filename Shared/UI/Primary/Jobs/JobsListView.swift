//
//  JobListView.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 19/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import SwiftUI
import Recombine
import Algorithms

struct JobListView: View {
    @State var searchText: String = ""
    let dispatch = Global.store.writeOnly()

    func sorted(jobs: [String: JobViewModel], server: Server) -> [JobViewModel] {
        jobs.values
            .sorted(keyPath: \.name)
            .sorted { lhs, rhs in
                let order = server.sorting.order
                switch server.sorting.value {
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
        StoreView(\.persistent.filter) { filter, _ in
            StoreView(\.jobs) { jobs, _ in
                OptionalStoreView(\.persistent.selectedServer) { server, dispatch in
                    let sortedJobs = sorted(jobs: jobs, server: server)
                    let filteredJobs = filtered(jobs: sortedJobs, statuses: filter)
                    List {
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
                    .searchable(text: $searchText)
                    .disableAutocorrection(true)
                    .refreshable(action: { dispatch(async: .command(.fetch(.all))) })
                    .listStyle(.plain)
                    .modifier(TopBar(jobs: filteredJobs))
                }
            }
        }
    }
}

private struct TopBar: ViewModifier {
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
            Menu {
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
            } label: {
                filter.isEmpty.if(
                    true: SystemImage.filter,
                    false: SystemImage.filterFilled
                )
            }
        }
    }
    
    func sortingButton(order: Sorting.Order) -> some View {
        OptionalStoreView(\.persistent.selectedServer?.sorting.order) { sorting, dispatch in
            Button {
                dispatch(sync: .update(.sorting(.order(order))))
            } label: {
                HStack {
                    Text(order.description)
                    Spacer()
                    if sorting == order {
                        SystemImage.checkmark
                    }
                }
            }
        }
    }
    
    func sortingButton(field: Job.Field.Descriptor) -> some View {
        OptionalStoreView(\.persistent.selectedServer?.sorting.value) { sorting, dispatch in
            Button {
                dispatch(sync: .update(.sorting(.value(field))))
            } label: {
                HStack {
                    Text(field.description)
                    Spacer()
                    if sorting == field {
                        SystemImage.checkmark
                    }
                }
            }
        }
    }
    
    var sorting: some View {
        OptionalStoreView {
            $0.persistent.selectedServer?
                .api.commands[.fetch]?.expected
                .adHocFields
                .map(Job.Field.Descriptor.adHoc)
        } content: { fields, _ in
            Menu {
                Section {
                    ForEach(
                        Sorting.Order.allCases,
                        id: \.self,
                        content: sortingButton(order:)
                    )
                }
                Section {
                    ForEach(
                        chain(
                            Job.Field.Descriptor.PresetField
                                .allCases
                                .map(Job.Field.Descriptor.preset),
                            fields
                        ),
                        id: \.self,
                        content: sortingButton(field:)
                    )
                }
            } label: {
                SystemImage.listNumber
            }
        }
    }
    
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .navigationBarItems(
                leading: TransferTotals(jobs: jobs),
                trailing: HStack {
                    sorting
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
