//
//  RequestParameter.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 16/9/2022.
//

import Foundation

enum RequestParameter: Hashable, Codable {
    enum Field: Hashable, Codable {
        case id
    }
    enum FileEncoding: Hashable, Codable {
        case base64
        case data(fileName: RequestFileName)
    }
    indirect case quoted(value: Self, quotationMark: String)
    case bool(Bool)
    case string(String)
    case username
    case password
    case token
    case uri
    case location
    case file(FileEncoding)
    case field(Field)
    case forEach(Field, separator: String? = nil)
}

extension RequestParameter: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self = .string(value)
    }
}

protocol RequestParameterContainer {
    associatedtype Value
    associatedtype Resolved

    func promote(_ value: Value?) -> Resolved
    func resolve(string: String) -> Value
    func resolve(array: [String], separator: String?) -> Value
    func resolve(bool: Bool) -> Value
    func resolve(data: Data, name: RequestFileName) -> Value
}

extension RequestParameterContainer {
    func resolve(parameter: RequestParameter, command: Command, server: Server, ids: inout [Job.Id]) -> Resolved {
        switch parameter {
        case let .string(string):
            return promote(resolve(string: string))
        case let .quoted(parameter, mark):
            func quote(_ string: String) -> Value {
                resolve(
                    string: [mark, string, mark].joined()
                )
            }
            func promoteQuote(_ string: String?) -> Resolved {
                promote(
                    string.map(quote)
                )
            }
            switch parameter {
            case .quoted:
                return resolve(parameter: parameter, command: command, server: server, ids: &ids)
            case let .string(string):
                return promoteQuote(string)
            case let .bool(bool):
                return promoteQuote(bool.description)
            case .username:
                return promoteQuote(server.user)
            case .password:
                return promoteQuote(server.password)
            case .token:
                return promoteQuote(server.token)
            case .uri:
                return promoteQuote(command.uri)
            case .location:
                return promoteQuote(command.location)
            case let .file(encoding):
                return promote(
                    command.file.map {
                        switch encoding {
                        case .base64:
                            return quote($0.base64EncodedString())
                        case let .data(fileName):
                            return resolve(
                                data: $0,
                                name: command.fileName.map(RequestFileName.string) ?? fileName
                            )
                        }
                    }
                )
            case let .field(value):
                switch value {
                case .id:
                    return promoteQuote(
                        ids.popLast()
                            .map(\.rawValue)
                    )
                }
            case let .forEach(field, separator):
                switch field {
                case .id:
                    defer { ids = [] }
                    return promote(
                        ids.isEmpty.if(
                            false: resolve(
                                array: ids.map(\.rawValue).map { [mark, $0, mark].joined() },
                                separator: separator
                            )
                        )
                    )
                }
            }
        case let .bool(bool):
            return promote(resolve(bool: bool))
        case .username:
            return promote(server.user.map(resolve(string:)))
        case .password:
            return promote(server.password.map(resolve(string:)))
        case .token:
            return promote(server.token.map(resolve(string:)))
        case .uri:
            return promote(command.uri.map(resolve(string:)))
        case .location:
            return promote(command.location.map(resolve(string:)))
        case let .file(encoding):
            return promote(
                command.file.map {
                    switch encoding {
                    case .base64:
                        return resolve(string: $0.base64EncodedString())
                    case let .data(fileName):
                        return resolve(
                            data: $0,
                            name: command.fileName.map(RequestFileName.string) ?? fileName
                        )
                    }
                }
            )
        case let .field(value):
            switch value {
            case .id:
                return promote(
                    ids.popLast()
                        .map(\.rawValue)
                        .map(resolve(string:))
                )
            }
        case let .forEach(field, separator):
            switch field {
            case .id:
                defer { ids = [] }
                return promote(
                    ids.isEmpty.if(
                        false: resolve(
                            array: ids.map(\.rawValue),
                            separator: separator
                        )
                    )
                )
            }
        }
    }
}
