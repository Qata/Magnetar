//
//  RequestQueryItems.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 16/9/2022.
//

import Foundation

struct RequestQueryItems: Hashable, Codable {
    struct QueryItem: Hashable, Codable {
        enum QueryValue: Hashable, Codable, ExpressibleByStringLiteral, ExpressibleByNilLiteral {
            case value(String? = nil)
            case parameter(RequestParameter)

            init(stringLiteral value: StringLiteralType) {
                self = .value(value)
            }

            init(nilLiteral: ()) {
                self = .value(nil)
            }
        }
        let name: String
        let value: QueryValue
    }
    let queryItems: [QueryItem]

    func appending(_ descriptor: Self) -> Self {
        .init(
            queryItems: queryItems + descriptor.queryItems
        )
    }

    func resolve(command: Command, server: Server) -> [Magnetar.QueryItem] {
        var ids: [Job.Id] = command.ids.reversed()
        return queryItems.map { item -> Magnetar.QueryItem in
            switch item.value {
            case let .value(value):
                return .init(name: item.name, value: value)
            case let .parameter(parameter):
                return item.resolve(
                    parameter: parameter,
                    command: command,
                    server: server,
                    ids: &ids
                )
            }
        }
    }
}

extension RequestQueryItems: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: QueryItem...) {
        self.queryItems = elements
    }
}

extension RequestQueryItems.QueryItem: RequestParameterContainer {
    typealias Value = String
    typealias Resolved = QueryItem

    func promote(_ value: String?) -> Resolved {
        QueryItem(name: name, value: value)
    }

    func resolve(string: String) -> Value {
        string
    }
    
    func resolve(bool: Bool) -> String {
        bool.description
    }
    
    func resolve(data: Data, name: RequestFileName) -> Value {
        fatalError("Bytes cannot be encoded to a query item")
    }

    func resolve(array: [String], separator: String?) -> Value {
        array.joined(separator: separator ?? ",")
    }
}
