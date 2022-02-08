//
//  TorrentRow.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

struct TorrentRow: View {
    var viewModel: JobViewModel

    var body: some View {
        VStack {
            Text(viewModel.name)
                .font(.headline)
                .accessibility(label: Text("Name"))
                .padding(.bottom, -2)
            ProgressBar(
                current: viewModel.downloaded.bytes,
                max: max(
                    viewModel.downloaded.bytes,
                    viewModel.size.bytes
                )
            )
            .foregroundColor(viewModel.statusColor)
            VStack(spacing: 8) {
                HStack {
                    HStack {
                        Spacer()
                        Text("\(viewModel.downloadSpeed.description) ↓")
                    }
                    HStack {
                        Text("↑ \(viewModel.uploadSpeed.description)")
                        Spacer()
                    }
                }
                HStack {
                    HStack {
                        Text(viewModel.status.description)
                        Spacer()
                    }
                    Text("Ratio: \(viewModel.ratio.description)")
                    HStack {
                        Spacer()
                        if [.downloading, .seeding].contains(viewModel.status) {
                            Text("ETA: \(viewModel.eta.description)")
                        }
                    }
                }
            }
            .font(.caption)
        }
        .accessibilityElement()
        .accessibility(label: Text(verbatim: viewModel.name))
        .accessibility(value: Text(viewModel.accessibleDescription))
    }
}
