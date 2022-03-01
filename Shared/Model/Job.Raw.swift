//
//  Job.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 6/2/22.
//

import Foundation
import MonadicJSON
import SwiftUI

struct ETADescriptor: Codable, Hashable {
    let infinity: [Int]
}

struct JobViewModel: Codable, Hashable, AccessibleCustomStringConvertible {
    enum Error: Swift.Error {
        case missing(Job.Field.Descriptor.PresetField)
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
    let additional: [Job.Field]
    
    init(from job: Job.Raw, context: APIDescriptor) throws {
        guard let name = job.name else {
            throw Error.missing(.name)
        }
        let statusDescriptor = context.jobs.status.firstNonNil { key, value in
            value
                .contains { $0.wrappedValue == job.status }
                .if(true: key)
        } ?? .unknown
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
        self.status = statusDescriptor
        self.eta = .init(eta)
        self.ratio = .init(downloaded: downloaded, uploaded: uploaded)
        self.additional = job.fields
    }
    
    var statusColor: Color {
        switch status {
        case .downloading:
            return .blue
        case .seeding:
            return .green
        case .stopped, .seedQueued, .downloadQueued, .paused, .checkingFiles, .fileCheckQueued:
            return .gray
        case .unknown:
            return .red
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
        case .downloadQueued, .seedQueued, .stopped, .paused, .checkingFiles, .fileCheckQueued, .unknown:
            context = [
                "Upload ratio of \(ratio.accessibleDescription)"
            ]
        }
        return ([status.description] + context)
            .joined(separator: "\n")
    }
}
