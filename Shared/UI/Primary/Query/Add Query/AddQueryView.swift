//
//  AddQueryView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 21/2/22.
//

import SwiftUI

struct AddQueryView: View {
    @Environment(\.dismiss) var dismiss
    @State var text = ""
    @State var pushed = false
    @Binding var showModal: Bool

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
            if let match = try? Regex.url.wholeMatch(in: text),
               let url = URL(string: text),
               !url.pathComponents.filter({ $0 != "/" }).isEmpty || url.query?.isEmpty == false
            {
                NavigationLink(isActive: $pushed) {
                    ExplodedUrlView(url: url, showModal: $showModal)
                } label: {
                    Button("Continue") {}
                }
            } else {
                Button("Continue") {}
                    .disabled(true)
            }
        }
        .navigationTitle("Enter The Query URL")
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

struct AddQueryView_Previews: PreviewProvider {
    static var previews: some View {
        AddQueryView(showModal: .constant(false))
    }
}
