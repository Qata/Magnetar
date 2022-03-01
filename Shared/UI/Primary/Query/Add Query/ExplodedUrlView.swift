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
    @State var selectedComponent: SelectedComponent?

    let dispatch = Global.store.writeOnly()
    let query: Query
    
    enum SelectedComponent: Hashable {
        case path(offset: Int)
        case query(offset: Int)
        
        var offset: Int {
            switch self {
            case let .path(offset):
                return offset
            case let .query(offset):
                return offset
            }
        }
    }

    init?(url: URL, showModal: Binding<Bool>) {
        guard let query = Query(url: url) else {
            return nil
        }
        self.query = query
        _showModal = showModal
    }
    
    @ViewBuilder var pathView: some View {
        if !query.path.isEmpty {
            Section("Path") {
                Picker(selection: $selectedComponent) {
                    ForEach(0..<query.path.count) { offset in
                        if let component = query.path[index: offset] {
                            Text(component.description)
                                .tag(Optional(SelectedComponent.path(offset: offset)))
                        }
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.inline)
            }
        }
    }

    @ViewBuilder var queryView: some View {
        if !query.queryItems.isEmpty {
            Section("Query Items") {
                Picker(selection: $selectedComponent) {
                    ForEach(0..<query.queryItems.count) { offset in
                        if let component = query.queryItems[index: offset] {
                            Text(component.description)
                                .tag(Optional(SelectedComponent.query(offset: offset)))
                        }
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
                    .init(
                        name: queryName,
                        base: query.base,
                        path: query.path.enumerated().map { offset, element in
                            if case .path(offset) = selectedComponent {
                                return .query
                            } else {
                                return element
                            }
                        },
                        queryItems: query.queryItems.enumerated().map { offset, element in
                            if case .query(offset) = selectedComponent {
                                return .init(
                                    name: element.name,
                                    value: .query
                                )
                            } else {
                                return element
                            }
                        }
                    )
                )
            )
        )
    }

    var body: some View {
        List {
            Picker(selection: $selectedComponent) {
                Text("No query parameter")
                    .tag(Optional<SelectedComponent>.none)
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
            pathView
            queryView
            Section {
                TextField("Query name", text: $queryName)
                Button("Save") {
                    save()
                    showModal = false
                }
                .disabled(queryName.isEmpty)
            }
        }
        .navigationBarTitle(Text("Please select the query"))
        .interactiveDismissDisabled()
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Cancel", role: .destructive) {
                    showModal = false
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
