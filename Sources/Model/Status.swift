//
//  Status.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

extension Torrent {
    enum Status: String, CaseIterable {
        case downloading
        case stopped
        case seeding
        case queuedDownloading
        case queuedSeeding
    }
}
