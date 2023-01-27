//
//  Measurements.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

enum DataSizeClass: String, Codable, CaseIterable {
    case bytes
    case kibibytes
    case mebibytes
    case gibibytes
    case tebibytes
    case pebibytes
    case exbibytes
    case zebibytes
    case yobibytes

    static let all: [UInt: Self] = Dictionary(
        uniqueKeysWithValues: allCases.map {
            ($0.standing, $0)
        }
    )

    var name: String {
        rawValue
    }

    var prefix: Character? {
        switch self {
        case .bytes:
            return nil
        default:
            return rawValue.capitalized.first
        }
    }

    var abbreviation: String {
        [prefix.map { "\($0)i" }, "B"]
            .compactMap { $0 }
            .joined()
    }

    var standing: UInt {
        switch self {
        case .bytes:
            return 0
        case .kibibytes:
            return 1
        case .mebibytes:
            return 2
        case .gibibytes:
            return 3
        case .tebibytes:
            return 4
        case .pebibytes:
            return 5
        case .exbibytes:
            return 6
        case .zebibytes:
            return 7
        case .yobibytes:
            return 8
        }
    }
}

struct Speed: Codable, Hashable, AccessibleCustomStringConvertible {
    private let size: Size

    static var zero: Self {
        .init(bytes: .zero)
    }

    init(bytes: UInt) {
        size = .init(bytes: bytes)
        description = size.description + "/s"
        accessibleDescription = [
            size.accessibleDescription,
            "per",
            "second"
        ].joined(separator: " ")
    }

    var bytes: UInt {
        size.bytes
    }

    var sizeClass: DataSizeClass {
        size.sizeClass
    }

    var rawDescription: String {
        size.rawDescription
    }

    let description: String
    let accessibleDescription: String
}

struct Size: Codable, Hashable, AccessibleCustomStringConvertible {
    static let numberFormatter: Atomic<NumberFormatter> = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return .init(formatter)
    }()
    let bytes: UInt
    let sizeClass: DataSizeClass

    init(bytes: UInt) {
        self.bytes = bytes
        let logged = Optional(Double(bytes))
            .map(abs)
            .map(log2)
            .filter(\.isFinite)
            .map { UInt(floor($0)) / 10 }
        ?? 0

        sizeClass = DataSizeClass.all[logged, default: .bytes]
    }

    var rawDescription: String {
        "\(Double(bytes) / pow(2, Double(sizeClass.standing * 10)), formatter: Self.numberFormatter)"
    }

    var description: String {
        [rawDescription, sizeClass.abbreviation]
            .joined(separator: " ")
    }

    var accessibleDescription: String {
        [rawDescription, sizeClass.name]
            .joined(separator: " ")
    }
}

extension Speed: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.bytes < rhs.bytes
    }
}

extension Size: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.bytes < rhs.bytes
    }
}
