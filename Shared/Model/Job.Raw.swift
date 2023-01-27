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
    let id: Job.Id
    let uploadSpeed: Speed
    let downloadSpeed: Speed
    let uploaded: Size
    let downloaded: Size
    let size: Size
    let eta: ETA
    let ratio: Ratio

    let fields: [Job.Field.Descriptor.PresetField: Job.Field]
    let additional: [Job.Field]
    let additionalDictionary: [String: Job.Field]

    init(from job: Job.Raw, context: APIDescriptor) throws {
        guard let id = job.id else {
            throw Error.missing(.id)
        }
        let statusDescriptor = context.jobs.status.firstKey {
            $0.contains { $0.wrappedValue == job.status }
        } ?? .unknown
        self.name = job.name ?? ""
        self.id = .init(rawValue: id)
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
        self.fields = job.fields
        self.additional = job.adHocFields
        self.additionalDictionary = Dictionary(
            job.adHocFields.map { ($0.name, $0) },
            uniquingKeysWith: { $1 }
        )
    }

    var statusColor: Color {
        switch status {
        case .downloading:
            return .blue
        case .seeding:
            return .green
        case .stopped,
                .queued,
                .paused,
                .checkingFiles,
                .fileCheckQueued:
            return .gray
        case .unknown:
            return .red
        }
    }

    subscript(_ field: Job.Field.Descriptor.PresetField) -> Job.Field? {
        fields[field]
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
        case .queued, .stopped, .paused, .checkingFiles, .fileCheckQueued, .unknown:
            context = [
                "Upload ratio of \(ratio.accessibleDescription)"
            ]
        }
        return ([status.description] + context)
            .joined(separator: "\n")
    }
}
