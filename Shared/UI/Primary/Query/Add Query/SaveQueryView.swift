//
//  SaveQueryView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 21/2/22.
//

import SwiftUI

struct SaveQueryView: View {
    @Environment(\.dismiss) var dismiss
    let dispatch = Global.store.writeOnly()

    let url: URL
    let selectedComponent: ExplodedUrlView.SelectedComponent
    let pathComponents: [Query.Component]
    let queryComponents: [Query.QueryItem]
    @State var queryName: String = ""
    
    func save() {
        dispatch(
            sync: .create(
                .query(
                    .init(
                        name: queryName,
                        base: url,
                        path: pathComponents.enumerated().map { offset, element in
                            if case .path(offset) = selectedComponent {
                                return .query
                            } else {
                                return element
                            }
                        },
                        queryItems: queryComponents.enumerated().map { offset, element in
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
        TextField("Query name", text: $queryName)
        Button("Save") {
            save()
            dismiss()
        }
        .disabled(queryName.isEmpty)
    }
}

struct SaveQueryView_Previews: PreviewProvider {
    static var previews: some View {
        SaveQueryView(
            url: URL(string: "https://google.com")!,
            selectedComponent: .path(offset: 1),
            pathComponents: [
                .string("path"),
                .string("to"),
                .string("location")
            ],
            queryComponents: [
                .init(
                    name: "hello",
                    value: .string("there")
                ),
                .init(
                    name: "how're",
                    value: .string("you")
                )
            ]
        )
    }
}
