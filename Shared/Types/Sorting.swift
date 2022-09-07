//
//  Sorting.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 8/2/22.
//

import Algorithms
import Foundation

extension SortOrder: CustomStringConvertible {
    public var description: String {
        String(reflecting: self)
    }
}

struct Sorting: Codable, Hashable {
    enum Order: String, Codable, Hashable, CaseIterable, CustomStringConvertible {
        case ascending
        case descending
        
        var description: String {
            rawValue.capitalized
        }
        
        func comparator<T: Comparable>() -> (T, T) -> Bool {
            switch self {
            case .ascending:
                return (<)
            case .descending:
                return (>)
            }
        }
    }

    var order: Order = .ascending
    var value: Job.Field.Descriptor = .preset(.name)
}
