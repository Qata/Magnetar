//
//  Equality.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

prefix operator ==
prefix operator !=
prefix operator <=
prefix operator >
prefix operator >=

prefix func == <Value: Equatable>(value: Value) -> (Value) -> Bool {
    { $0 == value }
}

prefix func != <Value: Equatable>(value: Value) -> (Value) -> Bool {
    { $0 != value }
}

prefix func > <Value: Comparable>(value: Value) -> (Value) -> Bool {
    { $0 > value }
}

prefix func >= <Value: Comparable>(value: Value) -> (Value) -> Bool {
    { $0 >= value }
}

prefix func <= <Value: Comparable>(value: Value) -> (Value) -> Bool {
    { $0 <= value }
}
