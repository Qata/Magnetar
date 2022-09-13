//
//  ErrorView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 12/9/2022.
//

import SwiftUI

struct ErrorView: View {
    var detailView: some View {
        StoreView(\.errors) { errors, dispatch in
            List {
                ForEach(Array(errors).reversed()) { model in
                    Section {
                        VStack(alignment: .leading) {
                            Text(model.date.accessibleDescription)
                            Divider()
                            Text(model.error)
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Clear List") {
                        dispatch(sync: .delete(.errors))
                    }
                }
            }
        }
    }

    var body: some View {
        StoreView(\.errors) { errors in
            if !errors.isEmpty {
                NavigationLink(destination: detailView) {
                    SystemImage.exclamationmarkSquareFill
                }
                .foregroundColor(.red)
            }
        }
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView()
    }
}
