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
import Alamofire
import Tagged
import SwiftXMLRPC

struct APIDescriptor: Codable, Hashable {
    var name: String
    var endpoint: RequestEndpoint = .init(path: [])
    var supportedJobLocators: [JobLocator] = []
    var authentication: [Authentication]
    var errors: [Error]
    var jobs: Job.Descriptor
    var commands: [Command.Discriminator: Command.Descriptor]

    func available(command: Command.Discriminator) -> Bool {
        return commands.keys.contains(command)
    }
}

extension APIDescriptor {
    enum JobLocator: Codable, Hashable {
        case pathExtension(PathExtension)
        case scheme(Scheme)
    }

    enum NameLocation: Codable, Hashable {
        case lastPathComponent
        case queryItem(String)
    }

    typealias Scheme = Tagged<Self, String>
    typealias PathExtension = Tagged<Self, String>

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
        case xmlRpc(method: String, params: [RequestXMLRPC])
        case json(RequestJSON)
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
    
    private func constructRequest(for server: Server, command: Command) -> URLRequest {
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
                .map {
                    Data("\($0):\($1)".utf8).base64EncodedString()
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
    
    func afRequest(for server: Server, command: Command) -> DataRequest {
        var urlRequest = constructRequest(for: server, command: command)
        switch method {
        case .get:
            return AF.request(urlRequest)
        case let .post(payload):
            switch payload {
            case let .multipartFormData(multipartFormData):
                return AF.upload(
                    multipartFormData: { formData in
                        multipartFormData.resolve(
                            command: command,
                            server: server,
                            formData: formData
                        )
                    },
                    with: urlRequest
                )
            case let .xmlRpc(method, payload):
                urlRequest.httpBody = XMLRPC.Call(
                    method: method,
                    params: payload.map {
                        $0.resolve(command: command, server: server)
                    }
                ).serialize()
                return AF.request(urlRequest)
            case let .json(payload):
                urlRequest.httpBody = try? JSONEncoder().encode(
                    payload
                        .resolve(command: command, server: server)
                        .encodable()
                )
                return AF.request(urlRequest)
            case let .queryItems(queryItems):
                urlRequest.httpBody = RequestQueryItems(queryItems: queryItems)
                    .resolve(command: command, server: server)
                    .compactMap { item in
                        (item.value?.urlEncoded).flatMap { value in
                            item.name.urlEncoded.map {
                                ($0, value)
                            }
                        }
                    }
                    .map { "\($0)=\($1)" }
                    .map(\.description)
                    .joined(separator: "&")
                    .data(using: .utf8)
                return AF.request(urlRequest)
            }
        }
    }

    func urlRequest(for server: Server, command: Command) -> URLRequest {
        var request = constructRequest(for: server, command: command)
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
                        (item.value?.urlEncoded).flatMap { value in
                            item.name.urlEncoded.map {
                                ($0, value)
                            }
                        }
                    }
                    .map { "\($0)=\($1)" }
                    .map(\.description)
                    .joined(separator: "&")
                    .data(using: .utf8)
            case let .json(payload):
                request.httpBody = try? JSONEncoder().encode(
                    payload
                        .resolve(command: command, server: server)
                        .encodable()
                )
            case let .xmlRpc(method, params):
                request.httpBody = XMLRPC.Call(
                    method: method,
                    params: params.map {
                        $0.resolve(command: command, server: server)
                    }
                )
                .serialize()
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
