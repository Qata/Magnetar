//
//  StringProtocol.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 18/2/22.
//

import Foundation

extension StringProtocol {
    var unCamelCased: [SubSequence] {
        chunked(by: { $1.isUppercase.not })
    }
}
