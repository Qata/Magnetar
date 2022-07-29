//
//  Job.swift
//  Magnetar (iOS)
//
//  Created by Charles Maria Tor on 9/2/22.
//

import MonadicJSON
import Foundation

enum Job {
    struct Descriptor: Codable, Hashable {
        var status: [Status: [LosslessValue<String>]]
    }

    struct Field: Codable, Hashable, AccessibleCustomStringConvertible {
        enum Descriptor: Codable, Hashable, CustomStringConvertible {
            enum FieldType: Codable, Hashable {
                case unixDate
                case speed
                case size
                case seconds
                case string
                case bool
                // Useful for APIs that return arrays.
                case irrelevant

                func jobField(for json: JSON, name: String) -> Job.Field? {
                    switch (self, json) {
                    case let (.unixDate, .number(value)):
                        return TimeInterval(value)
                            .map(Date.init(timeIntervalSince1970:))
                            .map { .init(name: name, value: .unixDate($0)) }
                    case let (.speed, .number(value)):
                        return Double(value)
                            .map { Speed(bytes: .init(max(0, $0))) }
                            .map { .init(name: name, value: .speed($0)) }
                    case let (.size, .number(value)):
                        return Double(value)
                            .map { Size(bytes: .init(max(0, $0))) }
                            .map { .init(name: name, value: .size($0)) }
                    case let (.seconds, .number(value)):
                        return Double(value)
                            .map { number in
                                (number < 0).if(
                                    true: ETA.infinite,
                                    false: ETA.finite(seconds: UInt(number))
                                )
                            }
                            .map { .init(name: name, value: .seconds($0)) }
                    case let (.string, .string(value)):
                        return .init(name: name, value: .string(value))
                    case let (.bool, .bool(value)):
                        return .init(name: name, value: .bool(value))
                    default:
                        return nil
                    }
                }
            }
            enum PresetField: String, Codable, Hashable, CaseIterable, CustomStringConvertible {
                case name
                case status
                case id
                case uploadSpeed
                case downloadSpeed
                case uploaded
                case downloaded
                case size
                case eta
                
                var description: String {
                    switch self {
                    case .eta, .id:
                        return rawValue.uppercased()
                    default:
                        return rawValue
                            .unCamelCased
                            .joined(separator: " ")
                            .capitalized
                    }
                }
            }
            struct AdHocField: Codable, Hashable, CustomStringConvertible {
                var name: String
                var type: FieldType

                var description: String {
                    name
                }
            }
            case preset(PresetField)
            case adHoc(AdHocField)
            
            var description: String {
                switch self {
                case let .preset(field):
                    return field.description
                case let .adHoc(field):
                    return field.description
                }
            }
        }

        enum Value: Codable, Hashable, Comparable, AccessibleCustomStringConvertible {
            case unixDate(Date)
            case speed(Speed)
            case size(Size)
            case seconds(ETA)
            case string(String)
            case bool(Bool)

            static func < (lhs: Self, rhs: Self) -> Bool {
                switch (lhs, rhs) {
                case let (.unixDate(lhs), .unixDate(rhs)):
                    return lhs < rhs
                case let (.speed(lhs), .speed(rhs)):
                    return lhs < rhs
                case let (.size(lhs), .size(rhs)):
                    return lhs < rhs
                case let (.seconds(lhs), .seconds(rhs)):
                    return lhs < rhs
                case let (.string(lhs), .string(rhs)):
                    return lhs < rhs
                case let (.bool(lhs), .bool(rhs)):
                    switch (lhs, rhs) {
                    case (false, true):
                        return true
                    default:
                        return false
                    }
                default:
                    return false
                }
            }

            var description: String {
                switch self {
                case let .unixDate(date):
                    return date.description
                case let .speed(speed):
                    return speed.description
                case let .size(size):
                    return size.description
                case let .seconds(eta):
                    return eta.description
                case let .string(string):
                    return string
                case let .bool(bool):
                    return bool.description.capitalized
                }
            }

            var accessibleDescription: String {
                switch self {
                case let .unixDate(date):
                    return date.accessibleDescription
                case let .speed(speed):
                    return speed.accessibleDescription
                case let .size(size):
                    return size.accessibleDescription
                case let .seconds(eta):
                    return eta.accessibleDescription
                case let .string(string):
                    return string
                case let .bool(bool):
                    return bool.description.capitalized
                }
            }
        }

        let name: String
        let value: Value

        init(
            name: String,
            value: Value
        ) {
            self.name = name
            self.value = value
        }
        
        var description: String {
            value.description
        }
        
        var accessibleDescription: String {
            value.accessibleDescription
        }
    }
    
    struct Raw: Hashable {
        @LosslessValue var name: String?
        @LosslessValue var status: String?
        @LosslessValue var id: String?
        @LosslessValue var uploadSpeed: UInt?
        @LosslessValue var downloadSpeed: UInt?
        @LosslessValue var uploaded: UInt?
        @LosslessValue var downloaded: UInt?
        @LosslessValue var size: UInt?
        @LosslessValue var eta: Int?
        var fields: [Field] = []
    }
}

extension Job.Raw: JSONInitialisable {
    init(from json: JSON, against expected: Payload.Expected, context: APIDescriptor) throws {
        func recurseObjects(json: [String: JSON], expected: [String: Payload.Expected]) throws {
            try expected
                .compactMap { key, value -> (JSON, Payload.Expected)? in
                    Optional.zip(json[key], value)
                }
                .forEach(recurse)
        }
        
        func recurse(json: JSON, expected: Payload.Expected) throws {
            switch expected {
            case let .object(expected):
                switch json {
                case let .object(json):
                    try recurseObjects(json: json, expected: expected)
                default:
                    throw JSONParseError(json: json, expected: expected)
                }
            case let .array(expected):
                switch json {
                case let .array(json):
                    try zip(json, expected)
                        .forEach { json, expected in
                            try recurse(json: json, expected: expected)
                        }
                default:
                    throw JSONParseError(json: json, expected: expected)
                }
            case let .field(field):
                switch field {
                case let .preset(field):
                    switch field {
                    case .name:
                        _name = try .init(from: json)
                    case .status:
                        _status = try .init(from: json)
                    case .id:
                        _id = try .init(from: json)
                    case .uploadSpeed:
                        _uploadSpeed = try .init(from: json)
                    case .downloadSpeed:
                        _downloadSpeed = try .init(from: json)
                    case .uploaded:
                        _uploaded = try .init(from: json)
                    case .downloaded:
                        _downloaded = try .init(from: json)
                    case .size:
                        _size = try .init(from: json)
                    case .eta:
                        _eta = try .init(from: json)
                    }
                case let .adHoc(field) where field.type == .irrelevant:
                    break
                case let .adHoc(field):
                    if let jobField = field.type.jobField(for: json, name: field.name) {
                        fields.append(jobField)
                    }
                }
            case .forEach:
                break
            }
        }
        try recurse(json: json, expected: expected)
    }
}
