//
//  MainQueryView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

import SwiftUI
import Algorithms

struct MainQueryView: View {
    let dispatch = Global.store.writeOnly(sync: { $0 })
    @State var showAddQuery = false
    @State var query: Query?
    @State var urlString: String?
    @State var searchString = ""
    
    func delete(query named: String) {
        dispatch(sync: .delete(.query(name: named)))
    }
    
    var body: some View {
        List {
            Section {
                Button("Browser") {
                    urlString = ""
                }
            }
            StoreView(\.persistent.queries) { queries, dispatch in
                Section("Queries") {
                    ForEach(queries, id: \.self) { query in
                        Button {
                            if query.parameter == nil {
                                urlString = query.url(for: "")?.absoluteString
                            } else {
                                self.query = query
                            }
                        } label: {
                            Text(query.name)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                delete(query: query.name)
                            } label: {
                                Label("Delete", icon: .xmarkBin)
                            }
                        }
                        .accessibilityAction(named: "Delete") {
                            delete(query: query.name)
                        }
                    }
                }
            }
            .alert(
                query?.name ?? "",
                isPresented: .init(get: { query != nil }, set: { _ in query = nil }),
                actions: {
#warning("Requires iOS 16 for alert textfield support https://sarunw.com/posts/swiftui-alert-textfield/")
                    TextField("Query", text: $searchString)
                    let query = query
                    Button("Search") {
                        urlString = query?
                            .url(for: searchString)?
                            .absoluteString
                    }
                    Button("Cancel", role: .cancel) {
                    }
                }
            ) {
                Text("Please enter the search terms")
            }
        }
        .navigationBarItems(
            leading: NavigationLink(
                destination: AddURIView()
            ) {
                Text("URI")
            },
            trailing: Button(image: .plus, binding: $showAddQuery)
        )
        .navigationTitle("")
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                Text("Query Central").bold()
            }
        }
        .sheet(isPresented: $showAddQuery) {
            NavigationView {
                AddQueryView(
                    text: "",
                    showModal: $showAddQuery
                )
            }
        }
        .overlay {
            NavigationLink(
                destination: WebViewSheet(url: urlString ?? ""),
                isActive: .init(
                    get: { urlString != nil },
                    set: { _ in urlString = nil }
                )
            ) {
                EmptyView()
            }
        }
    }
}

struct MainQueryView_Previews: PreviewProvider {
    static var previews: some View {
        MainQueryView()
    }
}
