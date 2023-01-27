//
//  Collection.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 21/8/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

public extension Collection {
    subscript(index index: Index) -> Element? {
        indices
            .contains(index)
            .if(true: self[index])
    }

    subscript(index index: Index, default defaultValue: @autoclosure () -> Element) -> Element {
        self[index: index] ?? defaultValue()
    }
}

public extension Collection where Index == Int {
    /// Returns the element at the specified offset from the start of the collection, if it is within bounds, otherwise nil.
    subscript<Offset: BinaryInteger>(offset offset: Offset) -> Element? {
        self[index: startIndex.advanced(by: numericCast(offset))]
    }

    /// Returns the element at the specified offset from the start of the collection, if it is within bounds, otherwise `default`.
    subscript<Offset: BinaryInteger>(offset offset: Offset, default defaultValue: @autoclosure () -> Element) -> Element? {
        self[index: startIndex.advanced(by: numericCast(offset)), default: defaultValue()]
    }
}
