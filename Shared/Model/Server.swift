//
//  Server.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 18/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import Combine
import Tagged

struct Server: Hashable, Codable {
    typealias Name = Tagged<Self, String>

    var url: URL
    var user: String?
    var password: String?
    var token: String?
    var port: UInt16
    var name: Name
    var downloadDirectories: [String] = []
    var api: APIDescriptor
    var refreshInterval: TimeInterval = 2
    var timeoutInterval: TimeInterval = 30
    var lastSeen: Unhashed<Date?> = .init(underlying: nil)

    var sorting: Sorting = .init()
    var filter: Set<Status> = []
}
