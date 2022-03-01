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
    @State var urlString: String?
    
    var body: some View {
        List {
            Section("Actions") {
                Button("Browser") {
                    
                }
            }
            Section("Queries") {
                ForEach(store.state, id: \.self) { query in
                    Button {
                        urlString = query.url(for: "test")?.absoluteString
                    } label: {
                        Text(query.name)
                    }
                }
            }
        }
        .navigationBarItems(trailing: Button(image: .plus, binding: $showAddQuery))
        .navigationBarTitle("Query Central")
        .sheet(isPresented: $showAddQuery) {
            NavigationView {
                AddQueryView(
                    text: "https://www.google.com/search?q=test",
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
