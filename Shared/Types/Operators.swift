//
//  Equality.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

prefix operator +
postfix operator +
prefix operator ==
prefix operator !=
prefix operator <=
prefix operator >
prefix operator >=
infix operator ?=

//prefix func + (value: String) -> (String) -> String {
//    { $0 + value }
//}
//
//postfix func + (value: String) -> (String) -> String {
//    {  value + $0 }
//}

prefix func + (value: String) -> (String?) -> String {
    { ($0 ?? "") + value }
}

postfix func + (value: String) -> (String?) -> String {
    {  value + ($0 ?? "") }
}

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

func ?= <Value>(lhs: inout Value, rhs: Value?) {
    if let value = rhs {
        lhs = value
    }
}
