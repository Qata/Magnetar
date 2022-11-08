//
//  LazyView.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 28/10/2022.
//

import SwiftUI

struct LazyView<Content: View>: View {
    let build: () -> Content

    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}
