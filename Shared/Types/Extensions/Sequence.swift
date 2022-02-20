//
//  Sequence.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 21/8/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import CasePaths

public extension Sequence {
    /// Returns the first element in `self` that matches the given type.
    func first<T>(withTypeMatching _: T.Type) -> T? {
        firstNonNil { $0 as? T }
    }

    /// Returns the first element in `self` that `transform` maps to a non-`nil` value.
    func firstNonNil<T>(_ transform: (Element) throws -> T?) rethrows -> T? {
        for value in self {
            if let value = try transform(value) {
                return value
            }
        }
        return nil
    }

    /// Returns an array containing the results of applying the given `KeyPath`
    /// over the sequence's elements.
    func map<U>(_ keyPath: KeyPath<Element, U>) -> [U] {
        map { $0[keyPath: keyPath] }
    }

    /// Returns an array containing the non-`nil` results of applying the given
    /// `KeyPath` with each element of this sequence.
    func compactMap<U>(_ keyPath: KeyPath<Element, U?>) -> [U] {
        compactMap { $0[keyPath: keyPath] }
    }

    /// Returns an array containing the concatenated results of applying the
    /// given `KeyPath` with each element of this sequence.
    func flatMap<U, S: Sequence>(_ keyPath: KeyPath<Element, S>) -> [U] where S.Element == U {
        flatMap { $0[keyPath: keyPath] }
    }

    /// Apply a sequence of functions over the current sequence.
    func apply<U, S: Sequence>(_ sequence: S) -> [U] where S.Element == (Element) -> U {
        flatMap { element in sequence.map { $0(element) } }
    }

    /// Allows lensing properties before comparison by the std lib `sorted(by:)` function, using the `by` closure.
    func sorted<T>(keyPath path: KeyPath<Element, T>, by: (T, T) -> Bool) -> [Element] {
        sorted {
            by($0[keyPath: path], $1[keyPath: path])
        }
    }

    /// Allows lensing properties before comparison by the std lib `sorted(by:)` function, using the `by` closure.
    func sorted<T>(keyPath path: KeyPath<Element, T>) -> [Element] where T: Comparable {
        sorted(keyPath: path, by: <)
    }

    func filter<T>(keyPath path: KeyPath<Element, T>, _ isIncluded: (T) -> Bool) -> [Element] {
        filter {
            isIncluded($0[keyPath: path])
        }
    }

    func contains<Value>(matching casePath: CasePath<Element, Value>) -> Bool {
        contains {
            casePath ~= $0
        }
    }
}
