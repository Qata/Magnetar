//
//  ServerRunner.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 6/2/22.
//

import Foundation
import Combine

enum Command: Hashable {
    struct Descriptor: Codable, Hashable {
        var expected: Payload? = nil
        var request: Request
    }

    enum FetchType: Hashable {
        case all
        case some([String])
    }

    indirect case login(andThen: Self)
    case fetch(FetchType)
    case start([String])
    case stop([String])
    case pause([String])
    case remove([String])
    case deleteData([String])
    case addURI(String, location: String?)
    case addFile(Data, location: String?)

    var ids: [String] {
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
        case let .addFile(_, location):
            return location
        default:
            return nil
        }
    }

    var file: Data? {
        switch self {
        case let .addFile(data, _):
            return data
        default:
            return nil
        }
    }
}

extension Command {
    enum Discriminator: String, Codable, Hashable, CustomStringConvertible {
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
    }

    var discriminator: Discriminator {
        switch self {
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
        
        func recurse(expected: Payload.JSON) {
            switch expected {
            case let .object(expected):
                expected.values.forEach(recurse)
            case let .array(expected):
                expected.forEach(recurse)
            case let .field(field):
                switch field {
                case .preset:
                    break
                case let .adHoc(field) where field.type == .irrelevant:
                    break
                case let .adHoc(field):
                    fields.append(field)
                }
            case let .forEach(expected):
                expected.forEach(recurse)
            case .string, .bool, .token:
                break
            }
        }
        switch self {
        case let .json(expected):
            recurse(expected: expected)
        }
        return fields.sorted(keyPath: \.name)
    }
}
