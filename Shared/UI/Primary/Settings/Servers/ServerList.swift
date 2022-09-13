//
//  ServerList.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 31/8/2022.
//

import SwiftUI

struct ServerList: View {
    var body: some View {
        StoreView(\.persistent.servers) { servers, _ in
            List {
                ForEach(servers, id: \.self) {
                    Text($0.name)
                }
            }
            .navigationTitle("Servers")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    NavigationLink {
                        AddServerForm()
                    } label: {
                        SystemImage.plus
                    }
                }
            }
        }
    }
}
