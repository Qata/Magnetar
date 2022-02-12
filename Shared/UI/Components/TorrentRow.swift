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
    @StateObject var api = Global.store.lensing(state: \.selectedServer?.api)
    
    var viewModel: JobViewModel
    
    @ViewBuilder
    func menuItem(disabledIf invalidStatuses: [Status] = [], command: @escaping ([String]) -> Command) -> some View {
        if let api = api.state {
            CommandButton(
                title: true,
                command: command,
                viewModel: viewModel,
                invalidStatuses: invalidStatuses,
                api: api
            ) { title, image, action in
                Button(action: action) {
                    Label {
                        title
                    } icon: {
                        image
                    }
                }
            }
        }
    }

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
            menuItem(disabledIf: [.downloading, .seeding], command: Command.start)
            menuItem(disabledIf: [.downloading, .seeding], command: Command.startNow)
            menuItem(disabledIf: [.paused, .stopped], command: Command.pause)
            menuItem(disabledIf: [.paused, .stopped], command: Command.stop)
            menuItem(command: Command.remove)
            menuItem(command: Command.deleteData)
        }
    }
}
