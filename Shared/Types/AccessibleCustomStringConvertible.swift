//
//  AccessibleCustomStringConvertible.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 8/2/22.
//

import Foundation

protocol AccessibleCustomStringConvertible: Hashable, CustomStringConvertible {
    var accessibleDescription: String { get }
}

extension Date: AccessibleCustomStringConvertible {
    var accessibleDescription: String {
        formatted(date: .numeric, time: .standard)
    }
}

extension String: AccessibleCustomStringConvertible {
    var accessibleDescription: String {
        self
    }
}
