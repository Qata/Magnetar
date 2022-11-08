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
    @State var selectedParameter: WebQuery.Parameter?
    @FocusState var nameFocused: Bool

    let dispatch = Global.store.writeOnly()
    let query: WebQuery

    init?(url: URL, showModal: Binding<Bool>) {
        guard let query = WebQuery(url: url) else {
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
                            .tag(Optional(WebQuery.Parameter(location: .path, index: component.offset)))
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
                                    WebQuery.Parameter(
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
    
    func onLoad() {
        nameFocused = true
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
                TextField("Query name", text: $queryName)
                    .disableAutocorrection(true)
                    .focused($nameFocused)
            }
            Picker(selection: $selectedParameter) {
                Text("None")
                    .tag(Optional(WebQuery.Parameter.none))
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
            pathView
            queryView
            Section {
                StoreView(\.persistent.queries) { queries in
                    let nameInUse = queries.contains { $0.name.rawValue == queryName }
                    Button("Save") {
                        if queryName.isEmpty {
                            nameFocused = true
                        } else {
                            save()
                            queryName.removeAll()
                            showModal = false
                        }
                    }
                    .disabled(selectedParameter == nil)
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
        .onLoad(perform: onLoad)
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
