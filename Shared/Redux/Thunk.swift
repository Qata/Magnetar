//
//  Thunk.swift
//  Thunk
//
//  Created by Charles Maria Tor on 26/8/21.
//

import Recombine
import Combine
import UserNotifications
import MonadicJSON
import CoreMedia
import CasePaths

enum AppError: Error {
    case serverError(URLError)
    case jsonDecoding(JSONParser.Error)
    case jsonParsing(JSONParseError)
    case finalParsing(Error)
    case invalidUsernameOrPassword
    case invalidTokenWithoutRecourse
    case commandMissing
    case tokenRequestFailed
    case unableToConvertTypeLosslessly
}

extension Publisher where Output == Global.State {
    var server: AnyPublisher<Server, Failure> {
        flatMap(\.selectedServer.publisher).eraseToAnyPublisher()
    }
}

typealias QueryResult = Either<[Action], (data: Data, command: Command.Descriptor, context: APIDescriptor)>

extension Publisher where Output == Global.State, Failure == Never {
    func query(
        command actionCommand: Command
    ) -> AnyPublisher<QueryResult, AppError> {
        func extractCommands(server: Server) -> AnyPublisher<(Server, Command.Descriptor), AppError> {
            server.api
                .commands[actionCommand.discriminator]
                .publisher(nilError: .commandMissing)
                .map { (server, $0) }
                .eraseToAnyPublisher()
        }
        
        func handleAuthentication(
            _ auth: Authentication,
            server: Server,
            response: HTTPURLResponse
        ) -> Result<[Action]?, AppError> {
            switch auth {
            case let .password(code):
                return (code == response.statusCode).if(
                    true: .failure(.invalidUsernameOrPassword),
                    false: .success(nil)
                )
            case let .token(token):
                switch token {
                case let .header(field, code, _):
                    return .success(
                        (response.statusCode == code).if(
                            true: [
                                response
                                    .value(forHTTPHeaderField: field)
                                    .map { .sync(.set(.token($0))) }
                                ?? .async(.command(.requestToken(andThen: actionCommand))),
                                .async(.command(actionCommand))
                            ]
                        )
                    )
                }
            }
        }

        func handleRequest(
            server: Server,
            command: Command.Descriptor
        ) -> AnyPublisher<QueryResult, AppError> {
            func handleTask(
                _ task: (data: Data, response: URLResponse)
            ) -> AnyPublisher<Either<[Action], Data>, AppError> {
                guard let httpResponse = task.response as? HTTPURLResponse else {
                    return Fail(error: .serverError(.init(.badServerResponse)))
                        .eraseToAnyPublisher()
                }
                return server.api
                    .authentication
                    .publisher
                    .flatMap {
                        handleAuthentication($0, server: server, response: httpResponse)
                            .publisher
                            .compactMap { $0 }
                            .map(Either.left)
                    }
                    .first()
                    .replaceEmpty(with: .right(task.data))
                    .eraseToAnyPublisher()
            }
            
            return URLSession.shared
                .dataTaskPublisher(for: command.request.urlRequest(for: server, ids: actionCommand.ids))
                .mapError(AppError.serverError)
                .flatMap(handleTask)
                .map { $0.mapRight { ($0, command, server.api) } }
                .eraseToAnyPublisher()
        }
        
        return server
            .setFailureType(to: AppError.self)
            .flatMap(extractCommands)
            .flatMap(handleRequest)
            .eraseToAnyPublisher()
    }
    
    func query<T: JSONInitialisable>(
        command actionCommand: Command,
        transform: @escaping (T) throws -> [Action]
    ) -> AnyPublisher<Action, AppError> {
        if case .requestToken(andThen: .requestToken) = actionCommand {
            return Fail(error: .tokenRequestFailed)
                .eraseToAnyPublisher()
        } else {
            return query(command: actionCommand)
                .flatMap { (_ queryResult: QueryResult) -> AnyPublisher<Action, AppError> in
                    switch queryResult {
                    case let .left(actions):
                        return actions.publisher
                            .setFailureType(to: AppError.self)
                            .eraseToAnyPublisher()
                    case let .right((data, command, context)):
                        switch command.expected {
                        case let .json(payload):
                            return JSONParser.parse(data: data)
                                .publisher
                                .mapError(AppError.jsonDecoding)
                                .flatMap { json in
                                    Result {
                                        try T(from: json, against: payload, context: context)
                                    }
                                    .publisher
                                    .mapError { .jsonParsing($0 as! JSONParseError) }
                                    .flatMap { value in
                                        Result {
                                            try transform(value)
                                        }
                                        .publisher
                                        .mapError(AppError.finalParsing)
                                        .flatMap(\.publisher)
                                    }
                                }
                                .eraseToAnyPublisher()
                        }
                    }
                }
                .eraseToAnyPublisher()
        }
    }
    
    func query<T: JSONInitialisable>(
        command: Command,
        setting transform: @escaping (T) throws -> SyncAction.Set
    ) -> AnyPublisher<Action, AppError> {
        query(command: command, transform: { try [.sync(.set(transform($0)))] })
    }
}

extension Global {
    static let thunk = Thunk<State, AsyncAction, SyncAction, Global.Environment> { store, action, _ -> AnyPublisher<Action, Never> in
        let state = store.state.changes.first()
        switch action {
        case .start:
            return store.state.changes
                .map(\.refreshInterval)
                .removeDuplicates()
                .filter(>.zero)
                .map { interval in
                    Timer.publish(every: interval, on: RunLoop.main, in: .common)
                        .autoconnect()
                        .map { _ in () }
                }
                .switchToLatest()
                .prepend(())
                .map { .async(.command(.fetch(.all))) }
                .prefix(
                    // Cancel if `start` is run again.
                    untilOutputFrom: store.actions.async.all
                        .first(matching: /Action.Async.start)
                )
                .eraseToAnyPublisher()
        case let .command(command):
            switch command {
            case let .requestToken(andThen: command):
                return state
                    .query(command: command)
                    .flatMap { $0.left.publisher.flatMap(\.publisher) }
                    .liftError()
            case let .fetch(amount):
                return state.server
                    .flatMap { server in
                        state
                            .query(
                                command: command,
                                transform: { (value: [Job.Raw]) in
                                    let jobs = try Dictionary(
                                        value
                                            .map { try JobViewModel(from: $0, context: server.api) }
                                            .map { ($0.id, $0) },
                                        uniquingKeysWith: { $1 }
                                    )
                                    switch amount {
                                    case .all:
                                        return [.sync(.set(.jobs(jobs)))]
                                    case let .some(ids):
                                        return [
                                            .sync(.update(.jobs(
                                                .init(
                                                    ids.map { ($0, jobs[$0]) },
                                                    uniquingKeysWith: { $1 }
                                                )
                                            )))
                                        ]
                                    }
                                }
                            )
//                            .prefix(
//                                // Cancel/retry if another command comes in.
//                                untilOutputFrom: store.actions.async.all
//                                    .first {
//                                        !((/Action.Async.command..Command.requestToken) ~= $0)
//                                    }
//                            )
                            .prefix(
                                // Cancel/retry if the jobs data gets updated.
                                untilOutputFrom: store.actions.sync.middleware.post
                                    .first(matching: /Action.Sync.update..Action.Sync.Update.jobs)
                            )
                            .prefix(
                                // Cancel/retry if any jobs data gets removed.
                                untilOutputFrom: store.actions.sync.middleware.post
                                    .first(matching: /Action.Sync.delete..Action.Sync.Delete.jobs)
                            )
                            .replaceEmpty(with: .async(action))
                    }
                    .liftError()
            case .start, .startNow, .pause, .stop:
                return state
                    .query(command: command)
                    .flatMap { $0.left.publisher.flatMap(\.publisher) }
                    .append(.async(.command(.fetch(.some(command.ids)))))
                    .append(
                        Just(.async(.command(.fetch(.some(command.ids)))))
                            .delay(for: 0.5, scheduler: DispatchQueue.main)
                            .setFailureType(to: AppError.self)
                    )
                    .liftError()
            case .remove, .deleteData:
                return state
                    .query(command: command)
                    .flatMap { $0.left.publisher.flatMap(\.publisher) }
                    .append(.sync(.delete(.jobs(command.ids))))
                    .liftError()
            case .addMagnet, .addFile:
                return Empty()
                    .eraseToAnyPublisher()
            }
        }
    }
}

extension Publisher where Output == Action {
    func liftError() -> AnyPublisher<Action, Never> {
        `catch` {
            Just(.sync(.error(String(describing: $0))))
        }
        .eraseToAnyPublisher()
    }
}
