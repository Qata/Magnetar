//
//  MainQueryView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

import SwiftUI
import Algorithms

struct MainQueryView: View {
    @State var presented = false
    @State var urlString = ""
    
    var body: some View {
        List {
            Button("Browser") {
                presented.toggle()
            }
            NavigationLink(destination: ExplodedUrlView(url: URL(string: "https://google.com/path/to/resource?query=valu%20e&goodbye=he+llo&name=charles")!)) {
                Text("Exploded")
            }
        }
        .navigationBarItems(
            trailing: NavigationLink(destination: AddQueryView()) {
                SystemImage.plus
            }
        )
        .navigationBarTitle("Query Central")
        .sheet(isPresented: $presented) {
            WebView(url: urlString)
        }
    }
}

struct AddQueryView: View {
    @State var text = ""
    @State var pushed = false
    
    var body: some View {
        List {
            TextEditor(text: $text)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .submitLabel(.continue)
                .onSubmit {
                    pushed = true
                }
            if text.matches(regex: .url),
               let url = URL(string: text),
               !url.pathComponents.filter({ $0 != "/" }).isEmpty || url.query?.isEmpty == false
            {
                NavigationLink(isActive: $pushed) {
                    ExplodedUrlView(url: url)
                } label: {
                    Button("Continue") {}
                }
            }
        }
        .navigationTitle("Enter an example query")
    }
}

struct ExplodedUrlView: View {
    let originalPathComponents: [Query.Component]
    let originalQueryComponents: [Query.QueryItem]
    @State var pathComponents: [Query.Component]
    @State var queryComponents: [Query.QueryItem]
    @State var url: URL
    @State var space: Query.SpaceCharacter?
    @State var selectedQuery: SelectedQuery?
    
    enum SelectedQuery {
        case path(offset: Int, component: Query.Component)
        case query(offset: Int, item: Query.QueryItem)
    }

    init?(url: URL) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        originalPathComponents = components
            .path
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
            .map(Query.Component.string)
        originalQueryComponents = components
            .queryItems?
            .compactMap {
                Optional.zip($0.name, $0.value)
                    .map { .init(name: $0, value: .string($1)) }
            }
        ?? []
        _pathComponents = .init(initialValue: originalPathComponents)
        _queryComponents = .init(initialValue: originalQueryComponents)

        components.path = ""
        components.queryItems = nil
        guard let url = components.url else {
            return nil
        }
        _url = .init(initialValue: url)
    }
    
    var querySelected: Bool {
        chain(queryComponents.map(\.value), pathComponents)
            .contains(.query)
    }
    
    var query: String? {
        zip(originalPathComponents, pathComponents)
            .first(where: { $1 == .query })
            .map(\.0)?
            .description
        ?? zip(originalQueryComponents, queryComponents)
            .first(where: { $1.value == .query })
            .map(\.0.value)?
            .description
    }
    
    @ViewBuilder var pathView: some View {
        if !originalPathComponents.isEmpty {
            Section("Path") {
                ForEach(0..<originalPathComponents.count) { offset in
                    let component = originalPathComponents[offset]
                    HStack {
                        Toggle(
                            isOn: .init(
                                get: { pathComponents[offset] == .query },
                                set: { pathComponents[offset] = $0.if(true: .query, false: component) }
                            )
                        ) {
                            Text(component.description)
                        }
                        .disabled(querySelected && pathComponents[offset] != .query)
                    }
                }
            }
        }
    }

    @ViewBuilder var queryView: some View {
        if !originalQueryComponents.isEmpty {
            Section("Query Items") {
                
                ForEach(0..<originalQueryComponents.count) { offset in
                    let component = originalQueryComponents[offset]
                    Toggle(
                        isOn: .init(
                            get: { queryComponents[offset].value == .query },
                            set: { queryComponents[offset].value = $0 ? .query : component.value }
                        )
                    ) {
                        Text(component.description)
                    }
                    .disabled(querySelected && queryComponents[offset].value != .query)
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            List {
                pathView
                queryView
                if let query = query {
                    SpaceCharacterView(query: query, space: $space)
                }
            }
        }
        .navigationBarTitle(Text("Please select the query"))
    }
}

struct SpaceCharacterView: View {
    @Binding var space: Query.SpaceCharacter?
    let query: String

    init(query: String, space: Binding<Query.SpaceCharacter?>) {
        self.query = query
        _space = space
        DispatchQueue.main.async { [self] in
            self.space = query.contains(" ").if(
                true: .space,
                false: query.contains("+").if(
                    true: .plus
                )
            )
        }
    }
    
    func test() {
        let chars = Query.SpaceCharacter.allCases.compactMap {
            .zip($0, $0.rawValue.asciiValue)
        }
        .map { ("\(String(describing: $0)) (%\($1))", $0) }
        
        Text(
            chars
                .first { query.contains($1.rawValue) }
                .map(\.0)
                .map {
                    "Looks like the query uses \($0) between words."
                }
            ?? "Unable to determine if the query uses \(chars.map(\.0).joined(separator: " or ")) between words."
        )
        Picker(selection: $space) {
            ForEach(chars, id: \.1) { description, character in
                Text(description)
                    .tag(Optional(character))
            }
            Text("Unspecified")
                .tag(Optional<Query.SpaceCharacter>.none)
        } label: {
            EmptyView()
        }
        .pickerStyle(.inline)
    }
    
    var body: some View {
        if query.contains(" ") {
            Text("Looks like the query uses space (%20) between words.")
        } else if query.contains("+") {
            Text("Looks like the query uses plus (%2B) between words.")
        } else {
            Text("Unable to determine if the query uses space (%20) or plus (%2B) between words.")
        }
        Picker(selection: $space) {
            ForEach(Query.SpaceCharacter.allCases, id: \.self) {
                let hex = $0.rawValue.asciiValue.map {
                    String($0, radix: 16, uppercase: true)
                }!
                Text("It uses \(String(describing: $0)) (%\(hex))")
                    .tag(Optional($0))
            }
            Text("Unspecified")
                .tag(Optional<Query.SpaceCharacter>.none)
        } label: {
            EmptyView()
        }
        .pickerStyle(.inline)
    }
}

struct MainQueryView_Previews: PreviewProvider {
    static var previews: some View {
        MainQueryView()
    }
}
