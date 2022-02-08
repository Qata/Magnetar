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

typealias QueryResult = Either<[Global.Action], (data: Data, command: ServerCommand, context: APIDescriptor)>

extension Publisher where Output == Global.State, Failure == Never {
    func query(
        command actionCommand: Command
    ) -> AnyPublisher<QueryResult, AppError> {
        func extractCommands(server: Server) -> AnyPublisher<(Server, ServerCommand), AppError> {
            Just(server)
                .setFailureType(to: AppError.self)
                .zip(
                    server.api
                        .commands[actionCommand.discriminator]
                        .publisher(nilError: .commandMissing)
                )
                .eraseToAnyPublisher()
        }
        
        func handleAuthentication(_ auth: Authentication, server: Server, response: HTTPURLResponse) -> Result<[Global.Action]?, AppError> {
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

        func handleRequest(server: Server, command: ServerCommand) -> AnyPublisher<QueryResult, AppError> {
            func handleTask(
                _ task: (data: Data, response: URLResponse)
            ) -> AnyPublisher<Either<[Global.Action], Data>, AppError> {
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
                .dataTaskPublisher(for: command.request.urlRequest(for: server))
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
        transform: @escaping (T) throws -> [Global.Action]
    ) -> AnyPublisher<Global.Action, AppError> {
        func handleResult(_ queryResult: QueryResult) -> AnyPublisher<Global.Action, AppError> {
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

        if case .requestToken(andThen: .requestToken) = actionCommand {
            return Fail(error: .tokenRequestFailed)
                .eraseToAnyPublisher()
        }
        return query(command: actionCommand)
            .flatMap(handleResult)
            .eraseToAnyPublisher()
    }
    
    func query<T: JSONInitialisable>(
        command: Command,
        setting transform: @escaping (T) throws -> Global.RefinedAction.Set
    ) -> AnyPublisher<Global.Action, AppError> {
        query(command: command, transform: { try [.sync(.set(transform($0)))] })
    }
}

extension Global {
    static let thunk = Thunk<State, RawAction, RefinedAction, Global.Environment> { state, action, _ -> AnyPublisher<Action, Never> in
        switch action {
        case let .command(command):
            switch command {
            case let .requestToken(andThen: command):
                return state
                    .query(command: command)
                    .flatMap { $0.left.publisher.flatMap(\.publisher) }
                    .liftError()
            case .fetch:
                return state.server
                    .flatMap { server in
                        state.query(
                            command: command,
                            setting: { (value: [Job]) in
                                try .jobs(
                                    value.map {
                                        try JobViewModel(from: $0, context: server.api)
                                    }
                                )
                            }
                        )
                    }
                    .liftError()
            case let .start(files):
                return Just(.sync(.set(.jobs([])))).eraseToAnyPublisher()
            case let .stop(files):
                    return Just(.sync([])).eraseToAnyPublisher()
            case let .pause(files):
                return Just(.sync([])).eraseToAnyPublisher()
            case .remove(_):
                return Just(.sync([])).eraseToAnyPublisher()
            case .delete(_):
                return Just(.sync([])).eraseToAnyPublisher()
            case .addMagnet(_):
                return Just(.sync([])).eraseToAnyPublisher()
            case .addFile(_):
                return Just(.sync([])).eraseToAnyPublisher()
            }
        }
    }
        .debug()
}

extension Publisher where Output == Global.Action {
    func liftError() -> AnyPublisher<Global.Action, Never> {
        `catch` {
            Just(.sync(.error(String(describing: $0))))
        }
        .eraseToAnyPublisher()
    }
}
