//
//  ErrorView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 12/9/2022.
//

import SwiftUI

struct ErrorView: View {
    @State var latestError: ErrorModel?
    
    var detailView: some View {
        StoreView(\.errors) { errors, dispatch in
            List {
                ForEach(Array(errors).reversed()) { model in
                    Section {
                        VStack(alignment: .leading) {
                            Text(model.date.accessibleDescription)
                            if model.error.description == nil {
                                Divider()
                            }
                            Text(model.error.title)
                            if let description = model.error.description {
                                Divider()
                                Text(description)
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
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

    var scale: CGSize {
        (latestError == nil).if(
            true: CGSize(width: 1, height: 1),
            false: CGSize(width: 1.3, height: 1.3)
        )
    }

    var body: some View {
        StoreView(\.errors) { errors in
            Group {
                if !errors.isEmpty {
                    NavigationLink(destination: detailView) {
                        SystemImage.exclamationmarkSquareFill
                    }
                    .foregroundColor(.red)
                    .font(.body)
                    .scaleEffect(scale, anchor: .leading)
                }
            }
            .onChange(of: errors) { errors in
                withAnimation(
                    .interpolatingSpring(
                        stiffness: 500,
                        damping: 7,
                        initialVelocity: 10
                    )
                ) {
                    latestError = errors.first(where: { _ in true })
                }
            }
            .onChange(of: latestError) {
                if $0 != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation(.easeOut) {
                            latestError = nil
                        }
                    }
                }
            }
        }
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView()
    }
}
