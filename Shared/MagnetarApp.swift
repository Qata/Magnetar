//
//  MagnetarApp.swift
//  Shared
//
//  Created by Charles Maria Tor on 8/2/22.
//

import SwiftUI
import Combine
import KeychainAccess

class PersistentStorage {
    var cancellables = Set<AnyCancellable>()
    init() {
        Global.store
            .$state
            .map(\.persistent)
            .removeDuplicates()
            .sink {
                print("::Storing")
                Global.keychain[data: "persistent"] = try? JSONEncoder().encode($0)
            }
            .store(in: &cancellables)
    }
}

@main
struct MagnetarApp: App {
    @State var persistentStorageWatcher = PersistentStorage()

    init() {
        Global.store.dispatch(async: .start)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
//                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}
