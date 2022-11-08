//
//  ContentView.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 11/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import SwiftUI
import CasePaths

struct MainView: View {
    let store = Global.store

    func tabItem<Content: View>(image: SystemImage, name: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        NavigationStack {
            content()
        }
        .tabItem {
            image
            Text(name)
        }
    }

    var body: some View {
        TabView(
            selection: store.binding(
                get: \.navigation,
                send: { .navigate(.tab($0)) }
            )
        ) {
            tabItem(
                image: .arrowUpArrowDown,
                name: "Transfers"
            ) {
                JobListView()
            }
            .tag(Global.State.Navigation.jobs)
            tabItem(
                image: .magnifyingglass,
                name: "Queries"
            ) {
                MainQueryView()
            }
            .tag(Global.State.Navigation.queries)
            tabItem(
                image: .gear,
                name: "Settings"
            ) {
                SettingsView()
            }
            .tag(Global.State.Navigation.settings)
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
