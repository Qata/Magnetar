//
//  Action.swift
//  Magnetar
//
//  Created by Charlie Tor on 21/10/20.
//

import Foundation
import Recombine

extension Global {
    typealias Action = EitherAction<RawAction, RefinedAction>
    enum RawAction {
        case command(Command)
    }
    enum RefinedAction {
        enum Set {
            case selectedServer(Server)
            case refreshInterval(TimeInterval)
            case jobs([String: JobViewModel])
            case token(String?)
        }
        enum Update {
            case jobs([String: JobViewModel?])
        }
        enum Remove {
            case jobs([String])
        }
        case error(String)
        case set(Set)
        case update(Update)
        case remove(Remove)
    }
}
