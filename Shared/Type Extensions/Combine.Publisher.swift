//
//  Publisher.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 16/2/22.
//

import Combine
import CasePaths

extension Publisher {
    func first<Value>(matching casePath: CasePath<Output, Value>) -> Publishers.FirstWhere<Self> {
        first {
            casePath ~= $0
        }
    }
    
    func filter<Value>(matching casePath: CasePath<Output, Value>) -> Publishers.Filter<Self> {
        filter {
            casePath ~= $0
        }
    }
    
    public func removeDuplicates<Value: Equatable>(by keyPath: KeyPath<Output, Value>) -> Publishers.RemoveDuplicates<Self> {
        removeDuplicates(by: { $0[keyPath: keyPath] == $1[keyPath: keyPath] })
    }
}
