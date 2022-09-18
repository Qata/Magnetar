//
//  Job.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 6/2/22.
//

import Foundation
import MonadicJSON
import Algorithms
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
    let additionalDictionary: [String: Job.Field]

    init(from job: Job.Raw, context: APIDescriptor) throws {
        guard let id = job.id else {
            throw Error.missing(.id)
        }
        let statusDescriptor = context.jobs.status.firstNonNil { key, value in
            value
                .contains { $0.wrappedValue == job.status }
                .if(true: key)
        } ?? .unknown
        self.name = job.name ?? ""
        self.id = id
        self.uploadSpeed = .init(
            bytes: job.uploadSpeed ?? .zero
        )
        self.downloadSpeed = .init(
            bytes: job.downloadSpeed ?? .zero
        )
        self.uploaded = .init(
            bytes: job.uploaded ?? .zero
        )
        self.downloaded = .init(
            bytes: job.downloaded ?? .zero
        )
        self.size = Size(bytes: job.size ?? .zero)
        self.status = statusDescriptor
        self.eta = .init(
            job.eta ?? -1
        )
        self.ratio = .init(
            downloaded: downloaded.bytes,
            uploaded: uploaded.bytes
        )
        self.additional = job.fields
        self.additionalDictionary = Dictionary(job.fields.map { ($0.name, $0) }, uniquingKeysWith: { $1 })
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
        case .downloading where size.bytes > 0:
            context = [
                String(format: "%.2f%% downloaded", Double(downloaded.bytes) / Double(size.bytes) * 100),
                "Estimated completion in \(eta.accessibleDescription)"
            ]
        case .downloading:
            context = [
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
