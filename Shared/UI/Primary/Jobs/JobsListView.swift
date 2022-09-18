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
    
    func jobCells(jobs: [JobViewModel]) -> some View {
        ForEach(jobs, id: \.id) { job in
            ZStack(alignment: .leading) {
                NavigationLink(destination: JobDetailView(id: job.id)) {
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

    var body: some View {
        OptionalStoreView(\.persistent.selectedServer?.filter) { filter, _ in
            StoreView(\.jobs) { jobs, _ in
                OptionalStoreView(\.persistent.selectedServer) { server, dispatch in
                    let sortedJobs = sorted(jobs: jobs, server: server)
                    let filteredJobs = filtered(jobs: sortedJobs, statuses: filter)
                    List {
                        Section {
                            if filteredJobs.isEmpty, !jobs.isEmpty, searchText.isEmpty {
                                HStack {
                                    Spacer()
                                    Group {
                                        Text(SystemImage.filterFilled.body)
                                        Text(SystemImage.arrowUp.body)
                                    }
                                }
                            }
                            jobCells(jobs: filteredJobs)
                        } header: {
                            if !searchText.isEmpty {
                                HStack {
                                    Spacer()
                                    HStack {
                                        SortingMenu()
                                        CommandsMenu(jobs: filteredJobs)
                                        OptionalStoreView(
                                            \.persistent.selectedServer?.filter,
                                             content: FilterMenu.init
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText)
                    .disableAutocorrection(true)
                    .refreshable(action: { dispatch(async: .start) })
                    .listStyle(.plain)
                    .modifier(JobsListTopBar(jobs: filteredJobs))
                }
            }
        }
    }
}
