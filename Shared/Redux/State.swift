//
//  State.swift
//  Magnetar
//
//  Created by Charlie Tor on 21/10/20.
//

import Foundation

extension Global {
    struct State: Codable, Hashable {
        var queries: [Query]
        var servers: [Server]
        var selectedServer: Server?
        var refreshInterval: TimeInterval
        var sorting: Sorting
        var errors: [String] = []
    }
}
