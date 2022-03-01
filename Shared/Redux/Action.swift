//
//  Action.swift
//  Magnetar
//
//  Created by Charlie Tor on 21/10/20.
//

import Foundation
import Recombine

typealias Action = EitherAction<AsyncAction, SyncAction>
enum AsyncAction {
    case start
    case command(Command)
}
enum SyncAction {
    enum Create {
        case query(Query)
    }
    enum Set {
        case selectedServer(Server)
        case refreshInterval(TimeInterval)
        case jobs([String: JobViewModel])
        case token(String?)
    }
    enum Update {
        case jobs([String: JobViewModel?])
    }
    enum Delete {
        case jobs([String])
    }
    case error(String)
    case create(Create)
    case set(Set)
    case update(Update)
    case delete(Delete)
}
