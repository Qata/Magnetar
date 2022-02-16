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
    @State var cancellables: Set<AnyCancellable> = []
    
    init() {
        let jobUpdate = Global.store.postMiddlewareSyncActions.filter { actions in
            actions.contains {
                if case .update(.jobs) = $0 {
                    return true
                } else {
                    return false
                }
            }
        }
        let jobSet = Global.store.postMiddlewareSyncActions.filter { actions in
            actions.contains {
                if case .set(.jobs) = $0 {
                    return true
                } else {
                    return false
                }
            }
        }
        Global.store
            .$state
            .map(\.refreshInterval)
            .removeDuplicates()
            .filter(>.zero)
            .map { interval in
                jobSet.map { _ in
                    Timer.publish(every: interval, on: RunLoop.main, in: .common)
                        .autoconnect()
                        .first()
                        .map { _ in () }
                }
                .switchToLatest()
            }
            .switchToLatest()
            .prepend(())
            .map { _ in .async(.command(.fetch(.all))) }
            .sink {
                Global.store.dispatch(actions: $0)
            }
            .store(in: &cancellables)
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
