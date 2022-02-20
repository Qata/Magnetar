//
//  MagnetarApp.swift
//  Shared
//
//  Created by Charles Maria Tor on 8/2/22.
//

import SwiftUI
import Combine

@main
struct MagnetarApp: App {
    init() {
        Global.store.dispatch(async: .start)
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
