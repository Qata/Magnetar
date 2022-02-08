//
//  ExpectedJobsPayload.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 6/2/22.
//

import Foundation

indirect enum ExpectedPayload: Hashable, Codable {
    case object([String: Self])
    case array([Self])
    case forEach([Self])
    case name
    case status
    case id
    case uploadSpeed
    case downloadSpeed
    case uploaded
    case downloaded
    case size
    case eta
    case irrelevant
}
