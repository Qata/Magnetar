//
//  Ratio.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

fileprivate let numberFormatter: Atomic<NumberFormatter> = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 2
    return .init(formatter)
}()

struct Ratio: CustomStringConvertible {
    let description: String
    let accessibleDescription: String
    
    init(_ torrent: Torrent) {
        let description = numberFormatter.access {
            $0.string(for:
                (torrent.downloaded != 0).if(
                    true: torrent.uploaded / torrent.downloaded,
                    false: 0
                )
            )
        }!
        self.description = [description, ":", 1.description]
            .joined()
        accessibleDescription = [description, "to", 1.description]
            .joined(separator: " ")
    }
}
