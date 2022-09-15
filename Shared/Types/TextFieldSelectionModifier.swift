//
//  TextFieldSelectionModifier.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 15/9/2022.
//

import SwiftUI

struct TextFieldSelectionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.onReceive(
            NotificationCenter.default
                .publisher(
                    for: UITextField.textDidBeginEditingNotification
                )
        ) {
            if let textField = $0.object as? UITextField {
                textField.selectedTextRange = textField.textRange(
                    from: textField.beginningOfDocument,
                    to: textField.endOfDocument
                )
            }
        }
    }
}

extension View {
    func selectAllWhenEditingBegins() -> some View {
        modifier(TextFieldSelectionModifier())
    }
}
