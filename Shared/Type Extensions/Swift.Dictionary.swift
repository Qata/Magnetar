//
//  Swift.Dictionary.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/12/2022.
//

public extension Dictionary {
    func firstKey(where isValueMatching: (Value) -> Bool) -> Key? {
        firstNonNil { key, value in
            isValueMatching(value)
                .if(true: key)
        }
    }
}
