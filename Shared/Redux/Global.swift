import Recombine
import Foundation
import KeychainAccess

typealias MainStore = Store<Global.State, AsyncAction, SyncAction>
typealias SubStore<State: Equatable, AsyncAction, SyncAction> = LensedStore<State, AsyncAction, SyncAction>

enum Global {
    class Environment {
    }
    static let environment = Environment()
    static let keychain = Keychain(service: "com.Qata.Magnetar")
    static let store = MainStore(
        state: .init(
            persistent: Global.keychain[data: "persistent"].flatMap { try? JSONDecoder().decode(State.PersistentState.self, from: $0) } ??
                .init(
                    queries: [],
                    servers: [transmissionServer, transmissionServer2],
                    apis: [transmissionAPI],
                    selectedServer: transmissionServer
                )
        ),
        reducer: Reducer.main,//.debugActions(actionFormat: .labelsOnly),
        thunk: thunk.debug(actionFormat: .labelsOnly),
        environment: environment,
        publishOn: DispatchQueue.main
    )
}
