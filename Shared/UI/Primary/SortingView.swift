//
//  SortingView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 8/2/22.
//

import SwiftUI

struct SortingView: View {
    let store = Global.store.lensing(state: \.selectedServer?.sorting)

    var body: some View {
        OptionalStoreView(store) { sorting, dispatch in
            Form {
                Picker("Order", selection: store.binding(
                    get: \.!.order,
                    send: { .update(.sorting(.order($0))) }
                )) {
                    ForEach(Sorting.Order.allCases, id: \.self) { order in
                        Text(order.description)
                            .tag(order)
                    }
                }
                .pickerStyle(.inline)
                Section("Value") {
                    NavigationLink {
                        SortingValueView()
                    } label: {
                        Text(sorting.value.description)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .navigationTitle("Transfer Sorting")
        }
    }
}

struct SortingValueView: View {
    @Environment(\.dismiss) private var dismiss
    let store = Global.store.lensing(state: \.selectedServer?.sorting)

    var body: some View {
        OptionalStoreView(store) { sorting, dispatch in
            List {
                Picker("Status", selection: store.binding(
                    get: {
                        switch $0!.value {
                        case let .status(status):
                            return status
                        case .presetField, .adHocField:
                            return nil
                        }
                    },
                    send: { .update(.sorting(.value(.status($0!)))) }
                )) {
                    ForEach(Status.allCases, id: \.self) { status in
                        Text(status.description)
                            .tag(Optional(status))
                    }
                }
                .pickerStyle(.inline)
                
                Picker("Preset Field", selection: store.binding(
                    get: {
                        switch $0!.value {
                        case let .presetField(field):
                            return field
                        case .status, .adHocField:
                            return nil
                        }
                    },
                    send: { .update(.sorting(.value(.presetField($0!)))) }
                )) {
                    ForEach(Job.Field.Descriptor.PresetField.allCases, id: \.self) { field in
                        Text(field.description)
                            .tag(Optional(field))
                    }
                }
                .pickerStyle(.inline)
                
                OptionalStoreView.init {
                    $0.selectedServer?.api.commands[.fetch]?.expected.adHocFields
                } content: { fields, _ in
                    Picker("Ad Hoc Field", selection: store.binding(
                        get: {
                            switch $0!.value {
                            case let .adHocField(field):
                                return field
                            case .status, .presetField:
                                return nil
                            }
                        },
                        send: { .update(.sorting(.value(.adHocField($0!)))) }
                    )) {
                        ForEach(fields, id: \.self) { field in
                            Text(field.description)
                                .tag(Optional(field))
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .listStyle(.grouped)
            .onChange(of: sorting.value) { _ in
                dismiss()
            }
        }
    }
}

struct SortingView_Previews: PreviewProvider {
    static var previews: some View {
        SortingView()
    }
}
