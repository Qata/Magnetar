//
//  TorrentList.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 19/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import SwiftUI
import Recombine

struct TorrentList: View {
    @State var items: [TorrentViewModel] =
        (0...100).map { value in
            Torrent(
                name: ["test", "value", "for"][value % 3],
                status: Torrent.Status.allCases[value % Torrent.Status.allCases.count],
                hash: UUID().description,
                uploadSpeed: .random(in: 0...50000000000),
                downloadSpeed: .random(in: 0...5000000000),
                uploaded: .random(in: 0...5000),
                downloaded: 2500,
                size: 5000,
                eta: .finite(seconds: .random(in: 0...1000000))
            )
        }.map(TorrentViewModel.init)
    
    @EnvironmentObject var store: Store<App.State, App.Action>

    var body: some View {
        List {
            Section(header: ServerStatusHeader(status: .online)) {
                ForEach(items, id: \.torrent.hash, content: TorrentRow.init)
            }
        }
        .navigationBarTitle(store.state.name)
        .navigationBarItems(leading: TransferTotals(torrents: items))
    }
}
