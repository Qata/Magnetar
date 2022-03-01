//
//  Collection.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 21/8/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

public extension Collection {
    /// Same functionality as `joined` but without the flattening.
    func intersperse(element: Element) -> some Collection {
        Array(
            zip(self, repeatElement(element, count: numericCast(count)))
                .flatMap { [$0, $1] }
                .dropLast()
        )
    }

    func chunked<I: BinaryInteger>(stride length: I) -> some Collection {
        stride(from: 0, to: count, by: numericCast(length))
            .map { dropFirst($0).prefix(numericCast(length)) }
    }
}

extension Array {
    public subscript(index: Int, default defaultValue: @autoclosure () -> Element) -> Element {
        guard index >= 0, index < endIndex else {
            return defaultValue()
        }

        return self[index]
    }

    public subscript(index index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}
