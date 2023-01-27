//
//  CommandGroup.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 7/9/2022.
//

import SwiftUI

struct CommandsMenu: View {
    var ids: [Job.Id]
    var image: SystemImage
    var onRemove: () -> Void

    init<Identifiers: Sequence>(
        ids: Identifiers,
        image: SystemImage = .playpause,
        onRemove: @escaping () -> Void = {}
    ) where Identifiers.Element == Job.Id {
        self.ids = .init(ids)
        self.image = image
        self.onRemove = onRemove
    }

    var body: some View {
        Menu {
            CommandsGroup(
                ids: ids,
                onRemove: onRemove
            )
        } label: {
            Label("Commands", icon: image)
        }
    }
}

struct CommandsGroup: View {
    static let statuses = Set(Status.allCases)

    var ids: [Job.Id]
    var onRemove: () -> Void

    init<Identifiers: Sequence>(
        ids: Identifiers,
        image: SystemImage = .playpause,
        onRemove: @escaping () -> Void = {}
    ) where Identifiers.Element == Job.Id {
        self.ids = .init(ids)
        self.onRemove = onRemove
    }

    func button(
        for command: Command,
        image: SystemImage,
        invalidStatuses: Set<Status>
    ) -> some View {
        OptionalStoreView(\.persistent.selectedServer?.api) { api, dispatch in
            StoreView(\.jobs.pairedStatuses) { statuses in
                if api.available(command: command.discriminator),
                   !ids.allSatisfy({ statuses[$0].map(invalidStatuses.contains) ?? false })
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
    }
    
    var removeOrDeleteMenu: some View {
        OptionalStoreView(\.persistent.selectedServer?.api) { api, dispatch in
            if api.available(command: .remove) || api.available(command: .deleteData) {
                Menu {
                    if api.available(command: .remove) {
                        Button {
                            dispatch(async: .command(.remove(ids)))
                            onRemove()
                        } label: {
                            Label("Remove", icon: .xmark)
                        }
                    }
                    if api.available(command: .deleteData) {
                        Button(role: .destructive) {
                            dispatch(async: .command(.deleteData(ids)))
                            onRemove()
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
                .subtracting([.paused, .stopped])
        )
    }

    var pauseButton: some View {
        button(
            for: .pause(ids),
            image: SystemImage.pauseFill,
            invalidStatuses: [.paused]
        )
    }

    var stopButton: some View {
        button(
            for: .stop(ids),
            image: SystemImage.stopFill,
            invalidStatuses: [.stopped]
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
