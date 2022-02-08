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
        Text(status.description)
            .accessibility(label: Text("Server status"))
            .accessibility(value: Text(status.description))
            .accessibility(addTraits: .isHeader)
    }
}
