//
//  ContentView.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 11/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import SwiftUI

struct MainView: View {
    func tabItem<Content: View>(image: SystemImage, name: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        NavigationView {
            content()
        }
        .tabItem {
            image
            Text(name)
        }
    }

    var body: some View {
        TabView {
            tabItem(
                image: .arrowUpArrowDown,
                name: "Transfers"
            ) {
                JobListView()
            }
            tabItem(
                image: .magnifyingglass,
                name: "Queries"
            ) {
                MainQueryView()
            }
            tabItem(
                image: .gear,
                name: "Settings"
            ) {
                SettingsView()
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
