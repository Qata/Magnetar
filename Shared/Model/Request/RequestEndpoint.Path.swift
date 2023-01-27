//
//  RequestEndpoint.Path.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 18/9/2022.
//

import Foundation

extension RequestEndpoint {
    enum Path: Codable, Hashable, ExpressibleByStringLiteral {
        case component(String)
        case parameter(RequestParameter)
        
        init(stringLiteral value: StringLiteralType) {
            self = .component(value)
        }
    }
}

extension RequestEndpoint.Path: RequestParameterContainer {
    typealias Value = String
    typealias Resolved = String

    func resolve(array: [String], separator: String?) -> String {
        array.joined(separator: separator ?? ",")
    }

    func resolve(string: String) -> String {
        string
    }

    func resolve(bool: Bool) -> String {
        bool.description
    }

    func resolve(data: Data, name: RequestFileName) -> String {
        fatalError("Bytes cannot be encoded to a path")
    }

    func promote(_ value: String?) -> String {
        value ?? ""
    }
}
