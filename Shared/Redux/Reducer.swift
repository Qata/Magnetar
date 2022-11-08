//
//  Reducer.swift
//  Magnetar
//
//  Created by Charlie Tor on 21/10/20.
//

import Recombine
import Algorithms
import Foundation
import OrderedCollections

extension Global {
    enum Reducer {
        static func sortJobs(
            _ jobs: inout OrderedDictionary<Job.Id, JobViewModel>,
            sorting: Sorting
        ) {
            jobs.sort(keyPath: \.value.name)
            jobs.sort(keyPath: \.value) { lhs, rhs in
                let fields: (Job.Field, Job.Field)?
                switch sorting.value {
                case let .preset(field):
                    fields = Optional.zip(
                        lhs[field],
                        rhs[field]
                    )
                case let .adHoc(field):
                    fields = Optional.zip(
                        lhs.additionalDictionary[field.name],
                        rhs.additionalDictionary[field.name]
                    )
                }
                return fields.map {
                    ($0.value == $1.value).if(
                        true: lhs.name < rhs.name,
                        false: sorting.order.comparator()($0.value, $1.value)
                    )
                }
                ?? (lhs.name < rhs.name)
            }
        }

        static func filteredJobs(
            _ jobs: OrderedDictionary<Job.Id, JobViewModel>,
            statuses filter: Set<Status>,
            searchText: String
        ) -> OrderedDictionary<Job.Id, JobViewModel> {
            jobs.filter(keyPath: \.value) {
                filter.isEmpty || filter.contains($0.status)
            }
            .filter(keyPath: \.value) { job -> Bool in
                guard searchText.isEmpty.not else { return true }
                return [\JobViewModel.name, \.id.rawValue]
                    .map { job[keyPath: $0].lowercased() }
                    .contains { $0.contains(searchText.lowercased()) }
            }
        }

        static func setJobs(_ jobs: inout OrderedDictionary<Job.Id, JobViewModel>, state: inout State) {
            if let server = state.persistent.selectedServer {
                sortJobs(&jobs, sorting: server.sorting)
                state.jobs.all = jobs
                state.jobs.filtered = .init(
                    all: filteredJobs(
                        jobs,
                        statuses: server.filter,
                        searchText: state.searchText
                    )
                )
            }
        }

        static let main = Recombine.Reducer<Global.State, SyncAction, Global.Environment> { state, action, environment in
            switch action {
            case let .create(action):
                create(state: &state, action: action, environment: environment)
            case let .set(action):
                set(state: &state, action: action, environment: environment)
            case let .update(action):
                update(state: &state, action: action, environment: environment)
            case let .delete(action):
                delete(state: &state, action: action, environment: environment)
            case let .navigate(action):
                switch action {
                case let .tab(navigation):
                    state.navigation = navigation
                }
            }
        }

        static let create = Recombine.Reducer<Global.State, SyncAction.Create, Global.Environment> { state, action, _ in
            switch action {
            case let .error(error):
                state.errors.write(
                    .init(
                        date: Date(),
                        error: .init(
                            title: error.title,
                            description: error.description
                        )
                    )
                )
                switch error {
                case let .urlError(error):
                    switch error.code {
                    case .timedOut:
                        print(":::Timed out")
                    default:
                        break
                    }
                default:
                    break
                }
            case let .query(query):
                state.persistent.queries.append(query)
            case let .queuedCommand(command):
                state.persistent.queuedCommands.append(command)
            }
        }

        static let set = Recombine.Reducer<Global.State, SyncAction.Set, Global.Environment> { state, action, _ in
            switch action {
            case let .searchText(string):
                state.searchText = string
                var jobs = state.jobs.all
                setJobs(&jobs, state: &state)
            case let .selectedServer(server):
                state.jobs = .init()
                state.persistent.selectedServer = server
            case let .refreshInterval(refreshInterval):
                state.persistent.selectedServer?.refreshInterval = refreshInterval
            case var .jobs(jobs):
                setJobs(&jobs, state: &state)
            case let .token(token):
                state.persistent.selectedServer?.token = token
            case let .sorting(sorting):
                state.persistent.selectedServer?.sorting = sorting
                var jobs = state.jobs.all
                setJobs(&jobs, state: &state)
            }
        }

        static let update = Recombine.Reducer<Global.State, SyncAction.Update, Global.Environment> { state, action, _ in
            switch action {
            case let .jobs(jobs):
                var updated = state.jobs.all
                jobs.forEach {
                    updated[$0] = $1
                }
                setJobs(&updated, state: &state)
            case let .sorting(sorting):
                switch sorting {
                case let .order(order):
                    state.persistent.selectedServer?.sorting.order = order
                case let .value(value):
                    state.persistent.selectedServer?.sorting.value = value
                }
                var jobs = state.jobs.all
                setJobs(&jobs, state: &state)
            case let .filter(status):
                switch status {
                case let .add(status):
                    state.persistent.selectedServer?.filter.insert(status)
                case let .remove(status):
                    state.persistent.selectedServer?.filter.remove(status)
                }
                var jobs = state.jobs.all
                setJobs(&jobs, state: &state)
            }
        }

        static let delete = Recombine.Reducer<Global.State, SyncAction.Delete, Global.Environment> { state, action, _ in
            switch action {
            case let .server(name):
                state.persistent.servers.removeAll(where: { $0.name == name })
                if state.persistent.selectedServer?.name == name {
                    state.persistent.selectedServer = state.persistent.servers.first
                }
            case let .jobs(ids):
                var updated = state.jobs.all
                ids.forEach {
                    updated.removeValue(forKey: $0)
                }
                setJobs(&updated, state: &state)
            case .filter:
                state.persistent.selectedServer?.filter.removeAll()
                var jobs = state.jobs.all
                setJobs(&jobs, state: &state)
            case .errors:
                state.errors = .init(count: 100)
            case let .query(name):
                state.persistent.queries.removeAll(where: { $0.name == name })
            }
        }
    }
}
