//
//  ETA.swift
//  Magnetar (iOS)
//
//  Created by Charles Maria Tor on 9/2/22.
//

import SwiftUI

enum ETA: Hashable, Codable, AccessibleCustomStringConvertible {
    case finite(seconds: UInt)
    case infinite
    
    init(_ eta: Int) {
        if eta < 0 {
            self = .infinite
        } else {
            self = .finite(seconds: numericCast(eta))
        }
    }
    
    var rawDescription: Either<String, [(String, UInt)]> {
        switch self {
        case let .finite(seconds):
            let values = [
                ("years", seconds / UInt(TimeInterval(weeks: 1)) / 52),
                ("weeks", seconds / UInt(TimeInterval(weeks: 1)) % 52),
                ("days", seconds / UInt(TimeInterval(days: 1)) % 7),
                ("hours", seconds / UInt(TimeInterval(hours: 1)) % 24),
                ("minutes", seconds / UInt(TimeInterval(minutes: 1)) % 60),
                ("seconds", seconds % UInt(TimeInterval(minutes: 1)))
            ]
            let (offset, first) = values.enumerated().first { $1.1 > 0 }
                ?? values.enumerated().reversed().first!
            let second = values.dropFirst(offset + 1).first { $1 > 0 }
            return .right([first, second].compactMap { $0 })
        case .infinite:
            return .left("∞")
        }
    }
    
    var description: String {
        rawDescription.mapRight {
            $0.map { $1.description + String($0.first!) }
            .joined(separator: " ")
        }
        .value
    }
    
    var accessibleDescription: String {
        rawDescription.mapRight {
            $0.map { label, amount in
                [
                amount.description,
                String(label.dropLast((amount == 1).if(true: 1, false: 0)))
                ]
                .joined(separator: " ")
            }
            .joined(separator: ", ")
        }
        .value
    }
}
