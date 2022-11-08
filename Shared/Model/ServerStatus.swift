//
//  ServerStatus.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

enum ServerStatus: String, CustomStringConvertible, Codable {
    case online
    case offline
    case attemptingConnection

    var description: String {
        expression {
            switch self {
            case .online, .offline:
                "Host \(rawValue.capitalized)"
            case .attemptingConnection:
                "Attempting Connection"
            }
        }
    }
}
