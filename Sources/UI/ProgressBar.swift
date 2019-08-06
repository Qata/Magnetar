//
//  ProgressBar.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import SwiftUI

struct ProgressBar : View {
    var value: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .opacity(0.3)
                .foregroundColor(.gray)
            Rectangle()
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .animation(.easeInOut)
        }
        .frame(height: 4)
        .cornerRadius(2)
        .accessibility(value: Text("\(Int(min(1, max(0, value)) * 100))%"))
    }
}

extension ProgressBar {
    init<I: BinaryInteger>(current: I, max maximum: I) {
        self.init(
            value: (maximum != 0).if(
                true: CGFloat(current) / CGFloat(maximum),
                false: 0
            )
        )
    }
}
