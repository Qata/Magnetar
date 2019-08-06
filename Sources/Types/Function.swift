//
//  Function.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 20/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

enum F {
    public static func curry<A, B, R>(_ f: @escaping (A, B) -> R) -> (A) -> (B) -> R {
        return { a in { b in f(a, b) } }
    }

    public static func curry<A, B, C, R>(_ f: @escaping (A, B, C) -> R) -> (A) -> (B) -> (C) -> R {
        return { a in { b in { c in f(a, b, c) } } }
    }
    
    public static func curry<A, B, C, D, R>(_ f: @escaping (A, B, C, D) -> R) -> (A) -> (B) -> (C) -> (D) -> R {
        return { a in { b in { c in { d in f(a, b, c, d) } } } }
    }
    
    public static func curry<A, B, C, D, E, R>(_ f: @escaping (A, B, C, D, E) -> R) -> (A) -> (B) -> (C) -> (D) -> (E) -> R {
        return { a in { b in { c in { d in { e in f(a, b, c, d, e) } } } } }
    }
    
    public static func flip<A, B, C>(_ f: @escaping (A, B) -> C) -> (B, A) -> C {
        return { f($1, $0) }
    }
}
