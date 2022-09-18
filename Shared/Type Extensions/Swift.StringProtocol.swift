//
//  StringProtocol.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 18/2/22.
//

import Foundation

extension StringProtocol {
    var unCamelCased: [SubSequence] {
        chunked(by: { $1.isUppercase.not })
    }
    
    var sfSymbolString: String {
        chunked {
            $0.isNumber.not && $1.isNumber.not && $1.isUppercase.not
        }
        .joined(separator: ".")
        .lowercased()
    }

    var urlEncoded: String? {
        addingPercentEncoding(
            withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "~-_."))
        )
    }
}
