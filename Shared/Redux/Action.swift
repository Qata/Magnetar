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
        case error(AppError)
    }
    enum Set {
        case sorting(Sorting)
        case selectedServer(Server)
        case refreshInterval(TimeInterval)
        case jobs([String: JobViewModel])
        case token(String?)
    }
    enum Update {
        enum Sorting {
            case order(Magnetar.Sorting.Order)
            case value(Job.Field.Descriptor)
        }
        
        enum Status {
            case add(Magnetar.Status)
            case remove(Magnetar.Status)
        }

        case sorting(Sorting)
        case jobs([String: JobViewModel?])
        case filter(Status)
    }
    enum Delete {
        case jobs([String])
        case filter
        case errors
    }
    case create(Create)
    case set(Set)
    case update(Update)
    case delete(Delete)
}
