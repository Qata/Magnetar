//
//  FilterMenu.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 7/9/2022.
//

import SwiftUI

struct FilterMenu: View {
    let dispatch = Global.store.writeOnly(sync: { $0 })
    
    func button(
        for status: Status,
        filter: Set<Status>,
        dispatch: @escaping (SyncAction.Update.Status) -> Void
    ) -> some View {
        Button {
            let transform = filter.contains(status).if(
                true: SyncAction.Update.Status.remove,
                false: SyncAction.Update.Status.add
            )
            dispatch(transform(status))
        } label: {
            HStack {
                Text(status.description)
                Spacer()
                if filter.contains(status) {
                    SystemImage.checkmark
                }
            }
        }
    }
    
    var clearButton: some View {
        Button {
            dispatch(sync: .delete(.filter))
        } label: {
            HStack {
                Text("Clear Selection")
                Spacer()
                SystemImage.xmark
            }
        }
    }
    
    func showAllMenu<AllStatuses: Collection>(
        activeStatuses: Set<Status>,
        allStatuses: AllStatuses,
        filter: Set<Status>
    ) -> some View
    where AllStatuses.Element == Status {
        Menu("Show All") {
            ForEach(Status.allCases, id: \.self) { status in
                if !activeStatuses.contains(status), allStatuses.contains(status) {
                    button(for: status, filter: filter) {
                        dispatch(sync: .update(.filter($0)))
                    }
                }
            }
        }
    }
    
    func menu(activeStatuses: Set<Status>, filter: Set<Status>) -> some View {
        ForEach(Status.allCases, id: \.self) { status in
            if activeStatuses.contains(status) {
                button(for: status, filter: filter) {
                    dispatch(sync: .update(.filter($0)))
                }
            }
        }
    }
    
    var body: some View {
        OptionalStoreView(\.persistent.selectedServer) { server, dispatch in
            let filter = server.filter
            Menu {
                Text("Filter")
                if !filter.isEmpty {
                    clearButton
                }
                StoreView({ Set($0.jobs.values.map(\.status)) }) { statuses in
                    menu(
                        activeStatuses: statuses,
                        filter: filter
                    )
                    showAllMenu(
                        activeStatuses: statuses,
                        allStatuses: server.api.jobs.status.keys,
                        filter: filter
                    )
                }
            } label: {
                filter.isEmpty.if(
                    true: SystemImage.filter,
                    false: .filterFilled
                )
            }
        }
    }
}
