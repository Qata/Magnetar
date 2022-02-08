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
        case error(String)
        case set(Set)
        
        enum Set {
            case selectedServer(Server)
            case refreshInterval(TimeInterval)
            case jobs([JobViewModel])
            case token(String?)
        }
    }
}
