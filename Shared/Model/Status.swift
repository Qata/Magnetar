//
//  Status.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import Algorithms

enum Status: String, Codable, Hashable, CaseIterable, Comparable {
    static func < (lhs: Status, rhs: Status) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
    
    case downloadQueued
    case downloading
    case seeding
    case seedQueued
    case checkingFiles
    case fileCheckQueued
    case paused
    case stopped
    case unknown
    
    var description: String {
        rawValue
            .unCamelCased
            .joined(separator: " ")
            .capitalized
    }
}
