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
        var status: [Status: LosslessValue<String>]
    }

    struct Field: Codable, Hashable, AccessibleCustomStringConvertible {
        enum Descriptor: Codable, Hashable {
            enum FieldType: Codable, Hashable {
                case unixDate
                case speed
                case size
                case seconds
                case string
                case bool
                case irrelevant

                func field(for json: JSON, name: String) -> Job.Field? {
                    switch (self, json) {
                    case let (.unixDate, .number(value)):
                        return TimeInterval(value)
                            .map(Date.init(timeIntervalSince1970:))
                            .map { .init(name: name, type: self, $0) }
                    case let (.speed, .number(value)):
                        return Double(value)
                            .map { Speed(bytes: .init(max(0, $0))) }
                            .map { .init(name: name, type: self, $0) }
                    case let (.size, .number(value)):
                        return Double(value)
                            .map { Size(bytes: .init(max(0, $0))) }
                            .map { .init(name: name, type: self, $0) }
                    case let (.seconds, .number(value)):
                        return Double(value)
                            .map { number in
                                (number < 0).if(
                                    true: ETA.infinite,
                                    false: ETA.finite(seconds: UInt(number))
                                )
                            }
                            .map { .init(name: name, type: self, $0) }
                    case let (.string, .string(value)):
                        return .init(name: name, type: self, value)
                    case let (.bool, .bool(value)):
                        return .init(name: name, type: self, value.description.capitalized)
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
            case preset(PresetField)
            case additional(name: String, type: FieldType)
        }
        
        let name: String
        let type: Magnetar.Job.Field.Descriptor.FieldType
        let description: String
        let accessibleDescription: String

        init<T: AccessibleCustomStringConvertible>(
            name: String,
            type: Magnetar.Job.Field.Descriptor.FieldType,
            _ underlying: T
        ) {
            self.name = name
            self.type = type
            self.description = underlying.description
            self.accessibleDescription = underlying.accessibleDescription
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
                case .additional(_, .irrelevant):
                    break
                case let .additional(name, type):
                    if let field = type.field(for: json, name: name) {
                        fields.append(field)
                    }
                }
            case .forEach:
                break
            }
        }
        try recurse(json: json, expected: expected)
    }
}
