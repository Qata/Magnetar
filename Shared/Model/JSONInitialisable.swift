//
//  JSONInitialisable.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

import MonadicJSON

protocol JSONInitialisable {
    init(from json: JSON, against expected: Payload.JSON, context: APIDescriptor) throws
}

extension Array: JSONInitialisable where Element: JSONInitialisable {
    init(from json: JSON, against expected: Payload.JSON, context: APIDescriptor) throws {
        func recurse(json: JSON, against expected: Payload.JSON) throws -> [Element] {
            switch (json, expected) {
            case let (.object(json), .object(expected)):
                return try expected
                    .compactMap { key, value -> (JSON, Payload.JSON)? in
                        Optional.zip(json[key], value)
                    }
                    .flatMap(recurse(json:against:))
            case let (.array(json), .array(expected)):
                return try zip(json, expected)
                    .flatMap { json, expected -> [Element] in
                        try recurse(json: json, against: expected)
                    }
            case let (.array(json), .forEach(expected)):
                return try zip(json, expected.cycled()).map {
                    try Element(from: $0, against: $1, context: context)
                }
            default:
                throw JSONParseError(json: json, expected: expected)
            }
        }
        self = try recurse(json: json, against: expected)
    }
}
