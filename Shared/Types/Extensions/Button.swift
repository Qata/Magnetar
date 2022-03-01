//
//  Button.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 22/2/22.
//

import SwiftUI

extension Button {
    init(image: SystemImage, action: @escaping () -> Void) where Label == SystemImage {
        self.init(action: action, label: { image })
    }

    init(image: SystemImage, binding: Binding<Bool>) where Label == SystemImage {
        self.init {
            binding.wrappedValue.toggle()
        } label: {
            image
        }
    }
}
