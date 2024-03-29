//
//  Optional.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import Combine

extension Optional {
    func publisher<Failure: Error>(nilError error: Failure) -> Future<Wrapped, Failure> {
        Future { sink in
            switch self {
            case let value?:
                sink(.success(value))
            case nil:
                sink(.failure(error))
            }
        }
    }

    func `default`(_ value: Wrapped) -> Wrapped {
        self ?? value
    }

    func filter(_ isIncluded: (Wrapped) throws -> Bool) rethrows -> Optional {
        switch self {
        case let value? where try isIncluded(value):
            return value
        default:
            return nil
        }
    }

    func error(nil error: Error) throws -> Wrapped {
        switch self {
        case let value?:
            return value
        case nil:
            throw error
        }
    }

    public static func zip<A, B>(_ first: A?, _ second: B?) -> Wrapped? where Wrapped == (A, B) {
        switch (first, second) {
        case let (first?, second?):
            return (first, second)
        default:
            return nil
        }
    }

    public static func zip<A, B, C>(_ first: A?, _ second: B?, _ third: C?) -> Wrapped? where Wrapped == (A, B, C) {
        switch (first, second, third) {
        case let (first?, second?, third?):
            return (first, second, third)
        default:
            return nil
        }
    }
}
