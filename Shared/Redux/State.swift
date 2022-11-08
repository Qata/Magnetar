//
//  State.swift
//  Magnetar
//
//  Created by Charlie Tor on 21/10/20.
//

import Foundation
import OrderedCollections

extension Global {
    struct State: Codable, Hashable {
        struct PersistentState: Codable, Hashable {
            var queries: [WebQuery] = []
            var servers: [Server] = []
            var apis: [APIDescriptor]
            var selectedServer: Server?
            var queuedCommands: [Command] = []
        }
        struct Jobs: Codable, Hashable {
            struct TransferTotals: Codable, Hashable {
                var uploadSpeed: Speed
                var downloadSpeed: Speed
            }

            struct Filtered: Codable, Hashable {
                let all: OrderedDictionary<Job.Id, JobViewModel>
                let statuses: Set<Status>
                let pairedStatuses: OrderedDictionary<Job.Id, Status>
                let viewModels: [JobViewModel]
                var ids: Set<Job.Id> {
                    Set(all.keys)
                }

                init(all: OrderedDictionary<Job.Id, JobViewModel> = [:]) {
                    self.all = all
                    viewModels = .init(all.values)
                    statuses = Set(all.values.map(\.status))
                    pairedStatuses = all.mapValues(\.status)
                }
            }
            var all: OrderedDictionary<Job.Id, JobViewModel> = [:] {
                didSet {
                    pairedStatuses = all.mapValues(\.status)
                    statuses = Set(pairedStatuses.values)
                    totals = .init(jobs: all)
                }
            }
            var statuses: Set<Status> = []
            var pairedStatuses: OrderedDictionary<Job.Id, Status> = [:]
            var filtered: Filtered = .init()
            var totals: TransferTotals = .init(uploadSpeed: .zero, downloadSpeed: .zero)
        }
        var persistent: PersistentState
        var errors: RingBuffer<ErrorModel> = .init(count: 100)
        var jobs: Jobs = .init()
        var searchText: String = ""
        var navigation: Navigation
    }
}

extension Global.State.Jobs.TransferTotals {
    init(jobs: OrderedDictionary<Job.Id, JobViewModel>) {
        downloadSpeed = .init(bytes: jobs.values.reduce(0, { $0 + $1.downloadSpeed.bytes }))
        uploadSpeed = .init(bytes: jobs.values.reduce(0, { $0 + $1.uploadSpeed.bytes }))
    }
}

extension Global.State {
    enum Navigation: Codable, Hashable {
        case jobs
        case queries
        case settings
    }
}
