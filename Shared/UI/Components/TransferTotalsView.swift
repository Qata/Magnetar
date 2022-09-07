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
    @Environment(\.layoutDirection) var direction
    
    init(jobs: [String: JobViewModel]) {
        downloadSpeed = .init(bytes: jobs.values.reduce(0, { $0 + $1.downloadSpeed.bytes }))
        uploadSpeed = .init(bytes: jobs.values.reduce(0, { $0 + $1.uploadSpeed.bytes }))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            let download = ["↓", downloadSpeed.description]
            let downloadDescription = (direction == .leftToRight).if(
                true: download,
                false: download.reversed()
            ).joined(separator: " ")
            Text(downloadDescription)
                .accessibility(label: Text("Total download speed"))
                .accessibility(value: Text(downloadSpeed.accessibleDescription))
            let upload = ["↑", uploadSpeed.description]
            let uploadDescription = (direction == .leftToRight).if(
                true: upload,
                false: upload.reversed()
            ).joined(separator: " ")
            Text(uploadDescription)
                .accessibility(label: Text("Total upload speed"))
                .accessibility(value: Text(uploadSpeed.accessibleDescription))
        }
        .font(.footnote)
    }
}
