//
//  ServerStatusHeader.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import SwiftUI

struct ServerStatusHeader: View {
    var status: ServerStatus
    
    var body: some View {
        ZStack {
            color.frame(width: UIScreen.main.bounds.size.width)
            Text(status.description)
                .foregroundColor(.white)
        }
        .accessibility(label: Text("Server status"))
        .accessibility(value: Text(status.description))
        .accessibility(addTraits: .isHeader)
    }

    var color: Color {
        switch status {
        case .attemptingConnection:
            return .green
        case .offline:
            return .red
        case .online:
            return .blue
        }
    }
}
