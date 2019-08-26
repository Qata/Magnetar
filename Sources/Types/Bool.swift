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
    var toggled: Bool {
        return !self
    }
    
    @inlinable
    func `if`<T>(true truth: @autoclosure () -> T, false falsity: @autoclosure () -> T) -> T {
        switch self {
        case true:
            return truth()
        case false:
            return falsity()
        }
    }
    
    @inlinable
    func `if`<T>(true value: @autoclosure () -> T?) -> T? {
        switch self {
        case true:
            return value()
        case false:
            return nil
        }
    }
    
    @inlinable
    func `if`<T>(false value: @autoclosure () -> T?) -> T? {
        switch self {
        case true:
            return nil
        case false:
            return value()
        }
    }
}
