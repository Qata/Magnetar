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
import OrderedCollections
import SwiftUINavigation

struct JobListView: View {
    @State var searchText: String = ""
    @State var presentedJob: Job.Id?
    @State var detailPresentation = JobDetailView.Presentation.push
    let dispatch = Global.store.writeOnly()

    @ViewBuilder
    func button(
        for command: Command,
        api: APIDescriptor,
        icon: SystemImage,
        role: ButtonRole? = nil
    ) -> some View {
        if api.available(command: command.discriminator) {
            Button(role: role) {
                dispatch(async: .command(command))
            } label: {
                Label(command.discriminator.description, icon: icon)
            }
        }
    }
    
    @ViewBuilder
    func leadingSwipeActions(job: JobViewModel, api: APIDescriptor) -> some View {
        switch job.status {
        case .stopped, .paused:
            button(
                for: .start([job.id]),
                api: api,
                icon: .playFill
            )
            .tint(.green)
        default:
            button(
                for: .pause([job.id]),
                api: api,
                icon: .pauseFill
            )
            button(
                for: .stop([job.id]),
                api: api,
                icon: .stopFill
            )
        }
    }

    @ViewBuilder
    func trailingSwipeActions(id: Job.Id, api: APIDescriptor) -> some View {
        button(
            for: .deleteData([id]),
            api: api,
            icon: .xmarkBin,
            role: .destructive
        )
        button(
            for: .remove([id]),
            api: api,
            icon: .xmark
        )
    }

    func jobCells(jobs: [JobViewModel]) -> some View {
        OptionalStoreView(\.persistent.selectedServer) { server in
            ForEach(jobs, id: \.id) { job in
                ZStack(alignment: .leading) {
                    if detailPresentation == .push {
                        NavigationLink(
                            destination: LazyView(
                                JobDetailView(
                                    id: job.id,
                                    presentation: detailPresentation
                                )
                            )
                        ) {
                            EmptyView()
                        }
                        .opacity(0)
                    }
                    JobRowView(viewModel: job)
                        .if(detailPresentation == .sheet) {
                            $0.sheet(unwrapping: $presentedJob) {
                                JobDetailView(
                                    id: $0.wrappedValue,
                                    presentation: detailPresentation
                                )?.presentationDetents([
                                    .medium,
                                    .large
                                ])
                            }
                            .onTapGesture {
                                presentedJob = job.id
                            }
                        }
                }
                .swipeActions(edge: .leading) {
                    leadingSwipeActions(job: job, api: server.api)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    trailingSwipeActions(id: job.id, api: server.api)
                }
            }
        }
    }

    var body: some View {
        List {
            Section {
                StoreView(\.jobs) { jobs in
                    if jobs.filtered.all.isEmpty, !jobs.all.isEmpty, searchText.isEmpty {
                        HStack {
                            Spacer()
                            Group {
                                Text(SystemImage.filterFilled.body)
                                Text(SystemImage.arrowUp.body)
                            }
                        }
                    }
                    jobCells(jobs: jobs.filtered.viewModels)
                }
            } header: {
                if !searchText.isEmpty {
                    HStack {
                        Spacer()
                        HStack {
                            SortingMenu()
                            StoreView(\.jobs.filtered.ids) {
                                CommandsMenu(ids: $0)
                            }
                            OptionalStoreView(\.persistent.selectedServer?.filter) {
                                FilterMenu(filter: $0)
                            }
                        }
                    }
                }
            }
        }
        // Prevents row diffing, which happens on the main thread.
        .id(UUID())
        .searchable(text: $searchText)
        .onChange(of: searchText) {
            dispatch(sync: .set(.searchText($0)))
        }
        .disableAutocorrection(true)
        .refreshable(action: { dispatch(async: .start) })
        .listStyle(.plain)
        .modifier(JobsListTopBar())
    }
}
