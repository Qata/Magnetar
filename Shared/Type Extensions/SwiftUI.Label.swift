//
//  Label.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 16/2/22.
//

import SwiftUI

extension Label {
    init<S: StringProtocol>(_ title: S, icon: SystemImage) where Title == Text, Icon == SystemImage {
        self.init {
            Text(title)
        } icon: {
            icon
        }
    }
}
