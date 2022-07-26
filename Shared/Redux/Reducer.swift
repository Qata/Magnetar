//
//  Reducer.swift
//  Magnetar
//
//  Created by Charlie Tor on 21/10/20.
//

import Recombine
import Algorithms

extension Global {
    enum Reducer {
        static let main = Recombine.Reducer<Global.State, SyncAction, Global.Environment> { state, action, _ in
            switch action {
            case let .error(error):
                state.errors.write(String(describing: error))
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
            case let .create(action):
                switch action {
                case let .query(query):
                    state.queries.append(query)
                }
            case let .set(action):
                switch action {
                case let .selectedServer(server):
                    state.selectedServer = server
                case let .refreshInterval(refreshInterval):
                    state.refreshInterval = refreshInterval
                case let .jobs(jobs):
                    state.selectedServer?.jobs = jobs
                case let .token(token):
                    state.selectedServer?.token = token
                case let .sorting(sorting):
                    state.selectedServer?.sorting = sorting
                }
            case let .update(action):
                switch action {
                case let .jobs(jobs):
                    jobs.forEach {
                        state.selectedServer?.jobs[$0] = $1
                    }
                case let .sorting(.order(order)):
                    state.selectedServer?.sorting.order = order
                case let .sorting(.value(value)):
                    state.selectedServer?.sorting.value = value
                }
            case let .delete(action):
                switch action {
                case let .jobs(ids):
                    ids.forEach {
                        state.selectedServer?.jobs.removeValue(forKey: $0)
                    }
                }
            }
        }
    }
}
