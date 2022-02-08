//
//  JSONPayload.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 6/2/22.
//

import Foundation

indirect enum JSONPayload: Hashable, Codable {
    indirect enum Either: Hashable & Codable {
        case json(Self)
        case payload(ExpectedPayload)
    }
    case object([String: Either])
    case array([Either])
}
