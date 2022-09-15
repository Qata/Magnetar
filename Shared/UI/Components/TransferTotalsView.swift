import Foundation
import SwiftUI

struct TransferTotalsView: View {
    let downloadSpeed: Speed
    let uploadSpeed: Speed
    @Environment(\.layoutDirection) var direction

    init(job: JobViewModel) {
        downloadSpeed = job.downloadSpeed
        uploadSpeed = job.uploadSpeed
    }
    
    init(jobs: [JobViewModel]) {
        downloadSpeed = .init(bytes: jobs.reduce(0, { $0 + $1.downloadSpeed.bytes }))
        uploadSpeed = .init(bytes: jobs.reduce(0, { $0 + $1.uploadSpeed.bytes }))
    }

    var body: some View {
        VStack(alignment: .leading) {
            let upload = ["↑", uploadSpeed.description]
            let uploadDescription = (direction == .leftToRight).if(
                true: upload,
                false: upload.reversed()
            ).joined(separator: " ")
            Text(uploadDescription)
                .accessibility(label: Text("Total upload speed"))
                .accessibility(value: Text(uploadSpeed.accessibleDescription))
            let download = ["↓", downloadSpeed.description]
            let downloadDescription = (direction == .leftToRight).if(
                true: download,
                false: download.reversed()
            ).joined(separator: " ")
            Text(downloadDescription)
                .accessibility(label: Text("Total download speed"))
                .accessibility(value: Text(downloadSpeed.accessibleDescription))
        }
        .accessibilityElement(children: .combine)
    }
}
