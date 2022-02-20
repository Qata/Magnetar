//
//  StringInterpolation.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 19/8/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

extension String.StringInterpolation {
    mutating func appendInterpolation<N: Numeric>(_ value: N, formatter: Atomic<NumberFormatter>) {
        formatter.access {
            appendInterpolation(value, formatter: $0)
        }
    }

    mutating func appendInterpolation<N: Numeric>(_ value: N, formatter: NumberFormatter) {
        appendInterpolation(
            formatter.string(for: value)!
        )
    }
}
