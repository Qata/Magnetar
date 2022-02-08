//
//  Job.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 6/2/22.
//

import Foundation
import MonadicJSON
import SwiftUI

typealias Jobs = [Job]

struct ETADescriptor: Codable, Hashable {
    let infinity: [Int]
}

struct JobDescriptor: Codable, Hashable {
    var status: [Status: LosslessValue<String>]
    var eta: ETADescriptor
}

struct JobViewModel: Hashable, Codable, AccessibleCustomStringConvertible {
    enum Error: Swift.Error {
        case missing(ExpectedPayload)
    }
    
    let name: String
    let status: Status
    let id: String
    let uploadSpeed: Speed
    let downloadSpeed: Speed
    let uploaded: Size
    let downloaded: Size
    let size: Size
    let eta: ETA
    let ratio: Ratio
    
    init(from job: Job, context: APIDescriptor) throws {
        guard let name = job.name else {
            throw Error.missing(.name)
        }
        let statusDescriptor = context.jobs.status.firstNonNil { key, value in
            (job.status == value.wrappedValue).if(
                true: key,
                false: nil
            )
        }
        guard let status = statusDescriptor else {
            throw Error.missing(.status)
        }
        guard let id = job.id else {
            throw Error.missing(.id)
        }
        guard let uploadSpeed = job.uploadSpeed else {
            throw Error.missing(.uploadSpeed)
        }
        guard let downloadSpeed = job.downloadSpeed else {
            throw Error.missing(.downloadSpeed)
        }
        guard let uploaded = job.uploaded else {
            throw Error.missing(.uploaded)
        }
        guard let downloaded = job.downloaded else {
            throw Error.missing(.downloaded)
        }
        guard let size = job.size else {
            throw Error.missing(.size)
        }
        guard let eta = job.eta else {
            throw Error.missing(.eta)
        }
        self.name = name
        self.id = id
        self.uploadSpeed = .init(bytes: uploadSpeed)
        self.downloadSpeed = .init(bytes: downloadSpeed)
        self.uploaded = .init(bytes: uploaded)
        self.downloaded = .init(bytes: downloaded)
        self.size = Size(bytes: size)
        self.status = status
        self.eta = .init(eta, context: context.jobs.eta)
        self.ratio = .init(downloaded: downloaded, uploaded: uploaded)
    }
    
    var statusColor: Color {
        switch status {
        case .downloading:
            return .blue
        case .seeding:
            return .green
        case .stopped, .seedQueued, .downloadQueued, .paused, .checkingFiles, .fileCheckQueued:
            return .gray
        }
    }
    
    var description: String {
        accessibleDescription
    }
    
    var accessibleDescription: String {
        let context: [String]
        switch status {
        case .downloading:
            context = [
                "\(Double(downloaded.bytes) / Double(size.bytes) * 100)% downloaded",
                "Estimated completion in \(eta.accessibleDescription)"
            ]
        case .seeding:
            context = [
                "Upload ratio of \(ratio.accessibleDescription)",
                "\(uploaded.accessibleDescription) uploaded"
                ]
        case .downloadQueued, .seedQueued, .stopped, .paused, .checkingFiles, .fileCheckQueued:
            context = [
                "Upload ratio of \(ratio.accessibleDescription)"
            ]
        }
        return ([status.description] + context)
            .joined(separator: "\n")
    }
}

struct _JobDescriptor: Codable, Hashable {
    enum Field: Codable, Hashable {
        case unixDate
        case speed
        case size
        case seconds
        case string
    }

    let fields: [String: Field]
}

struct Job: Codable, Hashable {
    @LosslessValue var name: String?
    @LosslessValue var status: String?
    @LosslessValue var id: String?
    @LosslessValue var uploadSpeed: UInt?
    @LosslessValue var downloadSpeed: UInt?
    @LosslessValue var uploaded: UInt?
    @LosslessValue var downloaded: UInt?
    @LosslessValue var size: UInt?
    @LosslessValue var eta: Int?
}

extension Job: JSONInitialisable {
    init(from json: JSON, against expected: ExpectedPayload, context: APIDescriptor) throws {
        func recurse(json: JSON, expected: ExpectedPayload) throws {
            switch expected {
            case let .object(expected):
                switch json {
                case let .object(json):
                    try zip(json.sorted(keyPath: \.key).map(\.value), expected.sorted(keyPath: \.key).map(\.value))
                        .forEach { json, expected in
                            try recurse(json: json, expected: expected)
                        }
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
            case .irrelevant, .forEach:
                break
            }
        }
        try recurse(json: json, expected: expected)
    }
}
