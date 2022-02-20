//
//  NavigationLink.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 16/2/22.
//

import SwiftUI

extension NavigationLink {
    init(destination: Destination, label: Label) where Label == SwiftUI.Label<Text, SystemImage> {
        self.init(
            destination: { destination },
            label: { label }
        )
    }
}
