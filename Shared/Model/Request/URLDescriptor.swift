//
//  URLDescriptor.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 16/9/2022.
//

import Foundation

struct RequestEndpoint: Codable, Hashable {
    enum Path: Codable, Hashable, ExpressibleByStringLiteral {
        case component(String)
        case parameter(RequestParameter)
        
        init(stringLiteral value: StringLiteralType) {
            self = .component(value)
        }
    }

    var path: [Path]
    var queryItems: RequestQueryItems?

    func appending(_ descriptor: Self) -> Self {
        .init(
            path: path + descriptor.path,
            queryItems: queryItems.map {
                .init(queryItems: $0.queryItems + (descriptor.queryItems?.queryItems ?? []))
            } ?? descriptor.queryItems
        )
    }
    
    func resolve(command: Command, server: Server) -> EndpointDescriptor {
        var ids: [String] = command.ids.reversed()
        return .init(
            path: path.map {
                switch $0 {
                case let .component(component):
                    return component
                case let .parameter(parameter):
                    return $0.resolve(
                        parameter: parameter,
                        command: command,
                        server: server,
                        ids: &ids
                    )
                }
            },
            queryItems: queryItems?.queryItems.map { item -> Magnetar.QueryItem in
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
        )
    }
}

extension RequestEndpoint.Path: RequestParameterContainer {
    typealias Value = String
    typealias Resolved = String
    
    func resolve(array: [String]) -> String {
        array.joined(separator: ",")
    }
    
    func resolve(string: String) -> String {
        string
    }

    func promote(_ value: String?) -> String {
        value ?? ""
    }
}

struct URLDescriptor: Codable, Hashable {
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
