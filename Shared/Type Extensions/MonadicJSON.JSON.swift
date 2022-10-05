//
//  MonadicJSON.JSON.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 20/9/2022.
//

import MonadicJSON

extension JSON {
    enum Discriminator: String, Codable, Hashable {
        case null
        case string
        case number
        case bool
        case object
        case array
    }

    var discriminator: Discriminator {
        switch self {
        case .null:
            return .null
        case .string:
            return .string
        case .number:
            return .number
        case .bool:
            return .bool
        case .object:
            return .object
        case .array:
            return .array
        }
    }
}
