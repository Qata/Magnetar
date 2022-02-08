//
//  SettingsView.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 13/8/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import SwiftUI
import Recombine
import Combine

struct SettingsView: View {
    var body: some View {
        List {
            Text("Hello")
        }
        .modifier(TopBar())
    }
}

let fetchRequests = PassthroughSubject<(), Never>()

private struct TopBar: ViewModifier {
    @StateObject var store: MainStore = Global.store

    func body(content: Content) -> some View {
        Group {
#if os(iOS)
            content
                .navigationBarItems(
                    trailing: Button(action: { }) {
                        Image(systemName: "plus")
                    }
                )
#else
            content
#endif
        }
    }
}

#if DEBUG
struct SettingsView_Previews : PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif

