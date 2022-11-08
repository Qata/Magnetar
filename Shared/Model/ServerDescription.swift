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
    var errors: [Error]
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

    struct Error: Codable, Hashable {
        enum ErrorType: Codable, Hashable {
            case password
            case forbidden
        }

        let type: ErrorType
        let codes: [Int]
    }
}

struct Request: Codable, Hashable {
    enum Payload: Codable, Hashable {
        case jsonrpc(RequestJSON)
        case queryItems([RequestQueryItems.QueryItem])
        case multipartFormData(RequestMultipartFormData)
    }
    enum Method: Codable, Hashable {
        case get
        case post(payload: Payload)
        
        var method: String {
            expression {
                switch self {
                case .post:
                    "POST"
                case .get:
                    "GET"
                }
            }
        }
    }
    var method: Method
    var relativeEndpoint: RequestEndpoint = .init(path: [])

    func urlRequest(for server: Server, command: Command) -> URLRequest {
        func constructRequest() -> URLRequest {
            let url = server.url
            let port = server.port
            let endpoint = server.api.endpoint
                .appending(relativeEndpoint)
                .resolve(command: command, server: server)
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            components?.queryItems = endpoint.queryItems?.asURLQueryItems()
            components?.port = numericCast(port)
            var request = URLRequest(
                url: endpoint.path.reduce(into: components!.url!) {
                    $0.appendPathComponent($1)
                },
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
            )
            server.api.authentication.forEach { auth in
                switch auth {
                case .basic:
                    Optional.zip(
                        server.user,
                        server.password
                    )
                    .flatMap {
                        "\($0):\($1)".data(using: .utf8)?.base64EncodedString()
                    }
                    .map {
                        request.setValue("Basic \($0)", forHTTPHeaderField: "Authorization")
                    }
                case let .token(.header(field, code: _)):
                    if let token = server.token {
                        request.setValue(token, forHTTPHeaderField: field)
                    }
                }
            }
            request.httpMethod = method.method
            request.timeoutInterval = server.timeoutInterval
            return request
        }
        var request = constructRequest()
        switch method {
        case .get:
            return request
        case let .post(payload):
            switch payload {
            case let .multipartFormData(multipartFormData):
                multipartFormData
                    .resolve(command: command, server: server, request: &request)
            case let .queryItems(queryItems):
                request.httpBody = RequestQueryItems(queryItems: queryItems)
                    .resolve(command: command, server: server)
                    .compactMap { item in
                        item.name.urlEncoded.map {
                            ($0, item.value?.urlEncoded)
                        }
                    }
                    .map { "\($0)=\($1 ?? "")" }
                    .map(\.description)
                    .joined(separator: "&")
                    .data(using: .utf8)
            case let .jsonrpc(payload):
                request.httpBody = try! JSONEncoder().encode(
                    payload
                        .resolve(command: command, server: server)
                        .encodable()
                )
            }
        }
        return request
    }
}

enum Authentication: Codable, Hashable {
    enum Token: Codable, Hashable {
        case header(field: String, code: Int)
    }
    case token(Token)
    case basic

    var headerField: String? {
        switch self {
        case let .token(.header(field, _)):
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

struct JSONParseError: Error, CustomStringConvertible {
    let json: JSON
    let expected: Payload.JSON

    var description: String {
        String("Expected \(expected) but encountered \(json)")
    }
}
