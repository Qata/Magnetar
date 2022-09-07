//
//  ContentView.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 11/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            NavigationView {
                JobListView()
            }.tabItem {
                SystemImage.arrowTriangle2Circlepath
                Text("Transfers")
            }
            NavigationView {
                MainQueryView()
            }.tabItem {
                SystemImage.magnifyingglass
                Text("Queries")
            }
            NavigationView {
                List {
                    NavigationLink(
                        destination: EmptyView(),
                        label: Label("APIs", icon: .cloudFill)
                    )
                    NavigationLink(
                        destination: StoreView(\.persistent.servers) { servers, _ in
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
                        },
                        label: Label("Servers", icon: .serverRack)
                    )
                    NavigationLink(
                        destination: List {
                            Text("Created by Charles Maria Tor.")
                            Text("If you find this app useful, please consider supporting its continued development over on Patreon.")
                        },
                        label: Label("Info", icon: .infoCircle)
                    )
                }
            }.tabItem {
                SystemImage.gear
                Text("Settings")
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
#endif
