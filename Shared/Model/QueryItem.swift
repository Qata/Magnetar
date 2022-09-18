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
        "\(name)=\(value ?? "")"
    }
}

extension Sequence where Element == QueryItem {
    func asURLQueryItems() -> [URLQueryItem] {
        self.map {
            URLQueryItem(name: $0.name, value: $0.value)
        }
    }
}
