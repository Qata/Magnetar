//
//  JobRow.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

struct JobRowView: View {
    let dispatch = Global.store.writeOnly()
    @StateObject var api = Global.store.lensing(state: \.persistent.selectedServer?.api)
    
    var viewModel: JobViewModel

    var body: some View {
        VStack {
            Text(viewModel.name)
                .font(.body.bold())
                .lineLimit(1)
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
                ZStack {
                    HStack {
                        HStack {
                            Text(viewModel.status.description)
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            if [.downloading, .seeding].contains(viewModel.status) {
                                Text("ETA: \(viewModel.eta.description)")
                            }
                        }
                    }
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
                }
            }
            .font(.caption)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement()
        .accessibility(label: Text(verbatim: viewModel.name))
        .accessibility(value: Text(viewModel.accessibleDescription))
        .contextMenu {
            CommandsGroup(jobs: [viewModel])
        }
    }
}
