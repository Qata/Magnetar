//
//  MainQueryView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

import SwiftUI
import Algorithms

struct MainQueryView: View {
    @StateObject var store = Global.store.lensing(state: \.queries)
    @State var showAddQuery = false
    @State var query: Query?
    @State var urlString: String?
    @State var searchString = ""
    
    var body: some View {
        List {
            Section("Actions") {
                Button("Browser") {
                    
                }
            }
            Section("Queries") {
                ForEach(store.state, id: \.self) { query in
                    Button {
                        if query.parameter == nil {
                            urlString = query.url(for: "")?.absoluteString
                        } else {
                            self.query = query
                        }
                    } label: {
                        Text(query.name)
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
                        urlString = query?.url(for: searchString)?.absoluteString
                    }
                    Button("Cancel", role: .cancel) {
                    }
                }) {
                    Text("Please enter the search terms")
                }
        }
        .navigationBarItems(trailing: Button(image: .plus, binding: $showAddQuery))
        .navigationBarTitle("Query Central")
        .sheet(isPresented: $showAddQuery) {
            NavigationView {
                AddQueryView(
                    text: "https://www.google.com/search?q=test&testname=yes&value=true",
                    showModal: $showAddQuery
                )
            }
        }
        .sheet(isPresented: .init(get: { urlString != nil }, set: { _ in urlString = nil })) {
            WebView(url: urlString ?? "")
        }
    }
}

struct MainQueryView_Previews: PreviewProvider {
    static var previews: some View {
        MainQueryView()
    }
}
