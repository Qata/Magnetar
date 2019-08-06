//
//  TransferTotals.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import SwiftUI

struct TransferTotals: View {
    let downloadSpeed: TorrentViewModel.Speed
    let uploadSpeed: TorrentViewModel.Speed
    
    init(torrents: [TorrentViewModel]) {
        downloadSpeed = .init(bytes: torrents.reduce(0, { $0 + $1.torrent.downloadSpeed }))
        uploadSpeed = .init(bytes: torrents.reduce(0, { $0 + $1.torrent.uploadSpeed }))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("↑ \(uploadSpeed.description)")
                .accessibility(label: Text("Upload speed"))
                .accessibility(value: Text(uploadSpeed.accessibleDescription))
            Text("↓ \(downloadSpeed.description)")
                .accessibility(label: Text("Download speed"))
                .accessibility(value: Text(downloadSpeed.accessibleDescription))
        }
        .font(.footnote)
    }
}
