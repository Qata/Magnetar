//
//  Unhashed.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 31/8/2022.
//

struct Unhashed<Underlying: Hashable & Codable>: Hashable, Codable {
    var underlying: Underlying
    
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return true
    }
    
    func hash(into hasher: inout Hasher) {
    }
}
