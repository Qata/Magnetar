//
//  Ratio.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

struct Ratio: CustomStringConvertible {
    static let numberFormatter: Atomic<NumberFormatter> = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        return .init(formatter)
    }()
    let description: String
    let accessibleDescription: String
    
    init(_ torrent: Torrent) {
        let ratio = (torrent.downloaded != 0).if(
            true: torrent.uploaded / torrent.downloaded,
            false: 0
        )
        let description = [
            "\(ratio, formatter: Self.numberFormatter)",
            1.description
        ]
        self.description = description
            .joined(separator: " : ")
        accessibleDescription = description
            .joined(separator: " to ")
    }
}
