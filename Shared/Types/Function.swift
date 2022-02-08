//
//  Function.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 20/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

precedencegroup BackwardComposition {
    associativity: left
    higherThan: BitwiseShiftPrecedence
}

precedencegroup ForwardComposition {
    associativity: left
    higherThan: BackwardComposition
}

infix operator <<<: BackwardComposition
infix operator >>>: ForwardComposition

func >>> <A, B, R>(f1: @escaping (A) -> B, f2: @escaping (B) -> R) -> (A) -> R {
    return compose(f1, f2)
}

func <<< <A, B, R>(f1: @escaping (B) -> R, f2: @escaping (A) -> B) -> (A) -> R {
    return compose(f2, f1)
}

func >>> <A, B, R>(f1: @escaping (A) -> B, f2: KeyPath<B, R>) -> (A) -> R {
    return compose(f1, f2)
}

func <<< <A, B, R>(f1: KeyPath<B, R>, f2: @escaping (A) -> B) -> (A) -> R {
    return compose(f2, f1)
}

func >>> <A, B, R>(f1: KeyPath<A, B>, f2: @escaping (B) -> R) -> (A) -> R {
    return compose(f1, f2)
}

func <<< <A, B, R>(f1: @escaping (B) -> R, f2: KeyPath<A, B>) -> (A) -> R {
    return compose(f2, f1)
}

func >>> <A, B, R>(f1: KeyPath<A, B>, f2: KeyPath<B, R>) -> (A) -> R {
    return compose(f1, f2)
}

func <<< <A, B, R>(f1: KeyPath<B, R>, f2: KeyPath<A, B>) -> (A) -> R {
    return compose(f2, f1)
}

func curry<A, B, R>(_ f: @escaping (A, B) -> R) -> (A) -> (B) -> R {
    return { a in { b in f(a, b) } }
}

func curry<A, B, C, R>(_ f: @escaping (A, B, C) -> R) -> (A) -> (B) -> (C) -> R {
    return { a in { b in { c in f(a, b, c) } } }
}

func curry<A, B, C, D, R>(_ f: @escaping (A, B, C, D) -> R) -> (A) -> (B) -> (C) -> (D) -> R {
    return { a in { b in { c in { d in f(a, b, c, d) } } } }
}

func curry<A, B, C, D, E, R>(_ f: @escaping (A, B, C, D, E) -> R) -> (A) -> (B) -> (C) -> (D) -> (E) -> R {
    return { a in { b in { c in { d in { e in f(a, b, c, d, e) } } } } }
}

func flip<A, B, C>(_ f: @escaping (A, B) -> C) -> (B, A) -> C {
    return { f($1, $0) }
}

func compose<A, B, R>(_ f1: @escaping (A) -> B, _ f2: @escaping (B) -> R) -> (A) -> R {
    return { f2(f1($0)) }
}

func compose<A, B, R>(_ f1: @escaping (A) -> B, _ f2: KeyPath<B, R>) -> (A) -> R {
    return { f1($0)[keyPath: f2] }
}

func compose<A, B, R>(_ f1: KeyPath<A, B>, _ f2: @escaping (B) -> R) -> (A) -> R {
    return { f2($0[keyPath: f1]) }
}

func compose<A, B, R>(_ f1: KeyPath<A, B>, _ f2: KeyPath<B, R>) -> (A) -> R {
    return { $0[keyPath: f1][keyPath: f2] }
}
