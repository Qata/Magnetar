//
//  RequestXMLRPC.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 15/12/2022.
//

import SwiftXMLRPC
import Foundation

indirect enum RequestXMLRPC: Hashable, Codable {
    enum Field: Hashable, Codable {
        case id
    }
    enum Encoding: Hashable, Codable {
        case base64
    }
    case `nil`
    case int8(Int8)
    case int16(Int16)
    case int32(Int32)
    case int64(Int64)
    case bool(Bool)
    case string(String)
    case double(Double)
    case date(Date)
    case data(Data)
    case `struct`([String: Self])
    case array([Self])

    case parameter(RequestParameter)

    func resolve(command: Command, server: Server) -> XMLRPC.Parameter {
        var ids: [Job.Id] = command.ids.reversed()
        func recurse(xml: Self) -> XMLRPC.Parameter {
            switch self {
            case .nil:
                return .nil
            case let .struct(values):
                return .struct(values.compactMapValues(recurse))
            case let .array(values):
                return .array(values.compactMap(recurse))
            case let .string(value):
                return .string(value)
            case let .int8(value):
                return .int8(value)
            case let .int16(value):
                return .int16(value)
            case let .int32(value):
                return .int32(value)
            case let .int64(value):
                return .int64(value)
            case let .double(value):
                return .double(value)
            case let .bool(value):
                return .bool(value)
            case let .date(value):
                return .date(value)
            case let .data(value):
                return .data(value)
            case let .parameter(parameter):
                return resolve(
                    parameter: parameter,
                    command: command,
                    server: server,
                    ids: &ids
                )
            }
        }
        return recurse(xml: self)
    }
}

extension RequestXMLRPC: RequestParameterContainer {
    typealias Value = XMLRPC.Parameter
    typealias Resolved = XMLRPC.Parameter

    func resolve(string: String) -> Value {
        .string(string)
    }

    func resolve(array: [String], separator _: String?) -> Value {
        .array(array.map { .string($0) })
    }
    
    func resolve(bool: Bool) -> Value {
        .bool(bool)
    }

    func resolve(data: Data, name _: RequestFileName) -> Value {
        .data(data)
    }

    func promote(_ value: Value?) -> Resolved {
        value!
    }
}
