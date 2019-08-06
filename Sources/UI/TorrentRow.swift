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
                .onTapGesture {
                    Publishers.Sequence(sequence: [
                        App.Action.set(.name("Hey \(self.torrent.name)"))
                        ])
                        .append(Just(.set(.name("Hello \(self.torrent.name)"))).delay(for: 3, scheduler: DispatchQueue.main))
                        .subscribe(App.store)
                }
            ProgressBar(current: torrent.downloaded, max: torrent.size)
                .foregroundColor(viewModel.statusColor)
                .accessibility(label: Text("Progress"))
            VStack {
                HStack {
                    HStack {
                        Spacer()
                        Text("\(viewModel.speed(for: \.downloadSpeed).description) ↓")
                            .accessibility(label: Text("Download speed"))
                            .accessibility(value: Text(viewModel.speed(for: \.downloadSpeed).accessibleDescription))
                    }
                    HStack {
                        Text("↑ \(viewModel.speed(for: \.uploadSpeed).description)")
                            .accessibility(label: Text("Upload speed"))
                            .accessibility(value: Text(viewModel.speed(for: \.uploadSpeed).accessibleDescription))
                        Spacer()
                    }
                }
                HStack {
                    HStack {
                        Text(viewModel.status)
                        Spacer()
                    }
                    Text("Ratio: \(viewModel.ratio.description)")
                        .accessibility(label: Text("Upload ratio"))
                        .accessibility(value: Text(viewModel.ratio.accessibleDescription))
                    HStack {
                        Spacer()
                        Text("ETA: \(viewModel.eta.description)")
                            .accessibility(label: Text("ETA"))
                            .accessibility(value: viewModel.eta.accessibleDescription)
                    }
                }
            }
            .font(.caption)
        }
    }
}
