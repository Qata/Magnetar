//
//  Atomic.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 14/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

final class Atomic<T> {
    private let lock: os_unfair_lock_t
    private var privateValue: T
    
    /// Atomically get or set the value of the variable.
    var value: T {
        get {
            return access { $0 }
        }
        
        set(newValue) {
            replace(newValue)
        }
    }
    
    /// Initialize the variable with the given initial value.
    ///
    /// - parameters:
    ///   - value: Initial value for `self`.
    init(_ value: T) {
        privateValue = value
        lock = .allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }
    
    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }
    
    /// Atomically modifies the variable.
    ///
    /// - parameters:
    ///   - action: A closure that takes the current value.
    ///
    /// - returns: The result of the action.
    @discardableResult
    func modify<U>(_ action: (inout T) throws -> U) rethrows -> U {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        return try action(&privateValue)
    }
    
    /// Atomically perform an arbitrary action using the current value of the
    /// variable.
    ///
    /// - parameters:
    ///   - action: A closure that takes the current value.
    ///
    /// - returns: The result of the action.
    @discardableResult
    func access<U>(_ action: (T) throws -> U) rethrows -> U {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        return try action(privateValue)
    }
    
    /// Atomically replace the contents of the variable.
    ///
    /// - parameters:
    ///   - newValue: A new value for the variable.
    ///
    /// - returns: The old value.
    @discardableResult
    func replace(_ newValue: T) -> T {
        return modify { (value: inout T) in
            let oldValue = value
            value = newValue
            return oldValue
        }
    }
}
