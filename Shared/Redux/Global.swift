import Recombine
import Foundation

typealias MainStore = Store<Global.State, Global.RawAction, Global.RefinedAction>

enum Global {
    class Environment {
    }
    
    static let environment = Environment()

    static let store = MainStore(
        state: .init(
            servers: [],
            selectedServer: transmissionServer,
            refreshInterval: 2,
            sorting: .ascending(.field(.name))
        ),
        reducer: Reducer.main,
        thunk: thunk,
        sideEffect: .init { _, _ in
            
        },
        environment: environment,
        publishOn: DispatchQueue.main
    )
}
