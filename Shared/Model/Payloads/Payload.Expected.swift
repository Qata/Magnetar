//
//  ExpectedJobsPayload.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 6/2/22.
//

import Foundation
import MonadicJSON

extension Payload {
    indirect enum JSON: Hashable, Codable {
        case object([String: Self])
        case array([Self])
        case forEach([Self])
        case string(String)
        case bool(Bool)
        case field(Job.Field.Descriptor)
        case token
    }
    enum Parameter: Hashable, Codable {
        case field(Job.Field.Descriptor)
        case token
    }
}

struct JSONValues: Codable, Hashable, JSONInitialisable {
    var values: [Payload.Parameter: [JSON]] = [:]

    init(from json: JSON, against expected: Payload.JSON, context: APIDescriptor) throws {
        func recurseObjects(json: [String: JSON], expected: [String: Payload.JSON]) throws {
            try expected
                .compactMap { key, value -> (JSON, Payload.JSON)? in
                    Optional.zip(json[key], value)
                }
                .forEach(recurse)
        }

        func recurse(json: JSON, expected: Payload.JSON) throws {
            switch expected {
            case let .field(field):
                values[.field(field), default: []].append(json)
            case .token:
                values[.token, default: []].append(json)
            case let .object(expected):
                switch json {
                case let .object(json):
                    try recurseObjects(json: json, expected: expected)
                default:
                    throw JSONParseError(json: json, expected: expected)
                }
            case let .string(expected):
                switch json {
                case .string(expected):
                    break
                default:
                    throw JSONParseError(json: json, expected: expected)
                }
            case let .bool(expected):
                switch json {
                case .bool(expected):
                    break
                default:
                    throw JSONParseError(json: json, expected: expected)
                }
            case let .array(expected), let .forEach(expected):
                switch json {
                case let .array(json):
                    try zip(json, expected).forEach { json, expected in
                        try recurse(json: json, expected: expected)
                    }
                default:
                    throw JSONParseError(json: json, expected: expected)
                }
            }
        }
        try recurse(json: json, expected: expected)
    }
}
