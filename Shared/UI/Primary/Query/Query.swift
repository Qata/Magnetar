//
//  Query.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 21/2/22.
//

import Foundation

struct Query: Codable, Hashable {
    enum Component: Codable, Hashable, CustomStringConvertible {
        case string(String)
        case query
        
        var description: String {
            switch self {
            case let .string(string):
                return string
            case .query:
                return ".query"
            }
        }
    }
    
    struct QueryItem: Codable, Hashable, CustomStringConvertible {
        var name: String
        var value: Component
        
        var description: String {
            "\(name) = \(value.description)"
        }
    }

    var name = ""
    let base: URL
    var path: [Component]
    var queryItems: [QueryItem]

    func url(for query: String) -> URL? {
        func string(for component: Component) -> String {
            switch component {
            case .string(let string):
                return string
            case .query:
                return query
            }
        }
        
        var url = URLComponents(url: base, resolvingAgainstBaseURL: true)
        url?.path = path
            .map(string(for:))
            .map("/"+)
            .joined()
        url?.queryItems = queryItems.map { item in
            .init(
                name: item.name,
                value: string(for: item.value)
            )
        }
        return url?.url(relativeTo: nil)
    }
}

extension Query {
    init?(url: URL) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        path = components
            .path
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
            .map(Query.Component.string)
        queryItems = components
            .queryItems?
            .compactMap {
                Optional.zip($0.name, $0.value)
                    .map { .init(name: $0, value: .string($1)) }
            }
        ?? []

        components.path = ""
        components.queryItems = nil
        guard let url = components.url(relativeTo: nil) else {
            return nil
        }
        self.base =  url
    }
}
