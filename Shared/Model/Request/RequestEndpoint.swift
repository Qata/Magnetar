//
//  URLDescriptor.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 16/9/2022.
//

import Foundation

struct RequestEndpoint: Codable, Hashable {
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
        var ids: [Job.Id] = command.ids.reversed()
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
