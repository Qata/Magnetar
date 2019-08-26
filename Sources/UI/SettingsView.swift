//
//  SettingsView.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 13/8/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Text("Hello")
        }
        .navigationBarItems(
            trailing: Button(action: { }) {
                Image(systemName: "plus")
            }
        )
    }
}

#if DEBUG
struct SettingsView_Previews : PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif

