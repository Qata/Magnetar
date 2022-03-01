//
//  StoreView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 22/2/22.
//

import SwiftUI
import Recombine

struct StoreView<State: Equatable, AsyncAction, SyncAction, Content: View>: View {
    @StateObject var store: LensedStore<State, AsyncAction, SyncAction>
    let content: (State, ActionLens<AsyncAction, SyncAction>) -> Content
    
    init(_ lens: LensedStore<State, AsyncAction, SyncAction>, @ViewBuilder content: @escaping (State, ActionLens<AsyncAction, SyncAction>) -> Content) {
        self._store = .init(wrappedValue: lens)
        self.content = content
    }
    
    init(_ keyPath: KeyPath<Global.State, State>, @ViewBuilder content: @escaping (State, ActionLens<AsyncAction, SyncAction>) -> Content) where AsyncAction == Action.Async, SyncAction == Action.Sync {
        self._store = .init(wrappedValue: Global.store.lensing(state: { $0[keyPath: keyPath]}))
        self.content = content
    }
    
    var body: some View {
        content(store.state, store.writeOnly())
    }
}

struct OptionalStoreView<State: Equatable, AsyncAction, SyncAction, Content: View>: View {
    @StateObject var store: LensedStore<State?, AsyncAction, SyncAction>
    let content: (State, ActionLens<AsyncAction, SyncAction>) -> Content
    
    init<Store: StoreProtocol>(
        _ store: Store,
        @ViewBuilder content: @escaping (State, ActionLens<AsyncAction, SyncAction>) -> Content
    ) where Store.State == State, Store.AsyncAction == AsyncAction, Store.SyncAction == SyncAction {
        self._store = .init(wrappedValue: store.lensing(state: { $0 }))
        self.content = content
    }
    
    init(_ keyPath: KeyPath<Global.State, State?>, @ViewBuilder content: @escaping (State, ActionLens<AsyncAction, SyncAction>) -> Content) where AsyncAction == Action.Async, SyncAction == Action.Sync {
        self._store = .init(wrappedValue: Global.store.lensing(state: { $0[keyPath: keyPath]}))
        self.content = content
    }
    
    var body: some View {
        store.state.map { content($0, store.writeOnly()) }
    }
}
