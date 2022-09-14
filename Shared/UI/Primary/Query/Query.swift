//
//  Query.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 21/2/22.
//

import Foundation

struct Query: Codable, Hashable {
    struct Parameter: Codable, Hashable {
        enum Location: String, Codable, Hashable {
            case none
            case path
            case queryItem
        }
        let location: Location
        let index: Int
        
        static var none: Self {
            .init(location: .none, index: .zero)
        }
    }

    struct Indexed<Element: Codable & Hashable>: Codable, Hashable {
        struct Component: Codable, Hashable {
            let offset: Int
            let element: Element
        }
        let components: [Component]
        
        init(elements: [Element]) {
            components = elements.enumerated().map {
                .init(offset: $0, element: $1)
            }
        }
    }

    var name = ""
    let base: URL
    var path: Indexed<String>
    var queryItems: Indexed<QueryItem>
    var parameter: Parameter?
    
    func updated(name: String, parameter: Parameter?) -> Self {
        var copy = self
        copy.name = name
        copy.parameter = parameter
        return copy
    }

    func url(for query: String) -> URL? {
        let path = path
            .components
            .map { component -> String in
                switch parameter?.index {
                case component.offset where parameter?.location == .path:
                    return query
                default:
                    return component.element
                }
            }
        let queryItems = queryItems
            .components
            .map { component -> URLQueryItem in
                switch parameter?.index {
                case component.offset where parameter?.location == .queryItem:
                    return URLQueryItem(name: component.element.name, value: query)
                default:
                    return URLQueryItem(name: component.element.name, value: component.element.value)
                }
            }

        var url = URLComponents(url: base, resolvingAgainstBaseURL: true)
        url?.path = path.map("/"+).joined()
        url?.queryItems = queryItems
        return url?.url(relativeTo: nil)
    }
}

extension Query {
    init?(url: URL) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        path = .init(
            elements: components
                .path
                .split(separator: "/", omittingEmptySubsequences: true)
                .map(String.init)
        )
        queryItems = .init(
            elements: components
                .queryItems?
                .compactMap {
                    Optional.zip($0.name, $0.value)
                        .map { .init(name: $0, value: $1) }
                }
            ?? []
        )

        components.path = ""
        components.queryItems = nil
        guard let url = components.url(relativeTo: nil) else {
            return nil
        }
        self.base =  url
    }
}
