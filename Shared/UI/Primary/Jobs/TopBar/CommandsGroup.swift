//
//  CommandGroup.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 7/9/2022.
//

import SwiftUI

struct CommandsMenu: View {
    let jobs: [JobViewModel]
    var image: SystemImage = .playpause
    var didRemove: () -> Void = {}
    
    var body: some View {
        Menu {
            CommandsGroup(jobs: jobs, didRemove: didRemove)
        } label: {
            image
        }
    }
}

struct CommandsGroup: View {
    static let statuses = Set(Status.allCases)

    let ids: [String]
    let jobs: [JobViewModel]
    var didRemove: () -> Void = {}
    
    init(jobs: [JobViewModel], didRemove: @escaping () -> Void = {}) {
        self.jobs = jobs
        self.ids = jobs.map(\.id)
        self.didRemove = didRemove
    }

    func button(
        for command: Command,
        image: SystemImage,
        invalidStatuses: Set<Status>
    ) -> some View {
        OptionalStoreView(\.persistent.selectedServer?.api) { api, dispatch in
            if api.available(command: command.discriminator),
               !jobs.allSatisfy({ invalidStatuses.contains($0.status) })
            {
                Button {
                    dispatch(async: .command(command))
                } label: {
                    Label(command.discriminator.description, icon: image)
                }
//                .disabled(
//                    jobs.allSatisfy {
//                        invalidStatuses.contains($0.status)
//                    }
//                )
            }
        }
    }
    
    var removeOrDeleteMenu: some View {
        OptionalStoreView(\.persistent.selectedServer?.api) { api, dispatch in
            if api.available(command: .remove) || api.available(command: .deleteData) {
                Menu {
                    if api.available(command: .remove) {
                        Button {
                            dispatch(async: .command(.remove(ids)))
                            didRemove()
                        } label: {
                            Label("Remove", icon: .xmark)
                        }
                    }
                    if api.available(command: .deleteData) {
                        Button(role: .destructive) {
                            dispatch(async: .command(.deleteData(ids)))
                            didRemove()
                        } label: {
                            Label("Remove and Delete Data", icon: .xmarkBin)
                        }
                    }
                } label: {
                    Button("Delete") {
                    }
                }
            }
        }
    }

    var startButton: some View {
        button(
            for: .start(ids),
            image: SystemImage.playFill,
            invalidStatuses: Self.statuses
                .subtracting([.paused, .stopped, .unknown])
        )
    }
    
    var pauseButton: some View {
        button(
            for: .pause(ids),
            image: SystemImage.pauseFill,
            invalidStatuses: [.paused, .unknown]
        )
    }
    
    var stopButton: some View {
        button(
            for: .stop(ids),
            image: SystemImage.stopFill,
            invalidStatuses: [.stopped, .unknown]
        )
    }
    
    var body: some View {
        Group {
            if ids.count > 1 {
                Text("Affecting \(ids.count) Jobs")
            }
            startButton
            pauseButton
            stopButton
            removeOrDeleteMenu
        }
    }
}
