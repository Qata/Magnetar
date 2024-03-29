//
//  MainQueryView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

import SwiftUI
import Combine
import Algorithms
import SwiftUINavigation

struct MainQueryView: View {
    let dispatch = Global.store.writeOnly(sync: { $0 })
    @State var showAddQuery = false
    @State var query: WebQuery?
    @State var url: URL??
    @State var searchString = ""
    
    func delete(query named: WebQuery.Name) {
        dispatch(sync: .delete(.query(name: named)))
    }
    
    func deleteButton(name: WebQuery.Name) -> some View {
        Button(role: .destructive) {
            delete(query: name)
        } label: {
            Label("Delete", icon: .xmark)
        }
    }

    var queries: some View {
        StoreView(\.persistent.queries) { queries, dispatch in
            Section("Queries") {
                ForEach(queries, id: \.self) { query in
                    Button {
                        if query.parameter == .some(.none) {
                            url = query.url(for: "")
                        } else {
                            self.query = query
                        }
                    } label: {
                        Text(query.name.rawValue)
                    }
                    .contextMenu {
                        deleteButton(name: query.name)
                    }
                    .accessibilityAction(named: "Delete") {
                        delete(query: query.name)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var alertActions: some View {
        TextField("", text: $searchString)
            .autocapitalization(.none)
            .selectAllWhenEditingBegins()
        let query = query
        Button("Search") {
            url = query?
                .url(for: searchString)
        }
        Button("Cancel", role: .cancel) {
        }
    }
    
    var body: some View {
        List {
            Section {
                Button("Open Browser") {
                    url = .some(.none)
                }
            }

            queries.alert(
                query?.name.rawValue ?? "",
                isPresented: $query.isPresent(),
                actions: {
                    alertActions
                }
            )
            // A bug causes alert to seemingly randomly pick text casing
            .textCase(.none)
        }
        .navigationDestination(isPresented: $url.isPresent()) {
            if let url = url {
                WebBrowserView(url: url.flatMap { $0 })
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                Text("Query Central").bold()
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button(image: .plus, binding: $showAddQuery)
            }
        }
        .sheet(isPresented: $showAddQuery) {
            NavigationStack {
                AddQueryView(
                    text: "",
                    showModal: $showAddQuery
                )
            }
        }
    }
}

struct MainQueryView_Previews: PreviewProvider {
    static var previews: some View {
        MainQueryView()
    }
}
