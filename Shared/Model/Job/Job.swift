//
//  Job.swift
//  Magnetar (iOS)
//
//  Created by Charles Maria Tor on 9/2/22.
//

import MonadicJSON
import Foundation
import Tagged

enum Job {
    typealias Id = Tagged<Job, String>

    struct Descriptor: Codable, Hashable {
        var status: [Status: [LosslessValue<String>]]
    }

    struct Field: Codable, Hashable, AccessibleCustomStringConvertible {
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
        
        var isValid: Bool {
            switch value {
            case let .unixDate(date):
                return date.timeIntervalSince1970 > 0
            case let .string(string):
                return !string.isEmpty
            case .speed, .seconds, .bool, .size, .int, .float:
                return true
            }
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
        var fields: [Job.Field.Descriptor.PresetField: Field] = [:]
        var adHocFields: [Field] = []
    }
}

extension Job.Field {
    enum Descriptor: Codable, Hashable, CustomStringConvertible {
        enum FieldType: Codable, Hashable {
            case unixDate
            case speed
            case size
            case seconds
            case string
            case int
            case float
            case bool
            // Useful for APIs that return arrays.
            case irrelevant

            func string(from response: StructuredResponse) -> String? {
                switch response {
                case let .string(value):
                    return value
                case let .bool(value):
                    return value.description
                case let .number(value):
                    return value.description
                case .null:
                    return "null"
                default:
                    return nil
                }
            }

            func jobField(for response: StructuredResponse, name: String) -> Job.Field? {
                Optional(()).flatMap {
                    switch self {
                    case .int:
                        return response.int
                            .map { .int($0) }
                    case .float:
                        return response.double
                            .map { .float($0) }
                    case .unixDate:
                        return response.date
                            .map { .unixDate($0) }
                    case .speed:
                        return response.uint
                            .map { .speed(.init(bytes: $0)) }
                    case .size:
                        return response.uint
                            .map { .size(.init(bytes: $0)) }
                    case .seconds:
                        return response.double
                            .map { number in
                                (number < 0).if(
                                    true: ETA.infinite,
                                    false: ETA.finite(seconds: UInt(number))
                                )
                            }
                            .map { .seconds($0) }
                    case .string:
                        return string(from: response)
                            .map { .string($0) }
                    case .bool:
                        return response.bool
                            .map { .bool($0) }
                    case .irrelevant:
                        return nil
                    }
                }
                .map { .init(name: name, value: $0) }
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
                case .uploaded, .downloaded:
                    return "\(rawValue.capitalized) Bytes"
                case .eta, .id:
                    return rawValue.uppercased()
                default:
                    return rawValue
                        .unCamelCased
                        .joined(separator: " ")
                        .capitalized
                }
            }

            var type: FieldType {
                switch self {
                case .name:
                    return .string
                case .status:
                    return .string
                case .id:
                    return .string
                case .uploadSpeed:
                    return .speed
                case .downloadSpeed:
                    return .speed
                case .uploaded:
                    return .size
                case .downloaded:
                    return .size
                case .size:
                    return .size
                case .eta:
                    return .seconds
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
        case int(Int)
        case float(Double)
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
            case let (.int(lhs), .int(rhs)):
                return lhs < rhs
            case let (.float(lhs), .float(rhs)):
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
            case .unixDate:
                return accessibleDescription
            case let .int(number):
                return number.description
            case let .float(number):
                return number.description
            case let .speed(speed):
                return speed.description
            case let .size(size):
                return size.description
            case let .seconds(eta):
                return eta.description
            case let .string(string):
                return string
            case .bool:
                return accessibleDescription
            }
        }

        var accessibleDescription: String {
            switch self {
            case let .unixDate(date):
                return date.accessibleDescription
            case let .int(number):
                return number.description
            case let .float(number):
                return number.description
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
}

extension Job.Raw: StructuredResponseInitialisable {
    init(
        from response: StructuredResponse,
        against expected: Payload.StructuredResponse,
        context: APIDescriptor
    ) throws {
        func recurseDictionary(response: [String: StructuredResponse], expected: [String: Payload.StructuredResponse]) throws {
            try expected
                .map { key, value -> (StructuredResponse, Payload.StructuredResponse) in
                    guard let response = response[key] else {
                        throw ResponseParseError(response: .dictionary(response), expected: .dictionary(expected))
                    }
                    return (response, value)
                }
                .forEach(recurse)
        }

        func recurse(response: StructuredResponse, expected: Payload.StructuredResponse) throws {
            switch expected {
            case let .parameter(parameter):
                switch parameter {
                case let .field(field):
                    switch field {
                    case let .preset(field):
                        if let jobField = field.type.jobField(for: response, name: field.description) {
                            fields[field] = jobField
                        }
                        switch field {
                        case .name:
                            _name = try .init(from: response)
                        case .status:
                            _status = try .init(from: response)
                        case .id:
                            _id = try .init(from: response)
                        case .uploadSpeed:
                            _uploadSpeed = try .init(from: response)
                        case .downloadSpeed:
                            _downloadSpeed = try .init(from: response)
                        case .uploaded:
                            _uploaded = try .init(from: response)
                        case .downloaded:
                            _downloaded = try .init(from: response)
                        case .size:
                            _size = try .init(from: response)
                        case .eta:
                            _eta = try .init(from: response)
                        }
                    case let .adHoc(field) where field.type == .irrelevant:
                        break
                    case let .adHoc(field):
                        if let jobField = field.type.jobField(for: response, name: field.name) {
                            adHocFields.append(jobField)
                        }
                    }
                case .token:
                    break
                case .destination:
                    break
                }
            case let .dictionary(expectedDictionary):
                switch response {
                case let .dictionary(response):
                    try recurseDictionary(response: response, expected: expectedDictionary)
                default:
                    throw ResponseParseError(response: response, expected: expected)
                }
            case let .string(expectedString):
                switch response {
                case .string(expectedString):
                    break
                default:
                    throw ResponseParseError(response: response, expected: expected)
                }
            case let .bool(expectedBool):
                switch response {
                case .bool(expectedBool):
                    break
                default:
                    throw ResponseParseError(response: response, expected: expected)
                }
            case let .array(expectedArray), let .forEach(expectedArray):
                switch response {
                case let .array(response):
                    try zip(response, expectedArray).forEach(recurse)
                default:
                    throw ResponseParseError(response: response, expected: expected)
                }
            case let .int(expectedInt):
                switch response {
                case .number(.int(expectedInt)):
                    break
                default:
                    throw ResponseParseError(response: response, expected: expected)
                }
            case .date:
                break
            case .data:
                break
            }
        }
        try recurse(response: response, expected: expected)
    }
}
