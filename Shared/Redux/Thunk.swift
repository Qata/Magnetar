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

enum AppError: Error, CustomStringConvertible {
    case urlError(URLError)
    case jsonDecoding(JSONParser.Error)
    case jsonParsing(JSONParseError)
    case finalParsing(Error)
    case authenticationFailure
    case invalidTokenWithoutRecourse
    case commandMissing
    case tokenRequestFailed
    case unableToConvertTypeLosslessly
    
    var description: String {
        switch self {
        case let .urlError(error):
            return error.localizedDescription
        case let .jsonDecoding(error):
            return error.localizedDescription
        case let .jsonParsing(error):
            return error.localizedDescription
        case let .finalParsing(error):
            return error.localizedDescription
        case .authenticationFailure:
            return "Authentication Failure"
        case .invalidTokenWithoutRecourse:
            return "Invalid Token"
        case .commandMissing:
            return "Command missing from config"
        case .tokenRequestFailed:
            return "Failed to request token"
        case .unableToConvertTypeLosslessly:
            return "Unable to losslessly convert type"
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
        let state = store.state.changes.first()
        switch action {
        case .start:
            #warning("When the UI is driven from the state, add a filter based on whether the torrent list is visible")
            return store.state.changes
                .compactMap(\.persistent.selectedServer?.refreshInterval)
                .removeDuplicates()
                .filter(>.zero)
                .map { interval in
                    Timer.publish(every: interval, on: RunLoop.main, in: .common)
                        .autoconnect()
                        .map { _ in () }
                }
                .switchToLatest()
//                .drop(
//                    untilOutputFrom: store.actions.sync.middleware.post
//                        .first(matching: /Action.Sync.set..Action.Sync.Set.token)
//                )
                .prepend(())
                .map { .async(.command(.fetch(.all))) }
                .prefix(
                    // Cancel if `start` is run again.
                    untilOutputFrom: store.actions.async.all
                        .first(matching: /Action.Async.start)
                )
                .eraseToAnyPublisher()
        case let .reuploadFile(url, location):
            return URLSession.shared
                .dataTaskPublisher(
                    for: URLRequest(url: url)
                )
                .map { data, response in
                    .async(.command(.addFile(data, location: location)))
                }
                .mapError(AppError.urlError)
                .liftError()
                .eraseToAnyPublisher()
        case let .command(command):
            switch command {
            case let .requestToken(andThen: command):
                return state
                    .query(command: command)
                    .flatMap { $0.left.publisher.flatMap(\.actions.publisher) }
                    .liftError()
            case let .fetch(ids):
                return state.server
                    .flatMap { server in
                        state.query(
                            command: command,
                            transform: { (value: [Job.Raw]) in
                                let jobs = try Dictionary(
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
                        .prefix(
                            // Cancel then retry if the jobs are updated.
                            untilOutputFrom: store.actions.sync.middleware.post
                                .first(matching: /Action.Sync.update..Action.Sync.Update.jobs)
                        )
                        .prefix(
                            // Cancel then retry if any jobs get removed.
                            untilOutputFrom: store.actions.sync.middleware.post
                                .first(matching: /Action.Sync.delete..Action.Sync.Delete.jobs)
                        )
                        .replaceEmpty(with: .async(action))
                    }
                    .liftError()
            case .start, .startNow, .pause, .stop, .addURI, .addFile:
                return state
                    .query(command: command)
                    .flatMap { $0.left.publisher.flatMap(\.actions.publisher) }
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
                    .flatMap { $0.left.publisher.flatMap(\.actions.publisher) }
                    .append(.sync(.delete(.jobs(command.ids))))
                    .liftError()
            }
        }
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
