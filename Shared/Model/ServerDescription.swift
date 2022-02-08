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
    var jobs: JobDescriptor
    var commands: [Command.Discriminator: ServerCommand]
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
        case post(endpoint: EndpointDescriptor, payload: JSON)
    }
    case jsonrpc(JSONRPC)
    
    var method: String {
        switch self {
        case .jsonrpc:
            return "POST"
        }
    }

    func urlRequest(for server: Server) -> URLRequest {
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
                request.httpBody = try! JSONEncoder().encode(payload.encodable())
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

enum EndpointType: Codable, Hashable {
    case get
    case post
}

enum EndpointPayload: Codable, Hashable {
    case jsonrpc(JSON)
}

struct ServerAction: Codable {
    enum Access: Codable {
        case rpc
        case query
        case post
    }
    
    enum Action: Codable {
        case start
        case stop
        case pause
        case delete
        case add
    }
    
    enum DataType: Codable {
        case identifier
        case constant(String)
    }
    
    let queryItems: [String: DataType]
}

struct PayloadParseError: Error {
    let json: JSON
    let payload: Any
}

indirect enum DescriptorConstant: Codable, Hashable {
    case string(String)
    case int(Int)
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

protocol JSONInitialisable {
    init(from json: JSON, against expected: ExpectedPayload, context: APIDescriptor) throws
}

extension Array: JSONInitialisable where Element: JSONInitialisable {
    init(from json: JSON, against expected: ExpectedPayload, context: APIDescriptor) throws {
        func recurse(json: JSON, against expected: ExpectedPayload) throws -> [Element] {
            switch (json, expected) {
            case let (.object(json), .object(expected)):
                return try zip(
                    json.sorted(keyPath: \.key).map(\.value),
                    expected.sorted(keyPath: \.key).map(\.value)
                )
                .flatMap { json, expected -> [Element] in
                    try recurse(json: json, against: expected)
                }
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

//struct Token: JSONInitialisable {
//    let token: String
//
//    init(from json: JSON, against expected: ExpectedPayload) throws {
//
//    }
//}

let transmissionEndpoint = EndpointDescriptor(path: ["transmission", "rpc"])

let jobsJSON = JSON.object([
    "arguments": .object([
        "torrents": .array([
            .object([
                "hashString": .string("DLKENDLXKD"),
                "name": .string("Test"),
                "status": .number("0"),
                "rateUpload": .number("4843"),
                "rateDownload": .number("3438932"),
                "uploadedEver": .number("4334234"),
                "downloadedEver": .number("44342332"),
                "sizeWhenDone": .number("234234324234234"),
                "doneDate": .number("14000230292"),
            ]),
            .object([
                "hashString": .string("EKJHKHE"),
                "name": .string("Test"),
                "status": .number("0"),
                "rateUpload": .number("4843"),
                "rateDownload": .number("3438932"),
                "uploadedEver": .number("4334234"),
                "downloadedEver": .number("44342332"),
                "sizeWhenDone": .number("234234324234234"),
                "doneDate": .number("14000230292"),
            ]),
            .object([
                "hashString": .string("DSLFJDSLF"),
                "name": .string("Test"),
                "status": .number("0"),
                "rateUpload": .number("4843"),
                "rateDownload": .number("3438932"),
                "uploadedEver": .number("4334234"),
                "downloadedEver": .number("44342332"),
                "sizeWhenDone": .number("234234324234234"),
                "doneDate": .number("14000230292"),
            ]),
        ])
    ])
])

let transmissionServer = Server(
    url: URL(string: "http://mini.local")!,
    user: "lotte",
    password: "lol",
    port: 9091,
    name: "Home",
    api: .init(
        authentication: [
            .password(invalidCode: 401),
            .token(
                .header(
                    field: "X-Transmission-Session-Id",
                    code: 409,
                    request: .jsonrpc(
                        .post(
                            endpoint: transmissionEndpoint,
                            payload: .object(["method": .string("port-test")])
                        )
                    )
                )
            )
        ],
        jobs: .init(
            status: [
                .stopped: 0,
                .seeding: 6,
                .downloading: 4,
                .downloadQueued: 3,
                .seedQueued: 5,
                .checkingFiles: 2,
                .fileCheckQueued: 1
            ],
            eta: .init(
                infinity: [-1, -2]
            )
        ),
        commands: [
            .fetch: .init(
                expected: .json(.object([
                    "arguments": .object([
                        "torrents": .forEach([
                            .object([
                                "hashString": .id,
                                "name": .name,
                                "status": .status,
                                "rateUpload": .uploadSpeed,
                                "rateDownload": .downloadSpeed,
                                "uploadedEver": .uploaded,
                                "downloadedEver": .downloaded,
                                "sizeWhenDone": .size,
                                "eta": .eta,
                            ])
                        ])
                    ])
                ])),
                request: .jsonrpc(.post(
                    endpoint: transmissionEndpoint,
                    payload: .object([
                        "method": .string("torrent-get"),
                        "arguments": .object([
                            "fields": .array([
                                .string("hashString"),
                                .string("name"),
                                .string("status"),
                                .string("rateUpload"),
                                .string("rateDownload"),
                                .string("uploadedEver"),
                                .string("downloadedEver"),
                                .string("sizeWhenDone"),
                                .string("eta"),
                            ])
                        ])
                    ])
                ))
            )
        ]
    )
)
