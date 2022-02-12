//
//  LabelledHStack.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/8/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import SwiftUI

struct HLabelled<Content: View>: View {
    let label: Text
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    let view: Content
    
    init(_ label: Text, alignment: VerticalAlignment = .firstTextBaseline, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.label = label
        view = content()
    }
    
    init<S: StringProtocol>(_ label: S, alignment: VerticalAlignment = .firstTextBaseline, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self = .init(Text(label), alignment: alignment, spacing: spacing, content: content)
    }

    var body: some View {
        HStack(alignment: alignment, spacing: spacing) {
            label.accessibility(hidden: true)
            view.multilineTextAlignment(.trailing)
                .accessibility(label: label)
        }
    }
}
