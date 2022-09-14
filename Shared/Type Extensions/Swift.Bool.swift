//
//  Bool.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

extension Bool {
    /// Returns the inversion of the Boolean's value.
    @inlinable
    var not: Bool {
        return !self
    }
    
    @inlinable
    func `if`<T>(true truth: @autoclosure () throws -> T, false falsity: @autoclosure () throws -> T) rethrows -> T {
        switch self {
        case true:
            return try truth()
        case false:
            return try falsity()
        }
    }
    
    @inlinable
    func `if`<T>(true value: @autoclosure () throws -> T?) rethrows -> T? {
        switch self {
        case true:
            return try value()
        case false:
            return nil
        }
    }
    
    @inlinable
    func `if`<T>(false value: @autoclosure () throws -> T?) rethrows -> T? {
        switch self {
        case true:
            return nil
        case false:
            return try value()
        }
    }
}
