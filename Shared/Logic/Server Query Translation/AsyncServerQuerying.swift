//
//  AsyncServerQuerying.swift
//  Magnetar (iOS)
//
//  Created by Charles Maria Tor on 14/7/22.
//

import Foundation
import UIKit
import Combine
import MonadicJSON
import Overture
import Alamofire
import SwiftXMLRPC

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
            .publisher
            .setFailureType(to: AppError.self)
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
                return Publishers.Concatenate(
                    prefix: server.api
                        .errors
                        .publisher
                        .flatMap {
                            handleError($0, code: httpResponse.statusCode, data: data)
                                .publisher
                                .flatMap { Fail(error: $0) }
                        },
                    suffix: server.api
                        .authentication
                        .publisher
                        .flatMap {
                            handleAuthentication($0, server: server, response: httpResponse)
                                .publisher
                                .flatMap(\.publisher)
                                .map { .left(.init(actions: $0)) }
                        }
                )
                .first()
                .replaceEmpty(with: .right(data))
                .eraseToAnyPublisher()
            }

            switch command.request.method {
            case .post(payload: .multipartFormData):
                let request = command.request.afRequest(
                    for: server,
                    command: actionCommand
                )
                return request
                    .publishData()
                    .value()
                    .handleEvents(receiveOutput: { data in
                        Swift.print("+++ Received \(String(describing: String(data: data, encoding: .ascii)))")
                    })
                    .mapError(AppError.afError)
                    .map {
                        .right(
                            QueryResult.Success(
                                data: $0,
                                command: command,
                                context: server.api
                            )
                        )
                    }
                    .eraseToAnyPublisher()
            default:
                break
            }

            let urlRequest = command.request.urlRequest(
                for: server,
                command: actionCommand
            )
            return URLSession.shared
                .dataTaskPublisher(for: urlRequest)
//                .handleEvents(receiveOutput: { data, _ in
//                    Swift.print(
//                    """
//                    +++ Sent \(actionCommand.discriminator) to \(urlRequest)
//                    +++ Body \(String(describing: urlRequest.httpBody.map(flip(curry(String.init(data:encoding:)))(.ascii))))
//                    +++ Received \(String(describing: String(data: data, encoding: .ascii)))
//                    """
//                    )
//                })
                .mapError(AppError.urlError)
                .flatMap(handleTask(data:response:))
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

        func handleError(
            _ error: APIDescriptor.Error,
            code: Int,
            data: Data
        ) -> AppError? {
            guard error.codes.contains(code) else {
                return nil
            }
            let html = try? AttributedString(html: data)

            switch error.type {
            case .password:
                return .authenticationFailure(html: html)
            case .forbidden:
                return .resourceForbidden(html: html)
            }
        }

        func handleAuthentication(
            _ auth: Authentication,
            server: Server,
            response: HTTPURLResponse
        ) -> Result<[Action]?, AppError> {
            switch auth {
            case .basic:
                return .success(nil)
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
                            ?? [.async(.command(.login(andThen: [actionCommand])))]
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
    func query<T: StructuredResponseInitialisable>(
        command actionCommand: Command,
        transform: @escaping (T) throws -> [Action]
    ) -> AnyPublisher<[Action], AppError> {
        if case let .login(andThen: next) = actionCommand, case .login? = next.first {
            // Prevents infinite looping by failing on a nested token request.
            return Fail(error: .tokenRequestFailed)
                .eraseToAnyPublisher()
        } else {
            return query(command: actionCommand)
                .flatMap { (queryResult: QueryResponse) -> AnyPublisher<[Action], AppError> in
                    switch queryResult {
                    case let .left(retry):
                        return Just(retry.actions)
                            .setFailureType(to: AppError.self)
                            .eraseToAnyPublisher()
                    case let .right(response):
//                        Swift.print("+++\(actionCommand)\(String(data: response.data, encoding: .ascii)!)")
                        switch response.command.expected {
                        case nil:
                            return Empty(outputType: [Action].self, failureType: AppError.self)
                                .eraseToAnyPublisher()
                        case let .xmlRpc(payload):
                            return XMLRPC.Response.deserialize(
                                from: String(data: response.data, encoding: .utf8)!,
                                sourceName: "XMLRPC"
                            )
                            .publisher
                            .mapError(AppError.finalParsing)
                            .flatMap { xml in
                                Result {
                                    try T(
                                        from: StructuredResponse(xml: xml),
                                        against: Payload.StructuredResponse(xml: payload),
                                        context: response.context
                                    )
                                }
                                .publisher
                                .mapError {
                                    .responseParsing(
                                        $0 as! ResponseParseError,
                                        command: actionCommand.discriminator
                                    )
                                }
                                .flatMap { value in
                                    Result {
                                        try transform(value)
                                    }
                                    .publisher
                                    .mapError(AppError.finalParsing)
                                }
                            }
                            .eraseToAnyPublisher()
                        case let .json(payload):
                            return JSONParser.parse(data: response.data)
                                .publisher
                                .mapError {
                                    AppError.jsonDecoding(
                                        $0,
                                        command: actionCommand.discriminator
                                    )
                                }
                                .flatMap { json in
                                    Result {
                                        try T(
                                            from: StructuredResponse(json: json),
                                            against: Payload.StructuredResponse(json: payload),
                                            context: response.context
                                        )
                                    }
                                    .publisher
                                    .mapError {
                                        .responseParsing(
                                            $0 as! ResponseParseError,
                                            command: actionCommand.discriminator
                                        )
                                    }
                                    .flatMap { value in
                                        Result {
                                            try transform(value)
                                        }
                                        .publisher
                                        .mapError(AppError.finalParsing)
                                    }
                                }
                                .eraseToAnyPublisher()
                        }
                    }
                }
                .eraseToAnyPublisher()
        }
    }

    func query<T: StructuredResponseInitialisable>(
        command: Command,
        setting transform: @escaping (T) throws -> SyncAction.Set
    ) -> AnyPublisher<[Action], AppError> {
        query(command: command, transform: { try [.sync(.set(transform($0)))] })
    }
}
