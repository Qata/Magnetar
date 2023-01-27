//
//  ExpectedJobsPayload.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 6/2/22.
//

import Foundation
import MonadicJSON
import Recombine
import SwiftXMLRPC

private let xmlDateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd'T'HH:mm:ss"
    return formatter
}()

extension Payload {
    indirect enum StructuredResponse: Hashable, Codable {
        case bool(Bool)
        case string(String)
        case int(Int)
        case date(Date)
        case data(Data)
        case dictionary([String: Self])
        case array([Self])

        case forEach([Self])
        case parameter(Parameter)
    }

    indirect enum JSON: Hashable, Codable {
        case object([String: Self])
        case array([Self])
        case string(String)
        case bool(Bool)

        case forEach([Self])
        case parameter(Parameter)
    }

    enum XMLRPC {
        enum Response: Hashable, Codable {
            case params([XMLRPC.Parameter])
        }

        indirect enum Parameter: Hashable, Codable {
            case int(Int)
            case bool(Bool)
            case string(String)
            case `struct`([String: Self])
            case array([Self])

            case forEach([Self])
            case parameter(Payload.Parameter)
        }
    }

    enum Parameter: Hashable, Codable {
        case field(Job.Field.Descriptor)
        case token
        case destination
    }
}

extension Payload.StructuredResponse {
    init(json: Payload.JSON) {
        func recurse(_ json: Payload.JSON) -> Self {
            switch json {
            case let .parameter(parameter):
                return .parameter(parameter)
            case let .array(array):
                return .array(array.map(recurse))
            case let .string(string):
                return .string(string)
            case let .bool(bool):
                return .bool(bool)
            case let .forEach(array):
                return .forEach(array.map(recurse))
            case let .object(object):
                return .dictionary(object.mapValues(recurse))
            }
        }
        self = recurse(json)
    }

    init(xml: Payload.XMLRPC.Response) throws {
        func recurse(_ xml: Payload.XMLRPC.Parameter) -> Self {
            switch xml {
            case let .parameter(parameter):
                return .parameter(parameter)
            case let .int(int):
                return .int(int)
            case let .array(array):
                return .array(array.map(recurse))
            case let .string(string):
                return .string(string)
            case let .bool(bool):
                return .bool(bool)
            case let .forEach(array):
                return .forEach(array.map(recurse))
            case let .struct(object):
                return .dictionary(object.mapValues(recurse))
            }
        }
        switch xml {
        case let .params(xml):
            self = recurse(.array(xml))
        }
    }
}

struct ResponseValues: Codable, Hashable, StructuredResponseInitialisable {
    var values: [Payload.Parameter: [StructuredResponse]] = [:]
    
    init(
        from response: StructuredResponse,
        against expected: Payload.StructuredResponse,
        context: APIDescriptor
    ) throws {
        func recurseDictionary(response: [String: StructuredResponse], expected: [String: Payload.StructuredResponse]) throws {
            try expected
                .map { key, value -> (StructuredResponse, Payload.StructuredResponse) in
                    guard let response = response[key] else {
                        throw ResponseParseError(response: .dictionary(response), expected: .dictionary(expected))
                    }
                    return (response, value)
                }
                .forEach(recurse)
        }

        func recurse(response: StructuredResponse, expected: Payload.StructuredResponse) throws {
            switch expected {
            case let .parameter(parameter):
                switch parameter {
                case let .field(field):
                    values[.field(field), default: []].append(response)
                case .token:
                    values[.token, default: []].append(response)
                case .destination:
                    values[.destination, default: []].append(response)
                }
            case let .dictionary(expectedDictionary):
                switch response {
                case let .dictionary(response):
                    try recurseDictionary(response: response, expected: expectedDictionary)
                default:
                    throw ResponseParseError(response: response, expected: expected)
                }
            case let .string(expectedString):
                switch response {
                case .string(expectedString):
                    break
                default:
                    throw ResponseParseError(response: response, expected: expected)
                }
            case let .bool(expectedBool):
                switch response {
                case .bool(expectedBool):
                    break
                default:
                    throw ResponseParseError(response: response, expected: expected)
                }
            case let .array(expectedArray), let .forEach(expectedArray):
                switch response {
                case let .array(response):
                    try zip(response, expectedArray).forEach(recurse)
                default:
                    throw ResponseParseError(response: response, expected: expected)
                }
            case let .int(expectedInt):
                switch response {
                case .number(.int(expectedInt)):
                    break
                default:
                    throw ResponseParseError(response: response, expected: expected)
                }
            case .date:
                break
            case .data:
                break
            }
        }
        try recurse(response: response, expected: expected)
    }

    func extractActions() -> [EitherAction<AsyncAction, SyncAction>] {
        values.flatMap { key, values in
            switch key {
            case .token:
                return values.flatMap { value -> [EitherAction<AsyncAction, SyncAction>] in
                    switch value {
                    case let .string(token):
                        return [.sync(.set(.token(token)))]
                    default:
                        return []
                    }
                }
            case .destination:
                return values.flatMap { value -> [EitherAction<AsyncAction, SyncAction>] in
                    switch value {
                    case let .string(destination):
                        return [.sync(.create(.destination(destination)))]
                    default:
                        return []
                    }
                }
            case .field:
                return []
            }
        }
    }
}
