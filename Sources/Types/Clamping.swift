//
//  Clamping.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 7/8/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

@propertyWrapper
struct Clamping<Value: Comparable> {
    var value: Value
    let range: ClosedRange<Value>

    init(_ range: ClosedRange<Value>, initialValue value: Value) {
        precondition(range.contains(value))
        self.value = value
        self.range = range
    }

    var wrappedValue: Value {
        get { value }
        set { value = min(max(range.lowerBound, newValue), range.upperBound) }
    }
}
