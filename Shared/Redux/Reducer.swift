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
            }
        }
        static let create = Recombine.Reducer<Global.State, SyncAction.Create, Global.Environment> { state, action, _ in
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
        }
        static let set = Recombine.Reducer<Global.State, SyncAction.Set, Global.Environment> { state, action, _ in
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
        }
        static let update = Recombine.Reducer<Global.State, SyncAction.Update, Global.Environment> { state, action, _ in
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
        }
        static let delete = Recombine.Reducer<Global.State, SyncAction.Delete, Global.Environment> { state, action, _ in
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
