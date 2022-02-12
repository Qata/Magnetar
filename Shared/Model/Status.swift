//
//  Status.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import Algorithms

enum Status: String, Codable, Hashable, CaseIterable {
    case stopped
    case seeding
    case downloading
    case downloadQueued
    case seedQueued
    case checkingFiles
    case fileCheckQueued
    case paused
    case unknown
    
    var description: String {
        rawValue
            .chunked(by: { !$1.isUppercase })
            .joined(separator: " ")
            .capitalized
    }
}
