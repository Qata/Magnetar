//
//  AsyncServerQuerying.swift
//  Magnetar (iOS)
//
//  Created by Charles Maria Tor on 14/7/22.
//

import Foundation
import Combine
import MonadicJSON

enum QueryResult {
    struct Success {
        let data: Data
        let command: Command.Descriptor
        let context: APIDescriptor
    }
    
    struct Retry {
        let actions: [Action]
    }
}

typealias QueryResponse = Either<QueryResult.Retry, QueryResult.Success>

private extension Publisher {
    func extractCommands(command: Command, server: Server) -> AnyPublisher<(Server, Command.Descriptor), AppError> {
        server.api
            .commands[command.discriminator]
            .publisher(nilError: .commandMissing)
            .map { (server, $0) }
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output == Global.State, Failure == Never {
    func query(
        command actionCommand: Command
    ) -> AnyPublisher<QueryResponse, AppError> {
        func handleRequest(
            server: Server,
            command: Command.Descriptor
        ) -> AnyPublisher<QueryResponse, AppError> {
            func handleTask(
                data: Data,
                response: URLResponse
            ) -> AnyPublisher<Either<QueryResult.Retry, Data>, AppError> {
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: .urlError(.init(.badServerResponse)))
                        .eraseToAnyPublisher()
                }
                return server.api
                    .authentication
                    .publisher
                    .flatMap {
                        handleAuthentication($0, server: server, response: httpResponse)
                            .publisher
                            .compactMap { $0 }
                            .map { .left(.init(actions: $0)) }
                    }
                    .first()
                    .replaceEmpty(with: .right(data))
                    .eraseToAnyPublisher()
            }
            let urlRequest = command.request.urlRequest(
                for: server,
                command: actionCommand
            )
            return URLSession.shared
                .dataTaskPublisher(
                    for: urlRequest
                )
                .handleEvents(receiveOutput: { data, _ in
                    Swift.print("+++\(urlRequest) \(String(data: data, encoding: .ascii)!)")
                })
                .mapError(AppError.urlError)
                .flatMap { handleTask(data: $0, response: $1) }
                .map {
                    $0.mapRight {
                        QueryResult.Success(
                            data: $0,
                            command: command,
                            context: server.api
                        )
                    }
                }
                .eraseToAnyPublisher()
        }

        func handleAuthentication(
            _ auth: Authentication,
            server: Server,
            response: HTTPURLResponse
        ) -> Result<[Action]?, AppError> {
            switch auth {
            case let .password(codes):
                return (codes.contains(response.statusCode)).if(
                    true: .failure(.authenticationFailure),
                    false: .success(nil)
                )
            case let .token(token):
                switch token {
                case let .header(field, code):
                    // The request was missing its header token.
                    return .success(
                        (response.statusCode == code).if(
                            true: response
                                .value(forHTTPHeaderField: field)
                                .map {
                                    [
                                        // If it was returned by the request, set the token and try again.
                                        .sync(.set(.token($0))),
                                        .async(.command(actionCommand))
                                    ]
                                }
                            // Otherwise, request it and try again.
                            ?? [.async(.command(.requestToken(andThen: actionCommand)))]
                        )
                    )
                }
            }
        }

        return server
            .setFailureType(to: AppError.self)
            .flatMap { extractCommands(command: actionCommand, server: $0) }
            .flatMap { handleRequest(server: $0, command: $1) }
            .eraseToAnyPublisher()
    }
    
}

extension Publisher where Output == Global.State, Failure == Never {
    func query<T: JSONInitialisable>(
        command actionCommand: Command,
        transform: @escaping (T) throws -> [Action]
    ) -> AnyPublisher<Action, AppError> {
        if case .requestToken(andThen: .requestToken) = actionCommand {
            return Fail(error: .tokenRequestFailed)
                .eraseToAnyPublisher()
        } else {
            return query(command: actionCommand)
                .flatMap { (queryResult: QueryResponse) -> AnyPublisher<Action, AppError> in
                    switch queryResult {
                    case let .left(retry):
                        return retry.actions
                            .publisher
                            .setFailureType(to: AppError.self)
                            .eraseToAnyPublisher()
                    case let .right(response):
                        Swift.print("+++\(actionCommand)\(String(data: response.data, encoding: .ascii)!)")
                        switch response.command.expected {
                        case nil:
                            return Empty(outputType: Action.self, failureType: AppError.self)
                                .eraseToAnyPublisher()
                        case let .json(payload):
                            return JSONParser.parse(data: response.data)
                                .publisher
                                .mapError(AppError.jsonDecoding)
                                .flatMap { json in
                                    Result {
                                        try T(from: json, against: payload, context: response.context)
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
