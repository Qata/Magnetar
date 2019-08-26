//
//  App.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 18/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import Recombine
import Combine

enum App {
    static let store = Store<State, Action>(
        state: .init(
            name: "Welcome",
            servers: [],
            selectedServer: nil,
            refreshInterval: 2
        ),
        reducer: MutatingReducer { state, action in
            switch action {
            case let .set(.name(name)):
                state.name = name
            case let .set(.selectedServer(server)):
                state.selectedServer = server
            case let .set(.refreshInterval(refreshInterval)):
                state.refreshInterval = refreshInterval
            }
        },
        middleware: .sideEffect {
            print($1)
        },
        publishOn: .main
    )

    struct State {
        var name: String
        var servers: [Server]
        var selectedServer: Server?
        var refreshInterval: TimeInterval
    }

    enum Action {
        case set(Set)
        
        enum Set {
            case name(String)
            case selectedServer(Server)
            case refreshInterval(TimeInterval)
        }
    }
}
