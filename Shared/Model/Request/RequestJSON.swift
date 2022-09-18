//
//  RequestJSON.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 16/9/2022.
//

import MonadicJSON
import Foundation

indirect enum RequestJSON: Hashable, Codable {
    enum Field: Hashable, Codable {
        case id
    }
    enum Encoding: Hashable, Codable {
        case base64
    }
    case null
    case string(String)
    case number(String)
    case bool(Bool)
    case object([String: Self])
    case array([Self])
    case parameter(RequestParameter)

    func resolve(command: Command, server: Server) -> JSON {
        var ids: [String] = command.ids.reversed()
        func recurse(json: RequestJSON) -> JSON? {
            switch json {
            case let .object(json):
                return .object(json.compactMapValues(recurse))
            case let .array(json):
                return .array(json.compactMap(recurse))
            case let .string(value):
                return .string(value)
            case let .number(value):
                return .number(value)
            case let .bool(value):
                return .bool(value)
            case .null:
                return .null
            case let .parameter(parameter):
                return resolve(
                    parameter: parameter,
                    command: command,
                    server: server,
                    ids: &ids
                )
            }
        }
        return recurse(json: self) ?? .null
    }
}

extension RequestJSON: RequestParameterContainer {
    typealias Value = JSON
    typealias Resolved = JSON?

    func resolve(string: String) -> Value {
        .string(string)
    }

    func resolve(array: [String], separator _: String?) -> Value {
        .array(array.map(JSON.string))
    }
    
    func resolve(bool: Bool) -> JSON {
        .bool(bool)
    }

    func resolve(data: Data, name: RequestFileName) -> JSON {
        fatalError("Bytes cannot be encoded to JSON")
    }

    func promote(_ value: Value?) -> Resolved {
        value
    }
}
