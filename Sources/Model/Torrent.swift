//
//  Torrent.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

struct Torrent {
    let name: String
    let status: Status
    let hash: String
    let uploadSpeed: UInt
    let downloadSpeed: UInt
    let uploaded: UInt
    let downloaded: UInt
    let size: UInt
    let eta: ETA
}
