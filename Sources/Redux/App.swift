//
//  App.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 18/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import Recombine

enum App {
    static let store = Store<State, Action>(
        state: .init(name: "Welcome", server: nil),
        reducer: reducer
    )
    
    static let reducer = Reducer<App.State, App.Action> { state, action in
        var state = state
        switch action {
        case let .set(.name(name)):
            state.name = name
        case let .set(.server(server)):
            state.server = server
        }
        return state
    }

    struct State {
        var name: String
        var server: AnyServer?
    }

    enum Action {
        case set(Set)
        
        enum Set {
            case name(String)
            case server(AnyServer)
        }
    }
}
