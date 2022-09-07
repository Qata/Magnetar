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
        let expected: Payload
        let request: Request
    }
    
    enum Discriminator: String, Codable, Hashable, CustomStringConvertible {
        case requestToken
        case fetch
        case start
        case startNow
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
                .capitalized
        }
    }
    
    enum FetchType: Hashable {
        case all
        case some([String])
    }

    indirect case requestToken(andThen: Self)
    case fetch(FetchType)
    case startNow([String])
    case start([String])
    case stop([String])
    case pause([String])
    case remove([String])
    case deleteData([String])
    case addURI(String, location: String?)
    case addFile(Data, location: String?)
    
    var ids: [String] {
        switch self {
        case let .start(ids):
            return ids
        case let .stop(ids):
            return ids
        case let .pause(ids):
            return ids
        case let .remove(ids):
            return ids
        case let .deleteData(ids):
            return ids
        case let .fetch(ids):
            switch ids {
            case let .some(ids):
                return ids
            case .all:
                return []
            }
        case let .startNow(ids):
            return ids
        case .addURI, .requestToken, .addFile:
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

    var discriminator: Discriminator {
        switch self {
        case .requestToken:
            return .requestToken
        case .fetch:
            return .fetch
        case .start:
            return .start
        case .startNow:
            return .startNow
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
        
        func recurse(expected: Payload.Expected) {
            switch expected {
            case let .object(expected):
                expected.values.forEach(recurse)
            case let .array(expected):
                expected.forEach(recurse)
            case .string:
                break
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
            }
        }
        switch self {
        case let .json(expected):
            recurse(expected: expected)
        }
        return fields.sorted(keyPath: \.name)
    }
}
