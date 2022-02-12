//
//  TransferTotals.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import SwiftUI

struct TransferTotals: View {
    let downloadSpeed: Speed
    let uploadSpeed: Speed
    
    init(jobs: [String: JobViewModel]) {
        downloadSpeed = .init(bytes: jobs.values.reduce(0, { $0 + $1.downloadSpeed.bytes }))
        uploadSpeed = .init(bytes: jobs.values.reduce(0, { $0 + $1.uploadSpeed.bytes }))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("↑ \(uploadSpeed.description)")
                .accessibility(label: Text("Total upload speed"))
                .accessibility(value: Text(uploadSpeed.accessibleDescription))
            Text("↓ \(downloadSpeed.description)")
                .accessibility(label: Text("Total download speed"))
                .accessibility(value: Text(downloadSpeed.accessibleDescription))
        }
        .font(.footnote)
    }
}
