//
//  RequestFileName.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 18/9/2022.
//

import Foundation

enum RequestFileName: Codable, Hashable {
    case string(name: String, extension: String)
    case random(extension: String)
    
    var name: String {
        switch self {
        case let .string(name, ext):
            return "\(name).\(ext)"
        case let .random(ext):
            return Self.string(name: UUID().uuidString, extension: ext).name
        }
    }
}
