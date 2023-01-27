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
import OrderedCollections
import Alamofire
import UIKit

enum AppError: Error {
    case afError(AFError)
    case urlError(URLError)
    case jsonDecoding(JSONParser.Error, command: Command.Discriminator)
    case responseParsing(ResponseParseError, command: Command.Discriminator)
    case losslessStringEncoding(expectedOneOf: [JSON.Discriminator])
    case finalParsing(Error)
    case authenticationFailure(html: AttributedString?)
    case resourceForbidden(html: AttributedString?)
    case invalidTokenWithoutRecourse
    case commandMissing
    case tokenRequestFailed
    case unableToConvertTypeLosslessly
    
    var title: String {
        switch self {
        case .afError:
            return "Netowrking Error"
        case .urlError:
            return "URL Error"
        case .jsonDecoding:
            return "JSON Decoding Error"
        case .responseParsing:
            return "Structure Parsing Error"
        case .finalParsing:
            return "Parsing Error"
        case .authenticationFailure:
            return "Authentication Failure"
        case .resourceForbidden:
            return "Resource Forbidden"
        case .invalidTokenWithoutRecourse:
            return "Invalid Token"
        case .commandMissing:
            return "Command Missing From Config"
        case .tokenRequestFailed:
            return "Token Request Failure"
        case .unableToConvertTypeLosslessly:
            return "Type Conversion Error"
        case .losslessStringEncoding:
            return "String Conversion Error"
        }
    }

    var description: AttributedString? {
        switch self {
        case let .afError(error):
            return .init(error.localizedDescription)
        case let .urlError(error):
            return .init(error.localizedDescription)
        case let .jsonDecoding(error, command):
            return .init("\(String(describing: error)) for \(command.description) request")
        case let .responseParsing(error, command):
            return .init("\(error.description) for \(command.description) request")
        case let .finalParsing(error):
            return .init(error.localizedDescription)
        case let .authenticationFailure(html):
            return html
        case let .resourceForbidden(html):
            return html
        case .invalidTokenWithoutRecourse:
            return nil
        case .commandMissing:
            return nil
        case .tokenRequestFailed:
            return "Failed to request token"
        case .unableToConvertTypeLosslessly:
            return "Unable to losslessly convert type"
        case let .losslessStringEncoding(expectedOneOf):
            return .init("Expected \(expectedOneOf.map(\.rawValue).joined(separator: " or "))")
        }
    }
}

extension AppError {
    #warning("Add convenience functions for common errors")
}

extension Publisher where Output == Global.State {
    var server: AnyPublisher<Server, Failure> {
        flatMap(\.persistent.selectedServer.publisher).eraseToAnyPublisher()
    }
}

extension Global {
    static let thunk = Thunk<State, AsyncAction, SyncAction, Global.Environment> { store, action, _ -> AnyPublisher<Action, Never> in
        expression {
            switch action {
            case .start:
                start(store: store)
            case let .reuploadFile(url, location):
                reuploadFile(url: url, location: location)
            case let .command(actionCommand):
                command(store: store, command: actionCommand)
                    .prefix(
                        // Cancel if the server changes.
                        untilOutputFrom: store.actions.sync.post
                            .first(matching: /Action.Sync.set..Action.Sync.Set.selectedServer)
                    )
                    .eraseToAnyPublisher()
            }
        }
    }

    private static func reuploadFile(url: URL, location: String?) -> AnyPublisher<Action, Never> {
        URLSession.shared
            .dataTaskPublisher(for: URLRequest(url: url))
            .map { data, response in
                .async(.command(.addFile(data, name: url.lastPathComponent, location: location)))
            }
            .mapError(AppError.urlError)
            .liftError()
            .eraseToAnyPublisher()
    }

    private static func command(
        store: StorePublishers<State, AsyncAction, SyncAction>,
        command: Command
    ) -> AnyPublisher<Action, Never> {
        let state = store.state.changes.first()
        switch command {
        case let .login(andThen: nextCommands):
            let commands: [Action] = nextCommands.map { .async(.command($0)) }
            return state.query(
                command: command
            ) { (value: ResponseValues) in
                value.extractActions()
            }
            .flatMap {
                Just($0).merge(
                    with: Just(commands)
                        .delay(for: 0, scheduler: DispatchQueue.main)
                )
            }
            .replaceEmpty(with: commands)
            .flatMap(\.publisher)
            .liftError()
        case .info:
            return state.query(
                command: command
            ) { (value: ResponseValues) in
                value.extractActions()
            }
            .flatMap(\.publisher)
            .liftError()
        case let .fetch(ids):
            return state.server
                .flatMap { server in
                    state.query(
                        command: command,
                        transform: { (value: [Job.Raw]) in
                            let jobs = try OrderedDictionary(
                                value
                                    .map { try JobViewModel(from: $0, context: server.api) }
                                    .map { ($0.id, $0) },
                                uniquingKeysWith: { $1 }
                            )
                            switch ids {
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
                }
                .flatMap(\.publisher)
                .prefix(
                    // Cancel if the jobs are updated.
                    untilOutputFrom: store.actions.sync.post
                        .first(matching: /Action.Sync.update..Action.Sync.Update.jobs)
                )
                .prefix(
                    // Cancel if the jobs are set.
                    untilOutputFrom: store.actions.sync.post
                        .first(matching: /Action.Sync.set..Action.Sync.Set.jobs)
                )
                .prefix(
                    // Cancel if any jobs get removed.
                    untilOutputFrom: store.actions.sync.post
                        .first(matching: /Action.Sync.delete..Action.Sync.Delete.jobs)
                )
                .prefix(
                    untilOutputFrom: NotificationCenter.default.publisher(
                        for: UIApplication.willResignActiveNotification
                    )
                )
//                .replaceEmpty(with: .async(.command(command)))
                .liftError()
        case .start, .pause, .stop, .addURI, .addFile:
            return state.query(
                command: command
            ) { (value: ResponseValues) in
                // Leveraging ResponseValues to validate the expected response.
                []
            }
            .flatMap(\.publisher)
            .append(.async(.command(.fetch(.some(command.ids)))))
            .append(
                // Some servers will queue the change of status and complete the request without setting
                // the job status, so we query a second time after a reasonable delay.
                Just(.async(.command(.fetch(.some(command.ids)))))
                    .delay(for: .milliseconds(500), scheduler: DispatchQueue.global())
                    .setFailureType(to: AppError.self)
            )
            .liftError()
        case .remove, .deleteData:
            return state.query(
                command: command
            ) { (value: ResponseValues) in
                // Leveraging ResponseValues to validate the expected response.
                []
            }
            .flatMap(\.publisher)
            .append(.sync(.delete(.jobs(command.ids))))
            .liftError()
        }
    }

    private static func start(store: StorePublishers<State, AsyncAction, SyncAction>) -> AnyPublisher<Action, Never> {
        #warning("When the UI is driven from the state, add a filter based on whether the torrent list is visible")
        return store.state.changes
            .map(\.persistent.selectedServer)
            .removeDuplicates(by: { $0?.name == $1?.name && $0?.refreshInterval == $1?.refreshInterval })
            .map { server -> AnyPublisher<Action, Never> in
                server
                    .publisher
                    .map(\.refreshInterval)
                    .filter(>.zero)
                    .flatMap {
                        Timer.publish(every: $0, on: RunLoop.main, in: .common)
                            .autoconnect()
                            .map { _ in .async(.command(.fetch(.all))) }
                            .drop(
                                untilOutputFrom: store.actions.sync.post
                                    .first(matching: /Action.Sync.set..Action.Sync.Set.jobs)
                            )
                            .prepend(.async(.command(.login(andThen: [.info, .fetch(.all)]))))
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .prefix(
                // Cancel if `start` is run again.
                untilOutputFrom: store.actions.async
                    .first(matching: /Action.Async.start)
            )
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output == Action, Failure == AppError {
    func liftError() -> AnyPublisher<Action, Never> {
        `catch` {
            Just(.sync(.create(.error($0))))
        }
        .eraseToAnyPublisher()
    }
}
