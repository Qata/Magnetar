//
//  TorrentRow.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

struct TorrentRow: View {
    var viewModel: TorrentViewModel
    var torrent: Torrent {
        viewModel.torrent
    }

    var body: some View {
        VStack {
            Text(torrent.name)
                .font(.headline)
                .accessibility(label: Text("Name"))
                .padding(.bottom, -2)
            ProgressBar(current: torrent.downloaded, max: torrent.size)
                .foregroundColor(viewModel.statusColor)
            VStack {
                HStack {
                    HStack {
                        Spacer()
                        Text("\(viewModel.speed(for: \.downloadSpeed).description) ↓")
                    }
                    HStack {
                        Text("↑ \(viewModel.speed(for: \.uploadSpeed).description)")
                        Spacer()
                    }
                }
                HStack {
                    HStack {
                        Text(viewModel.status)
                        Spacer()
                    }
                    Text("Ratio: \(viewModel.ratio.description)")
                    HStack {
                        Spacer()
                        if [.downloading, .seeding].contains(torrent.status) {
                            Text("ETA: \(viewModel.eta.description)")
                        }
                    }
                }
            }
            .font(.caption)
        }
        .accessibilityElement()
        .accessibility(label: Text(verbatim: torrent.name))
        .accessibility(value: Text(viewModel.accessibleDescription))
    }
}
