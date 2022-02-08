//
//  Sorting.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 8/2/22.
//

import Algorithms

enum Sorting: Codable, Hashable {
    enum Value: Codable, Hashable {
        enum Field: Codable, Hashable {
            case name
            case uploadSpeed
            case downloadSpeed
            case uploaded
            case downloaded
            case size
            case eta
        }

        case field(Field)
        case status(Status)
    }

    case ascending(Value)
    case descending(Value)
}
