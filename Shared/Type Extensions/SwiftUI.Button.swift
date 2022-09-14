//
//  Button.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 22/2/22.
//

import SwiftUI

extension Button {
    init(
        role: ButtonRole? = nil,
        image: SystemImage,
        action: @escaping () -> Void
    ) where Label == SystemImage {
        self.init(role: role, action: action, label: { image })
    }

    init(
        role: ButtonRole? = nil,
        image: SystemImage,
        binding: Binding<Bool>
    ) where Label == SystemImage {
        self.init(role: role) {
            binding.wrappedValue.toggle()
        } label: {
            image
        }
    }

    init(
        role: ButtonRole? = nil,
        label: Label,
        action: @escaping () -> Void
    ) where Label == SwiftUI.Label<Text, SystemImage> {
        self.init(role: role, action: action, label: { label })
    }
}
