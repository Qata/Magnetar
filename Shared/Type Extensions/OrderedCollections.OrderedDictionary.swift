//
//  OrderedCollection.OrderedDictionary.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 22/10/2022.
//

import OrderedCollections

extension OrderedDictionary {
    /// Allows lensing properties before comparison by the std lib `sorted(by:)` function, using the `by` closure.
    mutating func sort<T>(keyPath path: KeyPath<Element, T>, by: (T, T) -> Bool) {
        sort {
            by($0[keyPath: path], $1[keyPath: path])
        }
    }

    /// Allows lensing properties before comparison by the std lib `sorted(by:)` function, using the `by` closure.
    mutating func sort<T>(keyPath path: KeyPath<Element, T>) where T: Comparable {
        sort(keyPath: path, by: <)
    }

    func filter<T>(keyPath path: KeyPath<Element, T>, _ isIncluded: (T) throws -> Bool) rethrows -> Self {
        try filter {
            try isIncluded($0[keyPath: path])
        }
    }
}
