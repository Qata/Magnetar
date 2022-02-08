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
        switch self {
        case .online, .offline:
            return "Host \(rawValue.capitalized)"
        case .attemptingConnection:
            return "Attempting Connection"
        }
    }
}
