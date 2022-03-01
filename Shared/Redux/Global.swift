import Recombine
import Foundation

typealias MainStore = Store<Global.State, AsyncAction, SyncAction>
typealias SubStore<State: Equatable, AsyncAction, SyncAction> = LensedStore<State, AsyncAction, SyncAction>

enum Global {
    class Environment {
    }
    
    static let environment = Environment()

    static let store = MainStore(
        state: .init(
            queries: [],
            servers: [],
            selectedServer: transmissionServer,
            refreshInterval: 2,
            sorting: .ascending(.field(.preset(.name)))
        ),
        reducer: Reducer.main,
        thunk: thunk,
        sideEffect: .init { actions, environment in
            print("::\(actions)")
        },
        environment: environment,
        publishOn: DispatchQueue.main
    )
}
