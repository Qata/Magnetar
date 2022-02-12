//
//  Sorting.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 8/2/22.
//

import Algorithms

enum Sorting: Codable, Hashable {
    enum Value: Codable, Hashable {
        case field(Job.Field.Descriptor)
        case status(Status)
        
        static func allCases(additional: [Job.Field]) -> FlattenSequence<[[Sorting.Value]]> {
            [
                chain(
                    Job.Field.Descriptor.PresetField.allCases.map(Job.Field.Descriptor.preset),
                    additional.map { Job.Field.Descriptor.additional(name: $0.name, type: $0.type) }
                ).map(Self.field),
                Status.allCases.map(Self.status)
            ].joined()
        }
    }

    case ascending(Value)
    case descending(Value)
}
