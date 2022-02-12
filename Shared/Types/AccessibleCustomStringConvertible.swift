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

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

extension Date: AccessibleCustomStringConvertible {
    var accessibleDescription: String {
        dateFormatter.string(from: self)
    }
}

extension String: AccessibleCustomStringConvertible {
    var accessibleDescription: String {
        self
    }
}
