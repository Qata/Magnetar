//
//  SortingMenu.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 7/9/2022.
//

import SwiftUI
import Algorithms

#warning("Fix refresh issue")
struct SortingMenu: View {
    let dispatch = Global.store.writeOnly()
    
    func sortingButton(order: Sorting.Order, sorting: Sorting) -> some View {
        Button {
            dispatch(sync: .update(.sorting(.order(order))))
        } label: {
            HStack {
                Text(order.description)
                Spacer()
                if sorting.order == order {
                    SystemImage.checkmark
                }
            }
        }
    }
    
    func sortingButton(field: Job.Field.Descriptor, sorting: Sorting) -> some View {
        Button {
            dispatch(sync: .update(.sorting(.value(field))))
        } label: {
            HStack {
                Text(field.description)
                Spacer()
                if sorting.value == field {
                    SystemImage.checkmark
                }
            }
        }
    }
    
    @ViewBuilder
    func sections(fields: [Job.Field.Descriptor], sorting: Sorting) -> some View {
        Section {
            ForEach(
                Sorting.Order.allCases,
                id: \.self
            ) {
                sortingButton(order: $0, sorting: sorting)
            }
        }
        .onChange(of: fields) { _ in
            print("Fields changed")
        }
        .onChange(of: sorting) { _ in
            print("Sorting changed")
        }
        Section {
            ForEach(
                chain(
                    Job.Field.Descriptor.PresetField
                        .allCases
                        .map(Job.Field.Descriptor.preset),
                    fields
                ),
                id: \.self
            ) {
                sortingButton(field: $0, sorting: sorting)
            }
        }
    }

    var body: some View {
        OptionalStoreView {
            $0.persistent.selectedServer?.api
                .commands[.fetch]?
                .expected?
                .adHocFields
                .map(Job.Field.Descriptor.adHoc)
        } content: { fields in
            Menu {
                OptionalStoreView(\.persistent.selectedServer?.sorting) { sorting in
                    sections(fields: fields, sorting: sorting)
                }
            } label: {
                Label("Sorting", icon: .listNumber)
            }
        }
    }
}
