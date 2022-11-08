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
    @Environment(\.sizeCategory) var sizeCategory
    let viewModel: JobViewModel
    
    var compactStats: some View {
        VStack {
            HStack {
                Text("↓ \(viewModel.downloadSpeed.description)")
                Spacer()
                Text("\(viewModel.uploadSpeed.description) ↑")
            }
            HStack {
                HStack {
                    Text(viewModel.status.description)
                        .bold()
                    Spacer()
                }
                HStack {
                    Spacer()
                    if [.downloading, .seeding].contains(viewModel.status) {
                        Text(viewModel.eta.description)
                    }
                }
            }
        }
    }
    
    var accessibileStats: some View {
        Group {
            TransferTotalsView(
                downloadSpeed: viewModel.downloadSpeed,
                uploadSpeed: viewModel.uploadSpeed
            )
            if !sizeCategory.isAccessibilityCategory {
                Spacer()
            }
            VStack(
                alignment: sizeCategory.isAccessibilityCategory.if(
                    true: .leading,
                    false: .trailing
                )
            ) {
                let validStatus = [.downloading, .seeding].contains(viewModel.status)
                if !sizeCategory.isAccessibilityCategory || validStatus {
                    Text(viewModel.eta.description)
                        .opacity(
                            validStatus
                                .if(true: 1, false: 0)
                        )
                }
                Text(viewModel.status.description)
                    .bold()
            }
        }
        .accessibilityElement(children: .ignore)
    }

    @ViewBuilder
    var stats: some View {
        if sizeCategory.isAccessibilityCategory {
            VStack(alignment: .leading) {
                accessibileStats
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if sizeCategory > .extraLarge {
            HStack {
                accessibileStats
            }
        } else {
            compactStats
        }
    }

    var body: some View {
        #warning("Fix CommandsMenu")
        VStack {
            Text(viewModel.name)
                .font(.body.bold())
                .lineLimit(
                    sizeCategory.isAccessibilityCategory.if(
                        true: 3,
                        false: 1
                    )
                )
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

            stats
                .font(.caption)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement()
        .accessibility(label: Text(verbatim: viewModel.name))
        .accessibility(value: Text(viewModel.accessibleDescription))
        .contextMenu {
            CommandsGroup(ids: [viewModel.id])
        }
    }
}
