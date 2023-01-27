//
//  SettingsView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 12/9/2022.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            NavigationLink(
                destination: ServerList(),
                label: Label("Servers", icon: .serverRack)
            )
            NavigationLink(
                destination: EmptyView(),
                label: Label("APIs", icon: .cloudFill)
            )
            NavigationLink(
                destination: List {
                    Text("Created by Charles Maria Tor.")
                    Text("If you find this app useful, please consider supporting its continued development over on Patreon.")
                },
                label: Label("Info", icon: .infoCircle)
            )
        }
        .navigationTitle("Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
