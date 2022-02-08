//
//  ProgressBar.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import SwiftUI

struct ProgressBar : View {
    @Clamping var value: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .opacity(0.3)
                .foregroundColor(.gray)
                .frame(width: geometry.size.width)
            Rectangle()
                .frame(width: self.value * geometry.size.width, alignment: .leading)
        }
        .frame(height: 4)
        .cornerRadius(2)
        .accessibility(value: Text("\(Int(value * 100))%"))
    }
}

extension ProgressBar {
    init<I: BinaryInteger>(current: I, max maximum: I) {
        self.init(
            value: Clamping(
                0...1,
                initialValue: (maximum != 0).if(
                    true: CGFloat(current) / CGFloat(maximum),
                    false: 0
                )
            )
        )
    }
}
