//
//  ServerRunner.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 6/2/22.
//

import Foundation
import Combine

enum Command: Codable, Hashable {
    indirect case requestToken(andThen: Self)
    case fetch
    case start(Jobs)
    case stop(Jobs)
    case pause(Jobs)
    case remove(Jobs)
    case delete(Jobs)
    case addMagnet(URL)
    case addFile(URL)
    
    enum Discriminator: Codable, Hashable {
        case requestToken
        case fetch
        case start
        case stop
        case pause
        case remove
        case delete
        case addMagnet
        case addFile
    }

    var discriminator: Discriminator {
        switch self {
        case .requestToken:
            return .requestToken
        case .fetch:
            return .fetch
        case .start:
            return .start
        case .stop:
            return .stop
        case .pause:
            return .pause
        case .remove:
            return .remove
        case .delete:
            return .delete
        case .addMagnet:
            return .addMagnet
        case .addFile:
            return .addFile
        }
    }
}

struct ServerRunner {
}
