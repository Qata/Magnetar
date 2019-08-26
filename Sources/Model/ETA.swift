//
//  ETA.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import SwiftUI

extension Torrent {
    enum ETA: ExpressibleByIntegerLiteral {
        case finite(seconds: UInt)
        case infinite
        
        init(integerLiteral value: UInt) {
            self = .finite(seconds: value)
        }
    }
}

extension TorrentViewModel {
    struct ETA: CustomStringConvertible {
        let description: String
        let accessibleDescription: String
        
        init(eta: Torrent.ETA) {
            switch eta {
            case let .finite(unix):
                let values = [
                    ("years", unix / UInt(TimeInterval(weeks: 1)) / 52),
                    ("weeks", unix / UInt(TimeInterval(weeks: 1)) % 52),
                    ("days", unix / UInt(TimeInterval(days: 1)) % 7),
                    ("hours", unix / UInt(TimeInterval(hours: 1)) % 24),
                    ("minutes", unix / UInt(TimeInterval(minutes: 1)) % 60),
                    ("seconds", unix % UInt(TimeInterval(minutes: 1)))
                ]
                
                let (offset, first) = values.enumerated().first { $1.1 > 0 }
                    ?? values.enumerated().reversed().first!
                let second = values.dropFirst(offset + 1).first { $1 > 0 }
                let compacted = [first, second].compactMap { $0 }
                description = compacted
                    .map { $1.description + String($0.first!) }
                    .joined(separator: " ")
                accessibleDescription = compacted
                    .map { label, amount in
                        [
                        amount.description,
                        String(label.dropLast((amount == 1).if(true: 1, false: 0)))
                        ]
                        .joined(separator: " ")
                    }
                    .joined(separator: ", ")
            case .infinite:
                description = "∞"
                accessibleDescription = "Never"
            }
        }
    }
}
