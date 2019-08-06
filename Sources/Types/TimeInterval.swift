//
//  TimeInterval.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

public extension TimeInterval {
    init<I: BinaryInteger>(seconds: I) {
        self = .init(Int(seconds))
    }
    
    init<I: BinaryInteger>(minutes: I) {
        self = .init(seconds: minutes * 60)
    }
    
    init<I: BinaryInteger>(hours: I) {
        self = .init(minutes: hours * 60)
    }
    
    init<I: BinaryInteger>(days: I) {
        self = .init(hours: days * 24)
    }
    
    init<I: BinaryInteger>(weeks: I) {
        self = .init(days: weeks * 7)
    }
}
