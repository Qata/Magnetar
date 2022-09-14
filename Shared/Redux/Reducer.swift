//
//  Reducer.swift
//  Magnetar
//
//  Created by Charlie Tor on 21/10/20.
//

import Recombine
import Algorithms
import Foundation

extension Global {
    enum Reducer {
        static let main = Recombine.Reducer<Global.State, SyncAction, Global.Environment> { state, action, _ in
            switch action {
            case let .create(action):
                switch action {
                case let .error(error):
                    state.errors.write(.init(date: Date(), error: String(describing: error)))
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
                }
            case let .set(action):
                switch action {
                case let .selectedServer(server):
                    state.jobs.removeAll()
                    state.persistent.selectedServer = server
                case let .refreshInterval(refreshInterval):
                    state.persistent.selectedServer?.refreshInterval = refreshInterval
                case let .jobs(jobs):
                    state.jobs = jobs
                case let .token(token):
                    state.persistent.selectedServer?.token = token
                case let .sorting(sorting):
                    state.persistent.selectedServer?.sorting = sorting
                }
            case let .update(action):
                switch action {
                case let .jobs(jobs):
                    jobs.forEach {
                        state.jobs[$0] = $1
                    }
                case let .sorting(.order(order)):
                    state.persistent.selectedServer?.sorting.order = order
                case let .sorting(.value(value)):
                    state.persistent.selectedServer?.sorting.value = value
                case let .filter(status):
                    switch status {
                    case let .add(status):
                        state.persistent.selectedServer?.filter.insert(status)
                    case let .remove(status):
                        state.persistent.selectedServer?.filter.remove(status)
                    }
                }
            case let .delete(action):
                switch action {
                case let .jobs(ids):
                    ids.forEach {
                        state.jobs.removeValue(forKey: $0)
                    }
                case .filter:
                    state.persistent.selectedServer?.filter.removeAll()
                case .errors:
                    state.errors = .init(count: 100)
                case let .query(name):
                    state.persistent.queries.removeAll(where: { $0.name == name })
                case let .queries(indices):
                    state.persistent.queries.remove(atOffsets: indices)
                }
            }
        }
    }
}
