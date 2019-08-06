//
//  TorrentViewModel.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 16/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import SwiftUI

struct TorrentViewModel {
    let torrent: Torrent
    
    var statusColor: Color {
        switch self.torrent.status {
        case .downloading:
            return .blue
        case .seeding:
            return .green
        case .stopped, .queuedSeeding, .queuedDownloading:
            return .gray
        }
    }
    
    func size(for keyPath: KeyPath<Torrent, UInt>) -> Size {
        Size(bytes: torrent[keyPath: keyPath])
    }
    
    func speed(for keyPath: KeyPath<Torrent, UInt>) -> Speed {
        Speed(bytes: torrent[keyPath: keyPath])
    }
    
    var ratio: Ratio {
        Ratio(torrent)
    }
    
    var status: String {
        switch torrent.status {
        case .downloading, .stopped, .seeding:
            return torrent.status.rawValue.capitalized
        case .queuedDownloading:
            return "Download Queued"
        case .queuedSeeding:
            return "Seed Queued"
        }
    }
    
    var eta: ETA {
        ETA(eta: torrent.eta)
    }
}
