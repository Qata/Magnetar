//
//  FilterMenu.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 7/9/2022.
//

import SwiftUI

struct FilterMenu: View {
    var body: some View {
        OptionalStoreView(\.persistent.selectedServer?.filter) { filter, dispatch in
            Menu {
                Text("Filter")
                if !filter.isEmpty {
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
                ForEach(Status.allCases, id: \.self) { status in
                    Button {
                        let transform = filter.contains(status).if(
                            true: SyncAction.Update.Status.remove,
                            false: SyncAction.Update.Status.add
                        )
                        dispatch(sync: .update(.filter(transform(status))))
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
            } label: {
                filter.isEmpty.if(
                    true: SystemImage.filter,
                    false: .filterFilled
                )
            }
        }
    }
}
