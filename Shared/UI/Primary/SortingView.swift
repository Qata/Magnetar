//
//  SortingView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 8/2/22.
//

import SwiftUI
import Algorithms

struct SortingView: View {
    var body: some View {
        Form {
            OrderView()
            FieldView()
        }
        .navigationTitle("Transfer Sorting")
    }
}

extension SortingView {
    struct OrderView: View {
        let store = Global.store.lensing(state: \.persistent.selectedServer?.sorting)

        var body: some View {
            OptionalStoreView(store) { sorting, dispatch in
                Picker(
                    "Field Order",
                    selection: store.binding(
                        get: \.!.order,
                        send: { .update(.sorting(.order($0))) }
                    )
                ) {
                    ForEach(Sorting.Order.allCases, id: \.self) { order in
                        Text(order.description)
                            .tag(order)
                    }
                }
                .pickerStyle(.inline)
            }
        }
    }
}

extension SortingView {
    struct FieldView: View {
        @StateObject var store = Global.store.lensing(state: \.persistent.selectedServer?.sorting)

        var body: some View {
            OptionalStoreView {
                $0.persistent.selectedServer?
                    .api
                    .commands[.fetch]?
                    .expected?
                    .adHocFields
                    .map(Job.Field.Descriptor.adHoc)
            } content: { fields, _ in
                Picker("Field", selection: store.binding(
                    get: \.!.value,
                    send: { .update(.sorting(.value($0))) }
                )) {
                    ForEach(
                        chain(
                            Job.Field.Descriptor.PresetField
                                .allCases
                                .map(Job.Field.Descriptor.preset),
                            fields
                        ),
                        id: \.self
                    ) { field in
                        Text(field.description)
                            .tag(Optional(field))
                    }
                }
            }
        }
    }
}

struct SortingView_Previews: PreviewProvider {
    static var previews: some View {
        SortingView()
    }
}
