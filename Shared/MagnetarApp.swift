//
//  MagnetarApp.swift
//  Shared
//
//  Created by Charles Maria Tor on 8/2/22.
//

import SwiftUI

@main
struct MagnetarApp: App {
    static let jobUpdate = Global.store.postMiddlewareSyncActions.filter { actions in
        actions.contains {
            if case .update(.jobs) = $0 {
                return true
            } else {
                return false
            }
        }
    }
    static let jobSet = Global.store.postMiddlewareSyncActions.filter { actions in
        actions.contains {
            if case .set(.jobs) = $0 {
                return true
            } else {
                return false
            }
        }
    }
    
    static let refresh = Global.store
        .$state
        .map(\.refreshInterval)
        .removeDuplicates()
        .filter(>.zero)
        .map { interval in
            jobSet.map { _ in
                Timer.publish(every: interval, on: RunLoop.main, in: .common)
                    .autoconnect()
                    .first()
            }
            .switchToLatest()
        }
        .switchToLatest()
        .sink { _ in
            Global.store.dispatch(async: .command(.fetch(.all)))
        }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    _ = Self.refresh
                }
        }
    }
}
