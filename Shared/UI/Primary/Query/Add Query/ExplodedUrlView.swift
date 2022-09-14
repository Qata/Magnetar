//
//  ExplodedUrlView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 21/2/22.
//

import SwiftUI

struct ExplodedUrlView: View {
    @Binding var showModal: Bool
    @Environment(\.dismiss) var dismiss
    @State var queryName = ""
    @State var selectedParameter: Query.Parameter?
    @FocusState var nameFocused: Bool

    let dispatch = Global.store.writeOnly()
    let query: Query

    init?(url: URL, showModal: Binding<Bool>) {
        guard let query = Query(url: url) else {
            return nil
        }
        self.query = query
        _showModal = showModal
    }

    @ViewBuilder var pathView: some View {
        let components = query.path.components
        if !components.isEmpty {
            Section("Path") {
                Picker(selection: $selectedParameter) {
                    ForEach(components, id: \.self) { component in
                        Text(component.element.description)
                            .tag(Optional(Query.Parameter(location: .path, index: component.offset)))
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.inline)
            }
        }
    }

    @ViewBuilder var queryView: some View {
        let components = query.queryItems.components
        if !components.isEmpty {
            Section("Query Items") {
                Picker(selection: $selectedParameter) {
                    ForEach(components, id: \.offset) { component in
                        Text(component.element.description)
                            .tag(
                                Optional(
                                    Query.Parameter(
                                        location: .queryItem,
                                        index: component.offset
                                    )
                                )
                            )
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.inline)
            }
        }
    }
    
    func save() {
        dispatch(
            sync: .create(
                .query(
                    query.updated(
                        name: queryName,
                        parameter: selectedParameter
                    )
                )
            )
        )
    }

    var body: some View {
        List {
            Section("Example") {
                Text(
                    query
                        .updated(name: "", parameter: selectedParameter)
                        .url(for: "example search")?
                        .absoluteString
                    ?? ""
                )
            }
            Picker(selection: $selectedParameter) {
                Text("None")
                    .tag(Optional(Query.Parameter.none))
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
            pathView
            queryView
            Section {
                TextField("Query name", text: $queryName)
                    .disableAutocorrection(true)
                    .focused($nameFocused)
                StoreView(\.persistent.queries) { queries in
                    let nameInUse = queries.contains { $0.name == queryName }
                    Button("Save") {
                        save()
                        queryName.removeAll()
                        showModal = false
                    }
                    .disabled(selectedParameter == nil)
                    .disabled(queryName.isEmpty)
                    .disabled(nameInUse)

                    if nameInUse {
                        Text("Name must be unique")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationBarTitle(Text("Add New Query"))
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Cancel", role: .destructive) {
                    showModal = false
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Dismiss") {
                    nameFocused = false
                }
            }
        }
    }
}

struct ExplodedUrlView_Previews: PreviewProvider {
    static var previews: some View {
        ExplodedUrlView(
            url: URL(string: "https://google.com/path/to/resource?query=valu%20e&goodbye=he+llo")!,
            showModal: .constant(false)
        )
    }
}
