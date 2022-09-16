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
import CasePaths

struct APIDescriptor: Codable, Hashable {
    var name: String
    var endpoint: RequestEndpoint = .init(path: [])
    var supportedURIs: [URI] = []
    var supportedFilePathExtensions: [PathExtension] = []
    var authentication: [Authentication]
    var jobs: Job.Descriptor
    var commands: [Command.Discriminator: Command.Descriptor]

    func available(command: Command.Discriminator) -> Bool {
        return commands.keys.contains(command)
    }
}

extension APIDescriptor {
    enum URI: Codable, Hashable {
        case pathExtension(PathExtension)
        case scheme(Scheme)
    }
    
    enum NameLocation: Codable, Hashable {
        case lastPathComponent
        case queryItem(String)
    }
    
    struct Scheme: Codable, Hashable {
        var value: String
        var nameLocation: NameLocation?
    }

    struct PathExtension: Codable, Hashable {
        enum Encoding: Codable, Hashable {
            case bencoding
            case xml
            case newLineSeparated
        }
        
        var value: String
        var encoding: Encoding?
    }
}

struct QueryItem: Codable, Hashable, CustomStringConvertible {
    var name: String
    var value: String?
    
    var description: String {
        "\(name)=\(value ?? "")"
    }
}

enum Request: Codable, Hashable {
    enum Payload: Codable, Hashable {
        case jsonrpc(RequestJSON)
//        case queryItems(RequestQueryItems)
    }
    case post(
        relativeEndpoint: RequestEndpoint = .init(path: []),
        payload: Payload
    )
    case get(
        relativeEndpoint: RequestEndpoint = .init(path: [])
    )

    var method: String {
        switch self {
        case .post:
            return "POST"
        case .get:
            return "GET"
        }
    }

    func urlRequest(for server: Server, command: Command) -> URLRequest {
        let url = server.url
        let port = server.port
        switch self {
        case let .get(relativeEndpoint):
            let endpoint = server.api.endpoint
                .appending(relativeEndpoint)
                .resolve(command: command)
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
            request.httpMethod = method
            request.timeoutInterval = server.timeoutInterval
//                print("+++\(String(data: request.httpBody!, encoding: .utf8)!)")
            return request
        case let .post(relativeEndpoint, payload):
            switch payload {
//            case let .queryItems(queryItems):
//
            case let .jsonrpc(payload):
                let endpoint = server.api.endpoint
                    .appending(relativeEndpoint)
                    .resolve(command: command)
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
                request.httpBody = try! JSONEncoder().encode(
                    payload
                        .resolve(command: command)
                        .encodable()
                )
                request.httpMethod = method
                request.timeoutInterval = server.timeoutInterval
//                print("+++\(String(data: request.httpBody!, encoding: .utf8)!)")
                return request
            }
        }
    }
}

enum Authentication: Codable, Hashable {
    enum Token: Codable, Hashable {
        case header(field: String, code: Int, request: Request)
        case queryItem(name: String, request: Request)
    }
    case password(invalidCodes: [Int])
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
    
    func appending(_ descriptor: Self) -> Self {
        .init(
            path: path + descriptor.path,
            queryItems: queryItems.map {
                $0 + (descriptor.queryItems ?? [])
            } ?? descriptor.queryItems
        )
    }
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
