//
//  Reducer.swift
//  Magnetar
//
//  Created by Charlie Tor on 21/10/20.
//

import Recombine

extension Global {
    enum Reducer {
        static let main = Recombine.Reducer<Global.State, RefinedAction, Global.Environment> { state, action, _ in
            switch action {
            case let .error(error):
                state.errors.append(error)
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
                }
            }
        }
    }
}
