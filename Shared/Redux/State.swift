//
//  State.swift
//  Magnetar
//
//  Created by Charlie Tor on 21/10/20.
//

import Foundation

extension Global {
    struct State: Codable, Hashable {
        struct PersistentState: Codable, Hashable {
            var queries: [Query]
            var servers: [Server]
            var selectedServer: Server?
            var refreshInterval: TimeInterval
        }
        var persistent: PersistentState
        var errors: RingBuffer<String> = .init(count: 100)
        var jobs: [String: JobViewModel] = [:]
    }
}
