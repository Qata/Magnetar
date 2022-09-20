//
//  Server.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 18/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import Combine

struct Server: Hashable, Codable {
    var url: URL
    var user: String?
    var password: String?
    var token: String?
    var port: UInt16
    var name: String
    var downloadDirectories: [String] = []
    var api: APIDescriptor
    var refreshInterval: TimeInterval = 2
    var timeoutInterval: TimeInterval = 2
    var lastSeen: Unhashed<Date?> = .init(underlying: nil)

    var sorting: Sorting = .init()
    var filter: Set<Status> = []
}
