//
//  ServerDescription.swift
//  ServerDescription
//
//  Created by Charles Maria Tor on 14/8/21.
//

import Foundation
import SwiftUI
import Algorithms
import MonadicJSON

struct APIDescriptor: Codable, Hashable {
    var authentication: [Authentication]
    var jobs: Job.Descriptor
    var commands: [Command.Discriminator: Command.Descriptor]
    
    func available(command: Command.Discriminator) -> Bool {
        commands.keys.contains(command)
    }
}

struct QueryItem: Codable, Hashable {
    var name: String
    var value: String
}

enum QueryItemValue: Codable, Hashable {
    case string(String)
    case id
    case token
}

enum Request: Codable, Hashable {
    enum JSONRPC: Codable, Hashable {
        case post(endpoint: EndpointDescriptor, payload: RequestJSON)
    }
    case jsonrpc(JSONRPC)
    
    var method: String {
        switch self {
        case .jsonrpc:
            return "POST"
        }
    }

    func urlRequest(for server: Server, ids: [String]) -> URLRequest {
        let url = server.url
        let port = server.port
        switch self {
        case let .jsonrpc(jsonrpc):
            switch jsonrpc {
            case let .post(endpoint, payload):
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
                components?.queryItems = endpoint.queryItems.map {
                    $0.map {
                        URLQueryItem(name: $0.name, value: $0.value)
                    }
                }
                components?.user = server.user
                components?.password = server.password
                components?.port = numericCast(port)
                var request = URLRequest(
                    url: endpoint.path.reduce(into: components!.url!) {
                        $0.appendPathComponent($1)
                    },
                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
                )
                if server.token != nil, let field = server.api.authentication.firstNonNil(\.headerField) {
                    request.setValue(server.token, forHTTPHeaderField: field)
                }
                request.httpBody = try! JSONEncoder().encode(payload.resolve(ids: ids).encodable())
                request.httpMethod = method
                return request
            }
        }
    }
}

enum Authentication: Codable, Hashable {
    enum Token: Codable, Hashable {
        case header(field: String, code: Int, request: Request)
    }
    case password(invalidCode: Int)
    case token(Token)
    
    var headerField: String? {
        switch self {
        case let .token(.header(field, _, _)):
            return field
        default:
            return nil
        }
    }
}

struct EndpointDescriptor: Codable, Hashable {
    var path: [String]
    var queryItems: [QueryItem]?
}

enum SizeDescription: Codable, Hashable {
    case bytes(UInt)

    var value: UInt {
        switch self {
        case let .bytes(value):
            return value
        }
    }
}

enum SpeedDescription: Codable, Hashable {
    case bytesPerSecond(UInt)
    
    var value: UInt {
        switch self {
        case let .bytesPerSecond(value):
            return value
        }
    }
}

enum ETADescription: Codable, Hashable {
    case seconds(UInt)
    
    var value: UInt {
        switch self {
        case let .seconds(value):
            return value
        }
    }
}

struct JSONParseError: Error {
    let json: JSON
    let expected: Any
}

indirect enum RequestJSON: Hashable, Codable {
    enum Field: Hashable, Codable {
        case id
    }
    case null
    case string(String)
    case number(String)
    case bool(Bool)
    case object([String: Self])
    case array([Self])
    case field(Field)
    case forEach(Field)
    
    func resolve(ids: [String]) -> JSON {
        var ids: [String] = ids.reversed()
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
            case let .field(value):
                switch value {
                case .id:
                    return ids.popLast().map(JSON.string) ?? nil
                }
            case let .forEach(value):
                switch value {
                case .id:
                    defer { ids = [] }
                    return ids.isEmpty.if(false: .array(ids.map(JSON.string)))
                }
            }
        }
        return recurse(json: self) ?? .null
    }
}
