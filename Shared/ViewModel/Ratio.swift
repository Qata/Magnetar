//
//  Ratio.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

struct Ratio: Hashable, Codable, AccessibleCustomStringConvertible {
    static let numberFormatter: Atomic<NumberFormatter> = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        return .init(formatter)
    }()
    let downloaded: UInt
    let uploaded: UInt
    
    private var rawDescription: [String] {
        [
            "\(ratio, formatter: Self.numberFormatter)",
            1.description
        ]
    }
    
    var ratio: Double {
        (downloaded != 0).if(
            true: Double(uploaded) / Double(downloaded),
            false: 0
        )
    }

    var description: String {
        rawDescription
            .joined(separator: " : ")
    }

    var accessibleDescription: String {
        rawDescription
            .joined(separator: " to ")
    }
}
