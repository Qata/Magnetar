//
//  QueryItem.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 18/9/2022.
//

import Foundation

struct QueryItem: Codable, Hashable, CustomStringConvertible {
    var name: String
    var value: String?
    
    var description: String {
        value.map {
            "\(name)=\($0)"
        } ?? name
    }
}

extension Sequence where Element == QueryItem {
    func asURLQueryItems() -> [URLQueryItem] {
        self.compactMap { item in
            item.value.map {
                URLQueryItem(name: item.name, value: $0)
            }
        }
    }
}
