//
//  StructuredResponse.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 19/12/2022.
//

import MonadicJSON
import SwiftXMLRPC
import Foundation

indirect enum StructuredResponse: Hashable, Codable {
    enum Number: Hashable, Codable, CustomStringConvertible {
        case int(Int)
        case double(Double)
        case any(String)

        var description: String {
            switch self {
            case let .int(value):
                return value.description
            case let .double(value):
                return value.description
            case let .any(value):
                return value
            }
        }

        var double: Double? {
            switch self {
            case let .any(value):
                return .init(value)
            case let .double(value):
                return value
            case let .int(value):
                return .init(value)
            }
        }

        var int: Int? {
            switch self {
            case let .any(value):
                return .init(value)
            case let .double(value):
                return .init(value)
            case let .int(value):
                return value
            }
        }

        var uint: UInt? {
            int.map {
                numericCast(max(0, $0))
            }
        }
    }

    case null
    case bool(Bool)
    case string(String)
    case number(Number)
    case date(Date)
    case data(Data)
    case dictionary([String: Self])
    case array([Self])

    init(json: JSON) {
        func recurse(_ json: JSON) -> Self {
            switch json {
            case let .array(array):
                return .array(array.map(recurse))
            case let .string(string):
                return .string(string)
            case let .bool(bool):
                return .bool(bool)
            case let .object(object):
                return .dictionary(object.mapValues(recurse))
            case .null:
                return .null
            case let .number(number):
                return .number(.any(number))
            }
        }
        self = recurse(json)
    }

    init(xml: XMLRPC.Response) throws {
        func recurse(_ xml: XMLRPC.Parameter) -> Self {
            switch xml {
            case .nil:
                return .null
            case let .int8(int):
                return .number(.int(numericCast(int)))
            case let .int16(int):
                return .number(.int(numericCast(int)))
            case let .int32(int):
                return .number(.int(numericCast(int)))
            case let .int64(int):
                return .number(.int(numericCast(int)))
            case let .array(array):
                return .array(array.map(recurse))
            case let .string(string):
                return .string(string)
            case let .bool(bool):
                return .bool(bool)
            case let .struct(object):
                return .dictionary(object.mapValues(recurse))
            case let .double(double):
                return .number(.double(double))
            case let .date(date):
                return .date(date)
            case let .data(data):
                return .data(data)
            }
        }
        switch xml {
        case let .params(xml):
            self = recurse(.array(xml))
        case let .fault(code, description):
            throw XMLRPCError(code: code, fault: description)
        }
    }
    
    var bool: Bool? {
        switch self {
        case let .bool(value):
            return value
        default:
            return nil
        }
    }

    var date: Date? {
        switch self {
        case let .date(value):
            return value
        case let .number(value):
            return value.double.map(Date.init(timeIntervalSince1970:))
        default:
            return nil
        }
    }

    var double: Double? {
        switch self {
        case let .number(value):
            return value.double
        default:
            return nil
        }
    }

    var int: Int? {
        switch self {
        case let .number(value):
            return value.int
        default:
            return nil
        }
    }

    var uint: UInt? {
        switch self {
        case let .number(value):
            return value.uint
        default:
            return nil
        }
    }
}

protocol StructuredResponseInitialisable {
    init(from response: StructuredResponse, against expected: Payload.StructuredResponse, context: APIDescriptor) throws
}

extension Array: StructuredResponseInitialisable where Element: StructuredResponseInitialisable {
    init(
        from response: StructuredResponse,
        against expected: Payload.StructuredResponse,
        context: APIDescriptor
    ) throws {
        func recurse(response: StructuredResponse, against expected: Payload.StructuredResponse) throws -> [Element] {
            switch (response, expected) {
            case let (.dictionary(response), .dictionary(expected)):
                return try expected
                    .compactMap { key, value -> (StructuredResponse, Payload.StructuredResponse)? in
                        Optional.zip(response[key], value)
                    }
                    .flatMap(recurse)
            case let (.array(response), .array(expected)):
                return try zip(response, expected)
                    .flatMap(recurse)
            case let (.array(response), .forEach(expected)):
                return try zip(response, expected.cycled()).map {
                    try Element(from: $0, against: $1, context: context)
                }
            default:
                throw ResponseParseError(response: response, expected: expected)
            }
        }
        self = try recurse(response: response, against: expected)
    }
}
