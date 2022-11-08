//
//  FilterMenu.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 7/9/2022.
//

import SwiftUI

struct FilterMenu: View {
    let dispatch = Global.store.writeOnly(sync: { $0 })
    let filter: Set<Status>
    
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
    
    func showAllMenu(activeStatuses: Set<Status>) -> some View {
        OptionalStoreView {
            $0.persistent.selectedServer.map {
                Set($0.api.jobs.status.keys)
            }
        } content: { allStatuses in
            Menu("Show All") {
                ForEach(Status.allCases, id: \.self) { status in
                    if allStatuses.subtracting(activeStatuses).subtracting(filter).contains(status) {
                        button(for: status, filter: filter) {
                            dispatch(sync: .update(.filter($0)))
                        }
                    }
                }
            }
        }
    }
    
    func menu(activeStatuses: Set<Status>) -> some View {
        ForEach(Status.allCases, id: \.self) { status in
            if activeStatuses.union(filter).contains(status) {
                button(for: status, filter: filter) {
                    dispatch(sync: .update(.filter($0)))
                }
            }
        }
    }
    
    var body: some View {
        Menu {
            if !filter.isEmpty {
                clearButton
            }
            StoreView(\.jobs.statuses) { statuses in
                menu(activeStatuses: statuses)
                showAllMenu(activeStatuses: statuses)
            }
        } label: {
            Label(
                "Filter",
                icon: filter.isEmpty.if(
                    true: SystemImage.filter,
                    false: .filterFilled
                )
            )
        }
    }
}
