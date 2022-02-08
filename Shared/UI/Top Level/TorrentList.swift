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
    @StateObject var store: MainStore = Global.store

    var body: some View {
        List {
            Section(header: ServerStatusHeader(status: .online)) {
                if let jobs = store.state.selectedServer?.jobs {
                    ForEach(jobs, id: \.id, content: TorrentRow.init)
                }
            }
        }
        .listStyle(PlainListStyle())
        .modifier(TopBar())
        .onAppear {
            store.dispatch(async: .command(.fetch))
        }
    }
}

private struct TopBar: ViewModifier {
    @StateObject var store: MainStore = Global.store

    func body(content: Content) -> some View {
        #if os(iOS)
        return content
            .navigationBarItems(
                leading: store.state.selectedServer.map(\.jobs).map(TransferTotals.init),
                trailing: Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                }
            )
            .navigationBarTitle(store.state.selectedServer?.name ?? "")
        #else
        return content
        #endif
    }

    func refresh() {
        store.dispatch(async: .command(.fetch))
    }
}
