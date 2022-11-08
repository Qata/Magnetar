//
//  ErrorModel.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 12/9/2022.
//

import Foundation
import SwiftUI

struct ErrorModel: Hashable, Codable, Equatable, Identifiable {
    struct Error: Hashable, Codable {
        let title: String
        let description: AttributedString?
    }

    var id = UUID()
    let date: Date
    let error: Error
}
