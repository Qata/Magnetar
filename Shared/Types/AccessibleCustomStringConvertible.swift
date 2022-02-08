//
//  AccessibleCustomStringConvertible.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 8/2/22.
//

import Foundation

protocol AccessibleCustomStringConvertible: CustomStringConvertible {
    var accessibleDescription: String { get }
}
