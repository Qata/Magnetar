//
//  ServerRunner.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 6/2/22.
//

import Foundation
import Combine

enum Command: Codable, Hashable {
    struct Descriptor: Codable, Hashable {
        var expected: Payload? = nil
        var request: Request
    }

    enum FetchType: Codable, Hashable {
        case all
        case some([Job.Id])
    }

    indirect case login(andThen: [Self])
    case info
    case fetch(FetchType)
    case start([Job.Id])
    case stop([Job.Id])
    case pause([Job.Id])
    case remove([Job.Id])
    case deleteData([Job.Id])
    case addURI(String, location: String?)
    case addFile(Data, name: String?, location: String?)

    var ids: [Job.Id] {
        switch self {
        case let .start(ids),
            let .stop(ids),
            let .pause(ids),
            let .remove(ids),
            let .deleteData(ids):
            return ids
        case let .fetch(ids):
            switch ids {
            case let .some(ids):
                return ids
            case .all:
                return []
            }
        case .login,
                .info,
                .addURI,
                .addFile:
            return []
        }
    }
    
    var uri: String? {
        switch self {
        case let .addURI(uri, _):
            return uri
        default:
            return nil
        }
    }

    var location: String? {
        switch self {
        case let .addURI(_, location):
            return location
        case let .addFile(_, _, location):
            return location
        default:
            return nil
        }
    }
    
    var fileName: String? {
        switch self {
        case let .addFile(_, name, _):
            return name
        default:
            return nil
        }
    }

    var file: Data? {
        switch self {
        case let .addFile(data, _, _):
            return data
        default:
            return nil
        }
    }
}

extension Command {
    enum Discriminator: String, Codable, Hashable, CustomStringConvertible {
        case info
        case login
        case fetch
        case start
        case stop
        case pause
        case remove
        case deleteData
        case addURI
        case addFile
        
        var description: String {
            rawValue
                .unCamelCased
                .joined(separator: " ")
                .capitalizingFirstLetter()
        }

        func command(for ids: [Job.Id]) -> Command? {
            switch self {
            case .start:
                return .start(ids)
            case .stop:
                return .stop(ids)
            case .pause:
                return .pause(ids)
            case .remove:
                return .remove(ids)
            case .deleteData:
                return .deleteData(ids)
            case .fetch:
                return .fetch(.some(ids))
            case .login, .addURI, .addFile, .info:
                return nil
            }
        }
    }

    var discriminator: Discriminator {
        switch self {
        case .info:
            return .info
        case .login:
            return .login
        case .fetch:
            return .fetch
        case .start:
            return .start
        case .stop:
            return .stop
        case .pause:
            return .pause
        case .remove:
            return .remove
        case .deleteData:
            return .deleteData
        case .addURI:
            return .addURI
        case .addFile:
            return .addFile
        }
    }
}

extension Payload {
    var adHocFields: [Job.Field.Descriptor.AdHocField] {
        var fields = [Job.Field.Descriptor.AdHocField]()

        func recurse(expected: Payload.StructuredResponse) {
            switch expected {
            case let .dictionary(expected):
                expected.values.forEach(recurse)
            case let .array(expected):
                expected.forEach(recurse)
            case let .parameter(parameter):
                switch parameter {
                case let .field(field):
                    switch field {
                    case .preset:
                        break
                    case let .adHoc(field) where field.type == .irrelevant:
                        break
                    case let .adHoc(field):
                        fields.append(field)
                    }
                case .token, .destination:
                    break
                }
            case let .forEach(expected):
                expected.forEach(recurse)
            case .string, .bool, .int, .date, .data:
                break
            }
        }
        switch self {
        case let .json(expected):
            recurse(expected: StructuredResponse(json: expected))
        case let .xmlRpc(expected):
            try? recurse(expected: StructuredResponse(xml: expected))
        }
        return fields.sorted(keyPath: \.name)
    }
}
