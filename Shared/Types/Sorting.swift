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

    enum Value: Codable, Hashable, CustomStringConvertible {
        case presetField(Job.Field.Descriptor.PresetField)
        case adHocField(Job.Field.Descriptor.AdHocField)
        case status(Status)
        
        var description: String {
            switch self {
            case let .status(status):
                return "\(status.description) (Status)"
            case let .adHocField(field):
                return "\(field.description) (Field)"
            case let .presetField(field):
                return "\(field.description) (Field)"
            }
        }
    }

    var order: Order = .ascending
    var value: Value = .presetField(.name)
}
