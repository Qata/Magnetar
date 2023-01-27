//
//  Action.swift
//  Magnetar
//
//  Created by Charlie Tor on 21/10/20.
//

import Foundation
import Recombine
import OrderedCollections

typealias Action = EitherAction<AsyncAction, SyncAction>
enum AsyncAction {
    case start
    case reuploadFile(URL, location: String?)
    case command(Command)
}
enum SyncAction {
    enum Create {
        case server(Server)
        case destination(String)
        case query(WebQuery)
        case error(AppError)
        case queuedCommand(Command)
    }
    enum Set {
        case searchText(String)
        case sorting(Sorting)
        case selectedServer(Server)
        case refreshInterval(TimeInterval)
        case jobs(OrderedDictionary<Job.Id, JobViewModel>)
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
        case jobs([Job.Id: JobViewModel?])
        case filter(Status)
    }
    enum Delete {
        case server(Server.Name)
        case jobs([Job.Id])
        case filter
        case errors
        case query(name: WebQuery.Name)
    }
    enum Navigation {
        case tab(Global.State.Navigation)
    }
    case create(Create)
    case set(Set)
    case update(Update)
    case delete(Delete)
    case navigate(Navigation)
}
