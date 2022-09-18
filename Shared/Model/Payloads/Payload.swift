//
//  Payload.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 6/2/22.
//

enum Payload: Codable, Hashable {
    case json(Payload.JSON)
}
