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
        func recurseObject(json: [String: JSON], expected: [String: Payload.JSON]) throws {
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
            case let .object(expectedObject):
                switch json {
                case let .object(json):
                    try recurseObject(json: json, expected: expectedObject)
                default:
                    throw JSONParseError(json: json, expected: expected)
                }
            case let .string(expectedString):
                switch json {
                case .string(expectedString):
                    break
                default:
                    throw JSONParseError(json: json, expected: expected)
                }
            case let .bool(expectedBool):
                switch json {
                case .bool(expectedBool):
                    break
                default:
                    throw JSONParseError(json: json, expected: expected)
                }
            case let .array(expectedArray), let .forEach(expectedArray):
                switch json {
                case let .array(json):
                    try zip(json, expectedArray).forEach(recurse)
                default:
                    throw JSONParseError(json: json, expected: expected)
                }
            }
        }
        try recurse(json: json, expected: expected)
    }
}
